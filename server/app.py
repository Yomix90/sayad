"""Sayad spots server: fishing spots and tackle shops for the Sayad app,
with a management dashboard at /admin.

Public:  read approved spots/shops, submit new ones (kept pending).
Admin:   dashboard + API under /admin (header X-Admin-Token).

Environment:
  ADMIN_TOKEN   password of the dashboard (required for /admin)
  SAYAD_DB      SQLite file (default: ./sayad.db)
  OLD_APP_DIR   folder scanned for files to import (default: ../old app)
  MEDIA_DIR     images of the forum (default: ./media)
"""
import csv
import hmac
import io
import os
import sqlite3
import time
from collections import defaultdict, deque
from contextlib import contextmanager
from typing import List, Literal, Optional

from fastapi import Depends, FastAPI, File, Header, HTTPException, Query, Request, UploadFile
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import FileResponse, RedirectResponse, Response
from pydantic import BaseModel, Field

import forum
import importer
import osm_import
import weather

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.environ.get('SAYAD_DB', os.path.join(HERE, 'sayad.db'))
# Tolerate quotes or spaces copied into the Dokploy environment.
ADMIN_TOKEN = os.environ.get('ADMIN_TOKEN', '').strip().strip('"\'').strip()
OLD_APP_DIR = os.environ.get('OLD_APP_DIR', os.path.join(HERE, '..', 'old app'))
MEDIA_DIR = os.environ.get('MEDIA_DIR', os.path.join(HERE, 'media'))

SCHEMA = """
CREATE TABLE IF NOT EXISTS spots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  kind TEXT NOT NULL DEFAULT 'other',
  species TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  icon TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',
  source TEXT NOT NULL DEFAULT 'app',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS spots_pos ON spots(status, lat, lon);
CREATE TABLE IF NOT EXISTS shops (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  lat REAL NOT NULL,
  lon REAL NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  icon TEXT NOT NULL DEFAULT '',
  gold INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  source TEXT NOT NULL DEFAULT 'app',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS shops_pos ON shops(status, lat, lon);
CREATE TABLE IF NOT EXISTS import_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file TEXT NOT NULL,
  tbl TEXT NOT NULL DEFAULT '',
  target TEXT NOT NULL,
  inserted INTEGER NOT NULL,
  at INTEGER NOT NULL
);
"""

# Columns added after the first version: added to existing databases.
MIGRATIONS = {
    'spots': {'icon': "TEXT NOT NULL DEFAULT ''", 'image_url': "TEXT NOT NULL DEFAULT ''",
              'ext_id': "TEXT NOT NULL DEFAULT ''"},
    'shops': {'description': "TEXT NOT NULL DEFAULT ''", 'icon': "TEXT NOT NULL DEFAULT ''",
              'image_url': "TEXT NOT NULL DEFAULT ''"},
}

Kind = Literal['rock', 'beach', 'port', 'jetty', 'lake', 'river', 'dam', 'boat', 'other']
Table = Literal['spots', 'shops']
Status = Literal['pending', 'approved', 'rejected']


def init_db(path: Optional[str] = None) -> None:
    path = path or DB_PATH
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with sqlite3.connect(path) as c:
        c.executescript(SCHEMA)
        c.executescript(forum.SCHEMA)
        for table, cols in MIGRATIONS.items():
            have = {r[1] for r in c.execute(f'PRAGMA table_info({table})')}
            for col, decl in cols.items():
                if col not in have:
                    c.execute(f'ALTER TABLE {table} ADD COLUMN {col} {decl}')
        c.execute('CREATE INDEX IF NOT EXISTS spots_ext ON spots(ext_id)')
        # Shops imported before phones were read from every number format.
        for sid, desc in c.execute("SELECT id, description FROM shops WHERE phone = '' AND description != ''").fetchall():
            phone = importer.extract_phone(desc)
            if phone:
                c.execute('UPDATE shops SET phone = ? WHERE id = ?', (phone, sid))


@contextmanager
def db():
    c = sqlite3.connect(DB_PATH)
    c.row_factory = sqlite3.Row
    try:
        yield c
        c.commit()
    finally:
        c.close()


app = FastAPI(title='Sayad API', version='1.1')
app.add_middleware(GZipMiddleware, minimum_size=1000)


@app.on_event('startup')
def _startup() -> None:
    init_db()
    try:
        forum_router.auto_import()
    except Exception as e:  # never block the start of the API
        print('Forum auto-import failed:', e)


