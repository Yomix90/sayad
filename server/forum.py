"""Forum of the Sayad app: user accounts, articles with images, reactions
and comments, plus the import of the old app's articles (TIFNIT encyclopedia).

Public:  read articles and comments.
Users:   register / log in (Bearer token), post articles, react, comment.
Admin:   moderation and import under /admin/api/forum (X-Admin-Token).
"""
import hashlib
import hmac
import html
import json
import os
import re
import secrets
import threading
import time
import urllib.request
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, File, Header, HTTPException, Query, Request, UploadFile
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

import ai

SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE COLLATE NOCASE,
  display_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  banned INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS tokens (
  token_hash TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS articles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  author_name TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  images TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'published',
  source TEXT NOT NULL DEFAULT 'app',
  ext_id TEXT NOT NULL DEFAULT '',
  kind TEXT NOT NULL DEFAULT 'article',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS articles_list ON articles(status, category, created_at);
CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  article_id INTEGER NOT NULL,
  user_id INTEGER,
  author_name TEXT NOT NULL,
  body TEXT NOT NULL,
  ai INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS comments_article ON comments(article_id, created_at);
CREATE TABLE IF NOT EXISTS reactions (
  article_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  PRIMARY KEY (article_id, user_id)
);
"""

Kind = Literal['article', 'question']
ADMIN_AUTHOR = 'Admin'


def migrate(c) -> None:
    """Columns added after the first version of the forum."""
    have = {r[1] for r in c.execute('PRAGMA table_info(articles)')}
    if 'kind' not in have:
        c.execute("ALTER TABLE articles ADD COLUMN kind TEXT NOT NULL DEFAULT 'article'")
        # The old forum's Q&A section holds questions.
        c.execute("UPDATE articles SET kind = 'question' WHERE category = 'qa'")
    if 'ai' not in {r[1] for r in c.execute('PRAGMA table_info(comments)')}:
        c.execute('ALTER TABLE comments ADD COLUMN ai INTEGER NOT NULL DEFAULT 0')


AI_AUTHOR = 'Assistant Sayad'


def ai_answers_on() -> bool:
    """Automatic AI answers to new questions (AI_ANSWERS=0 turns them off)."""
    return ai.enabled() and os.environ.get('AI_ANSWERS', '1').strip() != '0'


CATEGORIES = ['general', 'surfcasting', 'spinning', 'pole', 'boat', 'qa', 'catches', 'videos']
Category = Literal['general', 'surfcasting', 'spinning', 'pole', 'boat', 'qa', 'catches', 'videos']
Reaction = Literal['like', 'love', 'fish', 'wow']
REACTIONS = ['like', 'love', 'fish', 'wow']

# Categories of the old TIFNIT forum.
OLD_CATEGORIES = {
    'questions': 'qa', 'générale': 'general', 'generale': 'general', 'surfcasting': 'surfcasting',
    'pole': 'pole', 'pelote': 'pole', 'spinning': 'spinning', 'vidéo': 'videos', 'video': 'videos',
    'bateau': 'boat', 'boat': 'boat',
}

IMAGE_TYPES = {b'\xff\xd8\xff': '.jpg', b'\x89PNG': '.png', b'GIF8': '.gif', b'RIFF': '.webp'}
MAX_IMAGE = 6 * 1024 * 1024


def hash_password(password: str, salt: Optional[str] = None) -> str:
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 200_000).hex()
    return f'pbkdf2${salt}${digest}'


def check_password(password: str, stored: str) -> bool:
    try:
        _, salt, _ = stored.split('$')
    except ValueError:
        return False
    return hmac.compare_digest(hash_password(password, salt), stored)


def _token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def image_ext(data: bytes) -> Optional[str]:
    for magic, ext in IMAGE_TYPES.items():
        if data.startswith(magic):
            if ext == '.webp' and data[8:12] != b'WEBP':
                return None
            return ext
    return None


class Limiter:
    """At most [count] actions per [seconds] for each key."""

    def __init__(self, count: int, seconds: int):
        self.count, self.seconds = count, seconds
        self.recent = defaultdict(deque)

    def hit(self, key) -> None:
        now = time.time()
        q = self.recent[key]
        while q and now - q[0] > self.seconds:
            q.popleft()
        if len(q) >= self.count:
            raise HTTPException(429, 'Too many requests, try again later')
        q.append(now)

    def clear(self) -> None:
        self.recent.clear()


register_limit = Limiter(5, 3600)
login_limit = Limiter(20, 900)
post_limit = Limiter(10, 3600)
comment_limit = Limiter(60, 3600)
upload_limit = Limiter(40, 3600)
ai_limit = Limiter(10, 3600)


# --- Old app articles ----------------------------------------------------------
DATE_RE = re.compile(r'^(\d{2})-(\d{2})-(\d{4})$')
OLD_UNDATED = 1451606400  # 2016-01-01
VIDEO_RE =re.compile(r'(?:youtube\.com/(?:embed/|watch\?v=|v/)|youtu\.be/)([\w-]{11})')


def is_articles_file(path: str) -> bool:
    if not path.lower().endswith('.json'):
        return False
    try:
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        return False
    return isinstance(data, list) and bool(data) and isinstance(data[0], dict) \
        and {'titre', 'texte'} <= set(data[0])


def parse_old_article(a: dict) -> dict:
    """Title, body, author and date of one encyclopedia article. The text ends
    with the date (dd-mm-yyyy) and the author's name on their own lines."""
    lines = [l.rstrip() for l in (a.get('texte') or '').strip().split('\n')]
    author, created = ADMIN_AUTHOR, None
    if len(lines) >= 2 and DATE_RE.match(lines[-2].strip()):
        d, m, y = DATE_RE.match(lines[-2].strip()).groups()
        created = datetime(int(y), int(m), int(d), 12, tzinfo=timezone.utc)
        lines = lines[:-2]
    elif lines and DATE_RE.match(lines[-1].strip()):
        d, m, y = DATE_RE.match(lines[-1].strip()).groups()
        created = datetime(int(y), int(m), int(d), 12, tzinfo=timezone.utc)
        lines = lines[:-1]
    body = re.sub(r'\n{3,}', '\n\n', '\n'.join(lines)).strip()
    videos = []
    for vid in VIDEO_RE.findall(a.get('content_html') or ''):
        url = f'https://www.youtube.com/watch?v={vid}'
        if url not in videos and url not in body:
            videos.append(url)
    if videos:
        body = (body + '\n\n' + '\n'.join(videos)).strip()
    cat = (a.get('categorie') or '').lower()
    category = next((v for k, v in OLD_CATEGORIES.items() if k in cat), 'general')
    images = [u for u in (a.get('images') or []) if isinstance(u, str) and u.startswith('http')]
    return {
        'title': html.unescape(a.get('titre') or '').strip()[:200] or 'TIFNIT',
        'body': html.unescape(body) or '-',
        'author': author[:60],
        'category': category,
        'kind': 'question' if category == 'qa' else 'article',
        'images': images,
        # Undated articles go after the dated ones (the old forum began in 2016).
        'created_at': int(created.timestamp()) if created else OLD_UNDATED,
        'ext_id': f"tifnit:{a.get('id')}" if a.get('id') is not None else '',
    }


def create_router(db, require_admin, media_dir, old_app_dir) -> APIRouter:
    """[db] opens the database, [media_dir] / [old_app_dir] return folders."""
    router = APIRouter()
    admin = [Depends(require_admin)]

    # --- Users ----------------------------------------------------------------
    def current_user(authorization: str = Header(default='')) -> Optional[dict]:
        if not authorization.lower().startswith('bearer '):
            return None
        th = _token_hash(authorization[7:].strip())
        with db() as c:
            row = c.execute('SELECT u.* FROM tokens t JOIN users u ON u.id = t.user_id '
                            'WHERE t.token_hash = ?', (th,)).fetchone()
        if row is None:
            return None
        return dict(row)

    def need_user(user: Optional[dict] = Depends(current_user)) -> dict:
        if user is None:
            raise HTTPException(401, 'Login required')
        if user['banned']:
            raise HTTPException(403, 'Account suspended')
        return user

    def public_user(u: dict) -> dict:
        return {'id': u['id'], 'username': u['username'], 'display_name': u['display_name']}

    def new_token(c, user_id: int) -> str:
        token = secrets.token_urlsafe(32)
        c.execute('INSERT INTO tokens(token_hash, user_id, created_at) VALUES (?,?,?)',
                  (_token_hash(token), user_id, int(time.time())))
        return token

    class Register(BaseModel):
        username: str = Field(min_length=3, max_length=30, pattern=r'^[A-Za-z0-9_.-]+$')
        password: str = Field(min_length=6, max_length=128)
        display_name: str = Field(default='', max_length=40)

    class Login(BaseModel):
        username: str = Field(max_length=30)
        password: str = Field(max_length=128)

    def _ip(request: Request) -> str:
        return request.headers.get('x-real-ip') or (request.client.host if request.client else '?')

    @router.post('/auth/register', status_code=201)
    def register(body: Register, request: Request):
        register_limit.hit(_ip(request))
        name = body.display_name.strip() or body.username
        with db() as c:
            if c.execute('SELECT 1 FROM users WHERE username = ?', (body.username,)).fetchone():
                raise HTTPException(409, 'Username already taken')
            cur = c.execute('INSERT INTO users(username, display_name, password_hash, created_at) '
                            'VALUES (?,?,?,?)',
                            (body.username, name, hash_password(body.password), int(time.time())))
            token = new_token(c, cur.lastrowid)
            user = dict(c.execute('SELECT * FROM users WHERE id = ?', (cur.lastrowid,)).fetchone())
        return {'token': token, 'user': public_user(user)}

    @router.post('/auth/login')
    def login(body: Login, request: Request):
        login_limit.hit(_ip(request))
        with db() as c:
            row = c.execute('SELECT * FROM users WHERE username = ?', (body.username.strip(),)).fetchone()
            if row is None or not check_password(body.password, row['password_hash']):
                raise HTTPException(401, 'Wrong username or password')
            if row['banned']:
                raise HTTPException(403, 'Account suspended')
            token = new_token(c, row['id'])
        return {'token': token, 'user': public_user(dict(row))}

    @router.get('/auth/me')
    def me(user: dict = Depends(need_user)):
        return public_user(user)

    @router.post('/auth/logout')
    def logout(authorization: str = Header(default='')):
        if authorization.lower().startswith('bearer '):
            with db() as c:
                c.execute('DELETE FROM tokens WHERE token_hash = ?', (_token_hash(authorization[7:].strip()),))
        return {'ok': True}

    # --- Articles -------------------------------------------------------------
    def counts(c, ids: List[int]):
        if not ids:
            return {}, {}
        marks = ','.join('?' * len(ids))
        com = {r[0]: r[1] for r in c.execute(
            f'SELECT article_id, COUNT(*) FROM comments WHERE article_id IN ({marks}) GROUP BY article_id', ids)}
        rea = defaultdict(dict)
        for r in c.execute(f'SELECT article_id, type, COUNT(*) FROM reactions WHERE article_id IN ({marks}) '
                           'GROUP BY article_id, type', ids):
            rea[r[0]][r[1]] = r[2]
        return com, rea

    def summary(r, com, rea) -> dict:
        images = json.loads(r['images'] or '[]')
        body = r['body']
        return {
            'id': r['id'], 'title': r['title'], 'category': r['category'],
            'excerpt': body[:220] + ('…' if len(body) > 220 else ''),
            'author': r['author_name'], 'user_id': r['user_id'], 'images': images,
            'created_at': r['created_at'], 'source': r['source'], 'kind': r['kind'],
            'comments': com.get(r['id'], 0), 'reactions': rea.get(r['id'], {}),
        }

    @router.get('/forum/categories')
    def categories():
        return CATEGORIES

    @router.get('/forum/articles')
    def list_articles(category: str = '', q: str = '', kind: str = '', offset: int = Query(0, ge=0),
                      limit: int = Query(20, ge=1, le=100)):
        where, args = ['status = "published"'], []
        if kind:
            where.append('kind = ?')
            args.append(kind)
        if category:
            where.append('category = ?')
            args.append(category)
        if q:
            where.append('(title LIKE ? OR body LIKE ?)')
            args += [f'%{q}%'] * 2
        sql = ' AND '.join(where)
        with db() as c:
            total = c.execute(f'SELECT COUNT(*) FROM articles WHERE {sql}', args).fetchone()[0]
            rows = c.execute(f'SELECT * FROM articles WHERE {sql} ORDER BY created_at DESC, id DESC '
                             'LIMIT ? OFFSET ?', args + [limit, offset]).fetchall()
            com, rea = counts(c, [r['id'] for r in rows])
        return {'total': total, 'items': [summary(r, com, rea) for r in rows]}

    def load_article(c, article_id: int, user: Optional[dict]):
        r = c.execute('SELECT * FROM articles WHERE id = ? AND status = "published"', (article_id,)).fetchone()
        if r is None:
            raise HTTPException(404, 'Not found')
        com, rea = counts(c, [article_id])
        out = summary(r, com, rea)
        out['body'] = r['body']
        out['comment_list'] = [{**dict(x), 'ai': bool(x['ai'])} for x in c.execute(
            'SELECT id, user_id, author_name AS author, body, ai, created_at FROM comments '
            'WHERE article_id = ? ORDER BY created_at, id', (article_id,))]
        mine = None
        if user:
            row = c.execute('SELECT type FROM reactions WHERE article_id = ? AND user_id = ?',
                            (article_id, user['id'])).fetchone()
            mine = row[0] if row else None
        out['my_reaction'] = mine
        return out

    @router.get('/forum/articles/{article_id}')
    def get_article(article_id: int, user: Optional[dict] = Depends(current_user)):
        with db() as c:
            return load_article(c, article_id, user)

    class ArticleIn(BaseModel):
        title: str = Field(min_length=3, max_length=200)
        body: str = Field(min_length=1, max_length=20000)
        category: Category = 'general'
        kind: Kind = 'article'
        images: List[str] = Field(default=[], max_length=10)

    @router.post('/forum/articles', status_code=201)
    def post_article(a: ArticleIn, user: dict = Depends(need_user)):
        post_limit.hit(user['id'])
        # Only images uploaded to this server.
        images = [u for u in a.images if re.fullmatch(r'/media/[\w-]+\.(jpg|png|gif|webp)', u)]
        with db() as c:
            cur = c.execute('INSERT INTO articles(user_id, author_name, title, body, category, kind, images, '
                            'source, created_at) VALUES (?,?,?,?,?,?,?, "app", ?)',
                            (user['id'], user['display_name'], a.title.strip(), a.body.strip(),
                             a.category, a.kind, json.dumps(images), int(time.time())))
            article_id = cur.lastrowid
        if a.kind == 'question' and ai_answers_on():
            # The answer arrives a few seconds later as the first comment.
            threading.Thread(target=answer_question, args=(article_id,), daemon=True).start()
        with db() as c:
            return load_article(c, article_id, user)

    @router.delete('/forum/articles/{article_id}')
    def delete_own_article(article_id: int, user: dict = Depends(need_user)):
        with db() as c:
            cur = c.execute('DELETE FROM articles WHERE id = ? AND user_id = ?', (article_id, user['id']))
            if cur.rowcount == 0:
                raise HTTPException(404, 'Not found')
            c.execute('DELETE FROM comments WHERE article_id = ?', (article_id,))
            c.execute('DELETE FROM reactions WHERE article_id = ?', (article_id,))
        return {'deleted': article_id}

    class ReactIn(BaseModel):
        type: Optional[Reaction] = None

    @router.post('/forum/articles/{article_id}/react')
    def react(article_id: int, body: ReactIn, user: dict = Depends(need_user)):
        """Sets the user's reaction; the same one again (or none) removes it."""
        with db() as c:
            load_article(c, article_id, user)
            old = c.execute('SELECT type FROM reactions WHERE article_id = ? AND user_id = ?',
                            (article_id, user['id'])).fetchone()
            c.execute('DELETE FROM reactions WHERE article_id = ? AND user_id = ?', (article_id, user['id']))
            if body.type and (old is None or old[0] != body.type):
                c.execute('INSERT INTO reactions(article_id, user_id, type) VALUES (?,?,?)',
                          (article_id, user['id'], body.type))
            out = load_article(c, article_id, user)
        return {'reactions': out['reactions'], 'my_reaction': out['my_reaction']}

    class CommentIn(BaseModel):
        body: str = Field(min_length=1, max_length=3000)

    @router.post('/forum/articles/{article_id}/comments', status_code=201)
    def comment(article_id: int, body: CommentIn, user: dict = Depends(need_user)):
        comment_limit.hit(user['id'])
        with db() as c:
            load_article(c, article_id, user)
            c.execute('INSERT INTO comments(article_id, user_id, author_name, body, created_at) '
                      'VALUES (?,?,?,?,?)',
                      (article_id, user['id'], user['display_name'], body.body.strip(), int(time.time())))
            return load_article(c, article_id, user)['comment_list']

    @router.delete('/forum/comments/{comment_id}')
    def delete_own_comment(comment_id: int, user: dict = Depends(need_user)):
        with db() as c:
            cur = c.execute('DELETE FROM comments WHERE id = ? AND user_id = ?', (comment_id, user['id']))
        if cur.rowcount == 0:
            raise HTTPException(404, 'Not found')
        return {'deleted': comment_id}

    class ImproveIn(BaseModel):
        title: str = Field(default='', max_length=200)
        body: str = Field(min_length=1, max_length=20000)
        kind: Kind = 'article'

    @router.get('/forum/ai')
    def ai_status():
        return {'enabled': ai.enabled()}

    @router.post('/forum/ai/improve')
    def ai_improve(body: ImproveIn, user: dict = Depends(need_user)):
        """Suggests a clearer version of the text being written (not saved)."""
        ai_limit.hit(user['id'])
        return ai.improve(body.title, body.body, body.kind)

    def answer_question(article_id: int) -> Optional[dict]:
        """Posts the AI's answer as a comment; None when the AI fails."""
        with db() as c:
            r = c.execute('SELECT title, body FROM articles WHERE id = ?', (article_id,)).fetchone()
        if r is None:
            return None
        try:
            text = ai.answer(r['title'], r['body'])
        except HTTPException as e:
            print(f'AI answer to article {article_id} failed: {e.detail}')
            return None
        with db() as c:
            cur = c.execute('INSERT INTO comments(article_id, user_id, author_name, body, ai, created_at) '
                            'VALUES (?, NULL, ?, ?, 1, ?)', (article_id, AI_AUTHOR, text, int(time.time())))
        return {'id': cur.lastrowid, 'author': AI_AUTHOR, 'body': text, 'ai': True}

    router.answer_question = answer_question

    # --- Images ---------------------------------------------------------------
    def save_image(data: bytes) -> str:
        ext = image_ext(data)
        if ext is None:
            raise HTTPException(400, 'Only JPEG, PNG, GIF or WebP images')
        os.makedirs(media_dir(), exist_ok=True)
        name = secrets.token_hex(12) + ext
        with open(os.path.join(media_dir(), name), 'wb') as f:
            f.write(data)
        return f'/media/{name}'

    @router.post('/forum/images', status_code=201)
    async def upload_image(file: UploadFile = File(...), user: dict = Depends(need_user)):
        upload_limit.hit(user['id'])
        data = await file.read(MAX_IMAGE + 1)
        if len(data) > MAX_IMAGE:
            raise HTTPException(413, 'Image too large (6 MB max)')
        return {'url': save_image(data)}

    @router.get('/media/{name}', include_in_schema=False)
    def media(name: str):
        if not re.fullmatch(r'[\w-]+\.(jpg|png|gif|webp)', name):
            raise HTTPException(404, 'Not found')
        path = os.path.join(media_dir(), name)
        if not os.path.isfile(path):
            raise HTTPException(404, 'Not found')
        return FileResponse(path, headers={'Cache-Control': 'public, max-age=31536000, immutable'})

    # --- Admin ------------------------------------------------------------------
    def admin_filter(q: str, source: str, status: str, kind: str):
        where, args = [], []
        if kind:
            where.append('kind = ?')
            args.append(kind)
        if q:
            where.append('(title LIKE ? OR body LIKE ? OR author_name LIKE ?)')
            args += [f'%{q}%'] * 3
        if source:
            where.append('source = ?')
            args.append(source)
        if status:
            where.append('status = ?')
            args.append(status)
        return ('WHERE ' + ' AND '.join(where)) if where else '', args

    @router.get('/admin/api/forum/articles', dependencies=admin)
    def admin_articles(q: str = '', source: str = '', status: str = '', kind: str = '',
                       offset: int = 0, limit: int = Query(50, le=1000)):
        sql, args = admin_filter(q, source, status, kind)
        with db() as c:
            total = c.execute(f'SELECT COUNT(*) FROM articles {sql}', args).fetchone()[0]
            rows = c.execute(f'SELECT * FROM articles {sql} ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?',
                             args + [limit, offset]).fetchall()
            com, rea = counts(c, [r['id'] for r in rows])
            items = []
            for r in rows:
                s = summary(r, com, rea)
                s['status'] = r['status']
                s['body'] = r['body']
                items.append(s)
            stats = {
                'articles': c.execute("SELECT COUNT(*) FROM articles WHERE kind = 'article'").fetchone()[0],
                'questions': c.execute("SELECT COUNT(*) FROM articles WHERE kind = 'question'").fetchone()[0],
                'comments': c.execute('SELECT COUNT(*) FROM comments').fetchone()[0],
                'users': c.execute('SELECT COUNT(*) FROM users').fetchone()[0],
            }
        return {'total': total, 'items': items, 'stats': stats, 'images': image_job.copy(),
                'ai': ai.enabled(), 'ai_answers': ai_answers_on()}

    class ArticleEdit(BaseModel):
        status: Optional[Literal['published', 'hidden']] = None
        kind: Optional[Kind] = None
        category: Optional[Category] = None
        title: Optional[str] = Field(default=None, min_length=1, max_length=200)
        body: Optional[str] = Field(default=None, min_length=1, max_length=20000)
        author_name: Optional[str] = Field(default=None, min_length=1, max_length=60)

    @router.put('/admin/api/forum/articles/{article_id}', dependencies=admin)
    def admin_article_edit(article_id: int, body: ArticleEdit):
        fields = body.model_dump(exclude_none=True)
        if not fields:
            raise HTTPException(400, 'Nothing to change')
        sets = ', '.join(f'{k} = ?' for k in fields)
        with db() as c:
            cur = c.execute(f'UPDATE articles SET {sets} WHERE id = ?', list(fields.values()) + [article_id])
        if cur.rowcount == 0:
            raise HTTPException(404, 'Not found')
        return {'id': article_id, **fields}

    class ArticlesBulk(BaseModel):
        """An action on [ids], or on every article matching the filters."""
        action: Literal['author_admin', 'to_question', 'to_article', 'hide', 'publish']
        ids: List[int] = []
        all_matching: bool = False
        q: str = ''
        source: str = ''
        status: str = ''
        kind: str = ''

    @router.post('/admin/api/forum/articles/bulk', dependencies=admin)
    def admin_articles_bulk(body: ArticlesBulk):
        change = {
            'author_admin': ('author_name', ADMIN_AUTHOR), 'to_question': ('kind', 'question'),
            'to_article': ('kind', 'article'), 'hide': ('status', 'hidden'), 'publish': ('status', 'published'),
        }[body.action]
        if body.all_matching:
            sql, args = admin_filter(body.q, body.source, body.status, body.kind)
        elif body.ids:
            sql, args = f'WHERE id IN ({",".join("?" * len(body.ids))})', list(body.ids)
        else:
            return {'changed': 0}
        with db() as c:
            cur = c.execute(f'UPDATE articles SET {change[0]} = ? {sql}', [change[1]] + args)
        return {'changed': cur.rowcount}

    @router.post('/admin/api/forum/articles/{article_id}/improve', dependencies=admin)
    def admin_improve(article_id: int):
        """AI suggestion for an article; saved only by a following PUT."""
        with db() as c:
            r = c.execute('SELECT title, body, kind FROM articles WHERE id = ?', (article_id,)).fetchone()
        if r is None:
            raise HTTPException(404, 'Not found')
        return ai.improve(r['title'], r['body'], r['kind'])

    @router.delete('/admin/api/forum/articles/{article_id}', dependencies=admin)
    def admin_delete_article(article_id: int):
        with db() as c:
            cur = c.execute('DELETE FROM articles WHERE id = ?', (article_id,))
            c.execute('DELETE FROM comments WHERE article_id = ?', (article_id,))
            c.execute('DELETE FROM reactions WHERE article_id = ?', (article_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, 'Not found')
        return {'deleted': article_id}

    @router.get('/admin/api/forum/articles/{article_id}/comments', dependencies=admin)
    def admin_comments(article_id: int):
        with db() as c:
            return [dict(r) for r in c.execute(
                'SELECT id, user_id, author_name AS author, body, ai, created_at FROM comments '
                'WHERE article_id = ? ORDER BY created_at, id', (article_id,))]

    @router.post('/admin/api/forum/articles/{article_id}/ai-answer', dependencies=admin)
    def admin_ai_answer(article_id: int):
        """Asks the AI to answer a question now (e.g. the old forum's ones)."""
        with db() as c:
            r = c.execute('SELECT title, body FROM articles WHERE id = ?', (article_id,)).fetchone()
        if r is None:
            raise HTTPException(404, 'Not found')
        text = ai.answer(r['title'], r['body'])
        with db() as c:
            cur = c.execute('INSERT INTO comments(article_id, user_id, author_name, body, ai, created_at) '
                            'VALUES (?, NULL, ?, ?, 1, ?)', (article_id, AI_AUTHOR, text, int(time.time())))
        return {'id': cur.lastrowid, 'author': AI_AUTHOR, 'body': text, 'ai': True}

    @router.delete('/admin/api/forum/comments/{comment_id}', dependencies=admin)
    def admin_delete_comment(comment_id: int):
        with db() as c:
            cur = c.execute('DELETE FROM comments WHERE id = ?', (comment_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, 'Not found')
        return {'deleted': comment_id}

    @router.get('/admin/api/forum/users', dependencies=admin)
    def admin_users(q: str = ''):
        with db() as c:
            rows = c.execute(
                'SELECT u.id, u.username, u.display_name, u.banned, u.created_at, '
                '(SELECT COUNT(*) FROM articles a WHERE a.user_id = u.id) AS articles, '
                '(SELECT COUNT(*) FROM comments m WHERE m.user_id = u.id) AS comments '
                'FROM users u WHERE u.username LIKE ? OR u.display_name LIKE ? '
                'ORDER BY u.id DESC LIMIT 500', (f'%{q}%', f'%{q}%')).fetchall()
        return [dict(r) for r in rows]

    class Ban(BaseModel):
        banned: bool

    @router.put('/admin/api/forum/users/{user_id}', dependencies=admin)
    def admin_ban(user_id: int, body: Ban):
        with db() as c:
            cur = c.execute('UPDATE users SET banned = ? WHERE id = ?', (int(body.banned), user_id))
            if body.banned:
                c.execute('DELETE FROM tokens WHERE user_id = ?', (user_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, 'Not found')
        return {'id': user_id, 'banned': body.banned}

    # --- Import of the old app's articles ----------------------------------------
    image_job = {'running': False, 'done': 0, 'total': 0, 'failed': 0}

    def article_files() -> List[str]:
        base = old_app_dir()
        found = []
        if base and os.path.isdir(base):
            for root, _, files in os.walk(base):
                for n in sorted(files):
                    p = os.path.join(root, n)
                    if is_articles_file(p):
                        found.append(os.path.relpath(p, base).replace('\\', '/'))
        return found

    def import_articles(rel: str, copy_images: bool = True) -> dict:
        base = os.path.realpath(old_app_dir())
        path = os.path.realpath(os.path.join(base, rel))
        if not path.startswith(base + os.sep) or not is_articles_file(path):
            raise HTTPException(400, 'Not an articles file')
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        result = {'file': rel, 'rows': len(data), 'inserted': 0, 'duplicates': 0}
        with db() as c:
            for a in data:
                art = parse_old_article(a)
                if art['ext_id'] and c.execute('SELECT 1 FROM articles WHERE ext_id = ?',
                                               (art['ext_id'],)).fetchone():
                    result['duplicates'] += 1
                    continue
                c.execute('INSERT INTO articles(user_id, author_name, title, body, category, kind, images, '
                          'source, ext_id, created_at) VALUES (NULL,?,?,?,?,?,?, "tifnit", ?, ?)',
                          (art['author'], art['title'], art['body'], art['category'], art['kind'],
                           json.dumps(art['images']), art['ext_id'], art['created_at']))
                result['inserted'] += 1
            c.execute('INSERT INTO import_log(file, tbl, target, inserted, at) VALUES (?, "forum", "articles", ?, ?)',
                      (rel, result['inserted'], int(time.time())))
        if copy_images:
            start_image_copy()
        return result

    def copy_remote_images() -> None:
        """Copies images still hosted on other sites to this server, so the
        articles keep their pictures if the old site closes."""
        try:
            with db() as c:
                rows = c.execute("SELECT id, images FROM articles WHERE images LIKE '%http%'").fetchall()
            todo = [(r['id'], json.loads(r['images'])) for r in rows]
            image_job.update(total=sum(len(i) for _, i in todo), done=0, failed=0)
            for article_id, images in todo:
                out = []
                for url in images:
                    if url.startswith('http'):
                        try:
                            req = urllib.request.Request(url, headers={'User-Agent': 'SayadForum/1.0'})
                            with urllib.request.urlopen(req, timeout=20) as res:
                                data = res.read(MAX_IMAGE + 1)
                            url = save_image(data) if len(data) <= MAX_IMAGE else url
                        except Exception:
                            image_job['failed'] += 1
                        image_job['done'] += 1
                    out.append(url)
                with db() as c:
                    c.execute('UPDATE articles SET images = ? WHERE id = ?', (json.dumps(out), article_id))
        finally:
            image_job['running'] = False

    def start_image_copy() -> bool:
        if image_job['running']:
            return False
        image_job['running'] = True
        threading.Thread(target=copy_remote_images, daemon=True).start()
        return True

    def auto_import() -> List[dict]:
        """Imports the articles files of the old app folder not imported yet."""
        with db() as c:
            done = {r[0] for r in c.execute("SELECT file FROM import_log WHERE tbl = 'forum'")}
        return [import_articles(f) for f in article_files() if f not in done]

    router.auto_import = auto_import

    @router.get('/admin/api/forum/import', dependencies=admin)
    def import_list():
        with db() as c:
            done = {r[0]: r[1] for r in c.execute(
                "SELECT file, SUM(inserted) FROM import_log WHERE tbl = 'forum' GROUP BY file")}
        return {'files': [{'file': f, 'imported': done.get(f)} for f in article_files()],
                'images': image_job.copy()}

    class ImportArticles(BaseModel):
        file: str
        copy_images: bool = True

    @router.post('/admin/api/forum/import', dependencies=admin)
    def import_run(req: ImportArticles):
        return import_articles(req.file, req.copy_images)

    @router.post('/admin/api/forum/import/images', dependencies=admin)
    def import_images():
        start_image_copy()
        return image_job.copy()

    return router