# --- Simple per-IP limit on public submissions (5 per hour) ----------------
_recent: dict = defaultdict(deque)


def limit_submissions(request: Request) -> None:
    ip = request.headers.get('x-real-ip') or (request.client.host if request.client else '?')
    now = time.time()
    q = _recent[ip]
    while q and now - q[0] > 3600:
        q.popleft()
    if len(q) >= 5:
        raise HTTPException(429, 'Too many submissions, try again later')
    q.append(now)


def require_admin(x_admin_token: str = Header(default='')) -> None:
    given = x_admin_token.strip().strip('"\'').strip()
    if not ADMIN_TOKEN or not hmac.compare_digest(given, ADMIN_TOKEN):
        raise HTTPException(401, 'Admin token required')


# --- Models -----------------------------------------------------------------
class SpotIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    kind: Kind = 'other'
    species: str = Field(default='', max_length=200)
    description: str = Field(default='', max_length=500)


class ShopIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    phone: str = Field(default='', max_length=30)
    city: str = Field(default='', max_length=60)


def _bbox_query(table: str, cols: str, min_lat, max_lat, min_lon, max_lon, limit):
    with db() as c:
        rows = c.execute(
            f'SELECT {cols} FROM {table} WHERE status = "approved" '
            'AND lat BETWEEN ? AND ? AND lon BETWEEN ? AND ? LIMIT ?',
            (min_lat, max_lat, min_lon, max_lon, limit)).fetchall()
    return [dict(r) for r in rows]


# --- Public -----------------------------------------------------------------
@app.get('/')
def root():
    return RedirectResponse('/admin')


@app.get('/health')
def health():
    with db() as c:
        spots = c.execute('SELECT COUNT(*) FROM spots WHERE status="approved"').fetchone()[0]
        shops = c.execute('SELECT COUNT(*) FROM shops WHERE status="approved"').fetchone()[0]
    return {'ok': True, 'spots': spots, 'shops': shops}


@app.get('/spots')
def list_spots(min_lat: float = Query(-90), max_lat: float = Query(90),
               min_lon: float = Query(-180), max_lon: float = Query(180),
               limit: int = Query(2000, le=10000)):
    """Approved spots inside a bounding box."""
    return _bbox_query('spots', 'id, name, lat, lon, kind, species, description, icon, image_url',
                       min_lat, max_lat, min_lon, max_lon, limit)


@app.post('/spots', status_code=201, dependencies=[Depends(limit_submissions)])
def submit_spot(s: SpotIn):
    """A user proposes a spot; it stays pending until an admin approves it."""
    with db() as c:
        cur = c.execute(
            'INSERT INTO spots(name, lat, lon, kind, species, description, status, source, created_at) '
            'VALUES (?,?,?,?,?,?, "pending", "app", ?)',
            (s.name.strip(), s.lat, s.lon, s.kind, s.species.strip(), s.description.strip(),
             int(time.time())))
    return {'id': cur.lastrowid, 'status': 'pending'}


@app.get('/shops')
def list_shops(min_lat: float = Query(-90), max_lat: float = Query(90),
               min_lon: float = Query(-180), max_lon: float = Query(180),
               limit: int = Query(2000, le=10000)):
    return _bbox_query('shops', 'id, name, lat, lon, phone, city, gold, description, image_url',
                       min_lat, max_lat, min_lon, max_lon, limit)


@app.post('/shops', status_code=201, dependencies=[Depends(limit_submissions)])
def submit_shop(s: ShopIn):
    with db() as c:
        cur = c.execute(
            'INSERT INTO shops(name, lat, lon, phone, city, status, source, created_at) '
            'VALUES (?,?,?,?,?, "pending", "app", ?)',
            (s.name.strip(), s.lat, s.lon, s.phone.strip(), s.city.strip(), int(time.time())))
    return {'id': cur.lastrowid, 'status': 'pending'}


# --- Dashboard page ---------------------------------------------------------
@app.get('/admin', include_in_schema=False)
def dashboard():
    return FileResponse(os.path.join(HERE, 'dashboard', 'index.html'))


# --- Admin API ----------------------------------------------------------------
admin = [Depends(require_admin)]


@app.get('/admin/api/stats', dependencies=admin)
def stats():
    with db() as c:
        out = {}
        for t in ('spots', 'shops'):
            out[t] = {s: c.execute(f'SELECT COUNT(*) FROM {t} WHERE status=?', (s,)).fetchone()[0]
                      for s in ('approved', 'pending', 'rejected')}
            out[t]['sources'] = {r[0]: r[1] for r in c.execute(
                f'SELECT source, COUNT(*) FROM {t} GROUP BY source')}
    return out


# Rough box around Morocco (Algerian border to Dakhla), for the
# "outside Morocco" filter.
MOROCCO = (20.5, 36.2, -17.6, -0.9)


def _filter(table: str, status: Optional[str], q: str, source: str, area: str):
    where, args = [], []
    if status:
        where.append('status = ?')
        args.append(status)
    if source:
        where.append('source = ?')
        args.append(source)
    if q:
        where.append('(name LIKE ? OR description LIKE ?' + (' OR phone LIKE ?' if table == 'shops' else '') + ')')
        args += [f'%{q}%'] * (3 if table == 'shops' else 2)
    inside = 'lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?'
    if area == 'morocco':
        where.append(inside)
        args += list(MOROCCO)
    elif area == 'outside':
        where.append(f'NOT ({inside})')
        args += list(MOROCCO)
    return ('WHERE ' + ' AND '.join(where)) if where else '', args


@app.get('/admin/api/items', dependencies=admin)
def items(table: Table, status: Optional[Status] = None, q: str = '', source: str = '',
          area: Literal['', 'morocco', 'outside'] = '',
          offset: int = 0, limit: int = Query(50, le=20000)):
    sql_where, args = _filter(table, status, q, source, area)
    with db() as c:
        total = c.execute(f'SELECT COUNT(*) FROM {table} {sql_where}', args).fetchone()[0]
        rows = c.execute(f'SELECT * FROM {table} {sql_where} ORDER BY id DESC LIMIT ? OFFSET ?',
                         args + [limit, offset]).fetchall()
    return {'total': total, 'items': [dict(r) for r in rows]}


class ItemEdit(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=120)
    lat: Optional[float] = Field(default=None, ge=-90, le=90)
    lon: Optional[float] = Field(default=None, ge=-180, le=180)
    kind: Optional[str] = None
    species: Optional[str] = None
    description: Optional[str] = None
    phone: Optional[str] = None
    city: Optional[str] = None
    gold: Optional[bool] = None
    status: Optional[Status] = None


ALLOWED = {
    'spots': {'name', 'lat', 'lon', 'kind', 'species', 'description', 'status'},
    'shops': {'name', 'lat', 'lon', 'phone', 'city', 'description', 'gold', 'status'},
}


@app.put('/admin/api/{table}/{item_id}', dependencies=admin)
def edit(table: Table, item_id: int, body: ItemEdit):
    fields = {k: v for k, v in body.model_dump(exclude_none=True).items() if k in ALLOWED[table]}
    if not fields:
        raise HTTPException(400, 'Nothing to change')
    if 'gold' in fields:
        fields['gold'] = int(fields['gold'])
    sets = ', '.join(f'{k} = ?' for k in fields)
    with db() as c:
        cur = c.execute(f'UPDATE {table} SET {sets} WHERE id = ?', list(fields.values()) + [item_id])
    if cur.rowcount == 0:
        raise HTTPException(404, 'Not found')
    return {'id': item_id, **fields}


@app.delete('/admin/api/{table}/{item_id}', dependencies=admin)
def delete(table: Table, item_id: int):
    with db() as c:
        cur = c.execute(f'DELETE FROM {table} WHERE id = ?', (item_id,))
    if cur.rowcount == 0:
        raise HTTPException(404, 'Not found')
    return {'deleted': item_id}


class Convert(BaseModel):
    """Moves items to the other table (spot <-> shop). Either [ids], or every
    item matching the list filters when [all_matching] is true."""
    ids: List[int] = []
    all_matching: bool = False
    status: Optional[Status] = None
    q: str = ''
    source: str = ''
    area: Literal['', 'morocco', 'outside'] = ''


@app.post('/admin/api/{table}/convert', dependencies=admin)
def convert(table: Table, body: Convert):
    target = 'shops' if table == 'spots' else 'spots'
    if body.all_matching:
        sql_where, args = _filter(table, body.status, body.q, body.source, body.area)
    elif body.ids:
        sql_where = f'WHERE id IN ({",".join("?" * len(body.ids))})'
        args = list(body.ids)
    else:
        return {'converted': 0, 'into': target}
    with db() as c:
        rows = c.execute(f'SELECT * FROM {table} {sql_where}', args).fetchall()
        for r in rows:
            r = dict(r)
            if target == 'shops':
                phone = importer.extract_phone(r.get('description') or '')
                c.execute('INSERT INTO shops(name, lat, lon, phone, description, icon, image_url, status, source, created_at) '
                          'VALUES (?,?,?,?,?,?,?,?,?,?)',
                          (r['name'], r['lat'], r['lon'], phone, r.get('description') or '',
                           r.get('icon') or '', r.get('image_url') or '', r['status'], r['source'], r['created_at']))
            else:
                desc = ' · '.join(x for x in (r.get('phone'), r.get('city'), r.get('description')) if x)
                c.execute('INSERT INTO spots(name, lat, lon, kind, description, icon, image_url, status, source, created_at) '
                          "VALUES (?,?,?, 'other', ?,?,?,?,?,?)",
                          (r['name'], r['lat'], r['lon'], desc[:500], r.get('icon') or '',
                           r.get('image_url') or '', r['status'], r['source'], r['created_at']))
            c.execute(f'DELETE FROM {table} WHERE id = ?', (r['id'],))
    return {'converted': len(rows), 'into': target}


class BulkFilter(BaseModel):
    """Applies an action to every item matching the list filters."""
    action: Literal['approve', 'reject', 'pending', 'delete']
    status: Optional[Status] = None
    q: str = ''
    source: str = ''
    area: Literal['', 'morocco', 'outside'] = ''


@app.post('/admin/api/{table}/bulk-filter', dependencies=admin)
def bulk_filter(table: Table, body: BulkFilter):
    sql_where, args = _filter(table, body.status, body.q, body.source, body.area)
    with db() as c:
        if body.action == 'delete':
            cur = c.execute(f'DELETE FROM {table} {sql_where}', args)
        else:
            status = {'approve': 'approved', 'reject': 'rejected', 'pending': 'pending'}[body.action]
            cur = c.execute(f'UPDATE {table} SET status = ? {sql_where}', [status] + args)
    return {'changed': cur.rowcount}


class Bulk(BaseModel):
    ids: List[int]
    action: Literal['approve', 'reject', 'pending', 'delete']


@app.post('/admin/api/{table}/bulk', dependencies=admin)
def bulk(table: Table, body: Bulk):
    if not body.ids:
        return {'changed': 0}
    marks = ','.join('?' * len(body.ids))
    with db() as c:
        if body.action == 'delete':
            cur = c.execute(f'DELETE FROM {table} WHERE id IN ({marks})', body.ids)
        else:
            status = {'approve': 'approved', 'reject': 'rejected', 'pending': 'pending'}[body.action]
            cur = c.execute(f'UPDATE {table} SET status = ? WHERE id IN ({marks})', [status] + body.ids)
    return {'changed': cur.rowcount}


@app.get('/admin/api/export/{table}.csv', dependencies=admin)
def export(table: Table):
    with db() as c:
        rows = c.execute(f'SELECT * FROM {table} ORDER BY id').fetchall()
    buf = io.StringIO()
    w = csv.writer(buf)
    if rows:
        w.writerow(rows[0].keys())
        w.writerows([list(r) for r in rows])
    return Response(buf.getvalue().encode('utf-8-sig'), media_type='text/csv',
                    headers={'Content-Disposition': f'attachment; filename="{table}.csv"'})


# --- Import from the "old app" folder ----------------------------------------
def _safe_path(rel: str) -> str:
    base = os.path.realpath(OLD_APP_DIR)
    path = os.path.realpath(os.path.join(base, rel))
    if not path.startswith(base + os.sep) or not os.path.isfile(path):
        raise HTTPException(400, 'Unknown file')
    return path


def _imports_by_file():
    with db() as c:
        rows = c.execute('SELECT file, tbl, MAX(at) AS at, SUM(inserted) AS inserted '
                         'FROM import_log GROUP BY file, tbl').fetchall()
    return {(r['file'], r['tbl']): dict(r) for r in rows}


@app.get('/admin/api/import/files', dependencies=admin)
def import_files():
    log = _imports_by_file()
    files = importer.scan(OLD_APP_DIR)
    for f in files:
        f['uploaded'] = f['file'].startswith('uploads/')
        f['imported'] = log.get((f['file'], f['table'] or ''))
    return {'dir': os.path.realpath(OLD_APP_DIR), 'files': files}


class ImportReq(BaseModel):
    file: str
    table: Optional[str] = None
    into: Optional[Table] = None
    status: Literal['approved', 'pending'] = 'approved'
    source: str = Field(default='old_app', max_length=40)
    dry_run: bool = False


@app.post('/admin/api/import', dependencies=admin)
def run_import(req: ImportReq):
    path = _safe_path(req.file)
    result = importer.import_file(DB_PATH, path, table=req.table, into=req.into,
                                  status=req.status, source=req.source, dry_run=req.dry_run)
    if not req.dry_run and 'error' not in result:
        with db() as c:
            c.execute('INSERT INTO import_log(file, tbl, target, inserted, at) VALUES (?,?,?,?,?)',
                      (req.file, req.table or '', result['into'], result['inserted'], int(time.time())))
    return result


@app.post('/admin/api/import/upload', dependencies=admin)
async def upload(file: UploadFile = File(...)):
    name = os.path.basename(file.filename or '')
    if not name.lower().endswith(importer.SUPPORTED):
        raise HTTPException(400, 'Supported: ' + ', '.join(importer.SUPPORTED))
    folder = os.path.join(OLD_APP_DIR, 'uploads')
    os.makedirs(folder, exist_ok=True)
    data = await file.read()
    if len(data) > 50 * 1024 * 1024:
        raise HTTPException(413, 'File too large (50 MB max)')
    with open(os.path.join(folder, name), 'wb') as f:
        f.write(data)
    out = {'saved': f'uploads/{name}'}
    # Articles of the old app are imported into the forum right away.
    if forum.is_articles_file(os.path.join(folder, name)):
        out['forum'] = forum_router.auto_import()
    return out


def _uploaded_files():
    folder = os.path.join(OLD_APP_DIR, 'uploads')
    if not os.path.isdir(folder):
        return []
    return [f'uploads/{n}' for n in sorted(os.listdir(folder))
            if os.path.isfile(os.path.join(folder, n))]


class FileReq(BaseModel):
    file: str


@app.post('/admin/api/import/delete', dependencies=admin)
def delete_upload(req: FileReq):
    """Deletes one file sent from the dashboard (only in uploads/)."""
    if not req.file.startswith('uploads/'):
        raise HTTPException(400, 'Only uploaded files can be deleted')
    os.remove(_safe_path(req.file))
    return {'deleted': [req.file]}


@app.post('/admin/api/import/cleanup', dependencies=admin)
def cleanup_uploads():
    """Deletes uploaded files that were never imported."""
    used = {f for f, _ in _imports_by_file()}
    deleted = []
    for rel in _uploaded_files():
        if rel not in used:
            os.remove(_safe_path(rel))
            deleted.append(rel)
    return {'deleted': deleted}


# --- Import from OpenStreetMap -------------------------------------------------
class OsmReq(BaseModel):
    status: Literal['approved', 'pending'] = 'pending'


@app.post('/admin/api/import/osm', dependencies=admin)
def osm_start(req: OsmReq):
    if not osm_import.start(DB_PATH, req.status):
        raise HTTPException(409, 'An OpenStreetMap import is already running')
    return osm_import.status()


@app.get('/admin/api/import/osm', dependencies=admin)
def osm_status():
    return osm_import.status()


# --- Forum -------------------------------------------------------------------
forum_router = forum.create_router(db, require_admin, lambda: MEDIA_DIR, lambda: OLD_APP_DIR)
app.include_router(forum_router)
app.include_router(weather.create_router())


# --- Former review routes, kept for compatibility -----------------------------
@app.get('/admin/pending', dependencies=admin)
def pending():
    with db() as c:
        return {
            t: [dict(r) for r in c.execute(
                f'SELECT * FROM {t} WHERE status="pending" ORDER BY created_at').fetchall()]
            for t in ('spots', 'shops')
        }


@app.post('/admin/{table}/{item_id}/{action}', dependencies=admin)
def review(table: Table, item_id: int, action: Literal['approve', 'reject'],
           gold: Optional[bool] = None):
    status = 'approved' if action == 'approve' else 'rejected'
    with db() as c:
        cur = c.execute(f'UPDATE {table} SET status=? WHERE id=?', (status, item_id))
        if gold is not None and table == 'shops':
            c.execute('UPDATE shops SET gold=? WHERE id=?', (int(gold), item_id))
    if cur.rowcount == 0:
        raise HTTPException(404, 'Not found')
    return {'id': item_id, 'status': status}
