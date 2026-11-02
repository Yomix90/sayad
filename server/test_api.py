"""Run: python -m pytest server/test_api.py  (or python server/test_api.py)"""
import os
import sys
import tempfile

TMP = tempfile.mkdtemp()
os.environ['SAYAD_DB'] = os.path.join(TMP, 'test.db')
os.environ['OLD_APP_DIR'] = os.path.join(TMP, 'old_app')
os.environ['ADMIN_TOKEN'] = 'secret-test'
sys.path.insert(0, os.path.dirname(__file__))

from fastapi.testclient import TestClient  # noqa: E402

import app as server  # noqa: E402
import forum  # noqa: E402

server.DB_PATH = os.environ['SAYAD_DB']
server.MEDIA_DIR = os.path.join(TMP, 'media')
server.ADMIN_TOKEN = 'secret-test'
server.OLD_APP_DIR = os.environ['OLD_APP_DIR']
server.init_db()
client = TestClient(server.app)
ADMIN = {'X-Admin-Token': 'secret-test'}


def test_submit_review_and_list():
    r = client.post('/spots', json={'name': 'Jetée de Mohammedia', 'lat': 33.7, 'lon': -7.39,
                                    'kind': 'jetty', 'species': 'Bar, Sar'})
    assert r.status_code == 201 and r.json()['status'] == 'pending'
    sid = r.json()['id']
    # Pending spots are not public.
    assert client.get('/spots').json() == []
    # Admin approves it.
    assert client.post(f'/admin/spots/{sid}/approve').status_code == 401
    assert client.post(f'/admin/spots/{sid}/approve', headers=ADMIN).json()['status'] == 'approved'
    spots = client.get('/spots', params={'min_lat': 33, 'max_lat': 34, 'min_lon': -8, 'max_lon': -7}).json()
    assert [s['name'] for s in spots] == ['Jetée de Mohammedia']
    # Outside the box: nothing.
    assert client.get('/spots', params={'min_lat': 30, 'max_lat': 31}).json() == []
    assert client.get('/health').json()['spots'] == 1


def test_validation_and_rate_limit():
    server._recent.clear()
    assert client.post('/spots', json={'name': 'x', 'lat': 100, 'lon': 0}).status_code == 422
    server._recent.clear()
    codes = [client.post('/shops', json={'name': f'Shop {i}', 'lat': 33, 'lon': -7}).status_code
             for i in range(6)]
    assert codes[:5] == [201] * 5 and codes[5] == 429


def test_admin_pending_requires_token():
    assert client.get('/admin/pending').status_code == 401
    # Spaces or quotes around a pasted token are ignored.
    assert client.get('/admin/api/stats', headers={'X-Admin-Token': ' "secret-test" '}).status_code == 200
    assert client.get('/admin/api/stats', headers={'X-Admin-Token': 'Secret-test'}).status_code == 401
    assert 'spots' in client.get('/admin/pending', headers=ADMIN).json()


def _old_app_files():
    import sqlite3
    os.makedirs(server.OLD_APP_DIR, exist_ok=True)
    c = sqlite3.connect(os.path.join(server.OLD_APP_DIR, 'ast.db'))
    c.execute('CREATE TABLE Masaid (Name TEXT, Lat REAL, Long REAL, Icon TEXT, Inf TEXT)')
    c.executemany('INSERT INTO Masaid VALUES (?,?,?,?,?)', [
        ('انزا - Anza', 30.43, -9.65, 'p1', None),
        ('Rochers', 33.52, -7.83, 'p2', 'Sar et bar'),
        ('Rochers', 33.52, -7.83, 'p2', 'doublon'),
        ('Bad', 0, 0, 'p1', None),
    ])
    c.commit(); c.close()
    c = sqlite3.connect(os.path.join(server.OLD_APP_DIR, 'asx.db'))
    c.execute('CREATE TABLE Matajir (Name TEXT, Lat REAL, Long REAL, Icon TEXT, Inf TEXT)')
    c.execute('INSERT INTO Matajir VALUES (?,?,?,?,?)',
              ('Shop Test', 33.6, -7.6, 'shop3', 'Appelez le 06 12 34 56 78 svp'))
    c.commit(); c.close()


def test_dashboard_and_import_old_app():
    _old_app_files()
    assert client.get('/admin').status_code == 200
    assert client.get('/admin/api/import/files').status_code == 401
    files = client.get('/admin/api/import/files', headers=ADMIN).json()['files']
    by = {f['table']: f for f in files}
    assert by['Masaid']['target'] == 'spots' and by['Matajir']['target'] == 'shops'

    dry = client.post('/admin/api/import', headers=ADMIN,
                      json={'file': 'ast.db', 'table': 'Masaid', 'dry_run': True}).json()
    assert dry['valid'] == 3 and dry['invalid'] == 1 and dry['inserted'] == 0

    r = client.post('/admin/api/import', headers=ADMIN, json={'file': 'ast.db', 'table': 'Masaid'}).json()
    assert r['inserted'] == 2 and r['duplicates'] == 1 and r['invalid'] == 1
    again = client.post('/admin/api/import', headers=ADMIN, json={'file': 'ast.db', 'table': 'Masaid'}).json()
    assert again['inserted'] == 0 and again['duplicates'] == 3

    shop = client.post('/admin/api/import', headers=ADMIN, json={'file': 'asx.db', 'table': 'Matajir'}).json()
    assert shop['inserted'] == 1
    items = client.get('/admin/api/items', headers=ADMIN, params={'table': 'shops', 'q': 'Shop Test'}).json()
    s = items['items'][0]
    assert s['phone'] == '0612345678' and s['gold'] == 1 and s['status'] == 'approved'

    # Files outside the old app folder are refused.
    assert client.post('/admin/api/import', headers=ADMIN,
                       json={'file': '../test.db'}).status_code == 400


def test_admin_edit_bulk_and_export():
    server._recent.clear()
    sid = client.post('/spots', json={'name': 'A modifier', 'lat': 35, 'lon': -5}).json()['id']
    r = client.put(f'/admin/api/spots/{sid}', headers=ADMIN, json={'name': 'Modifié', 'species': 'Dorade'})
    assert r.json()['name'] == 'Modifié'
    assert client.post('/admin/api/spots/bulk', headers=ADMIN,
                       json={'ids': [sid], 'action': 'approve'}).json()['changed'] == 1
    stats = client.get('/admin/api/stats', headers=ADMIN).json()
    assert stats['spots']['approved'] >= 1
    csv_text = client.get('/admin/api/export/spots.csv', headers=ADMIN).content.decode('utf-8-sig')
    assert 'Modifié' in csv_text
    assert client.delete(f'/admin/api/spots/{sid}', headers=ADMIN).json()['deleted'] == sid


def test_select_all_by_filter():
    import sqlite3
    with sqlite3.connect(server.DB_PATH) as c:
        c.executemany('INSERT INTO spots(name, lat, lon, status, source, created_at) VALUES (?,?,?,?,?,0)', [
            ('Maroc 1', 33.5, -7.6, 'approved', 'bulkcase'),
            ('Maroc 2', 30.4, -9.6, 'approved', 'bulkcase'),
            ('Indonésie', -6.6, 98.6, 'approved', 'bulkcase'),
        ])
    q = {'table': 'spots', 'source': 'bulkcase'}
    assert client.get('/admin/api/items', headers=ADMIN, params={**q, 'area': 'outside'}).json()['total'] == 1
    assert client.get('/admin/api/items', headers=ADMIN, params={**q, 'area': 'morocco'}).json()['total'] == 2
    # Delete everything outside Morocco from that source, without ids.
    r = client.post('/admin/api/spots/bulk-filter', headers=ADMIN,
                    json={'action': 'delete', 'source': 'bulkcase', 'area': 'outside'})
    assert r.json()['changed'] == 1
    r = client.post('/admin/api/spots/bulk-filter', headers=ADMIN,
                    json={'action': 'pending', 'source': 'bulkcase'})
    assert r.json()['changed'] == 2
    assert client.post('/admin/api/spots/bulk-filter', json={'action': 'delete'}).status_code == 401
    # "Show all": large pages are allowed.
    assert client.get('/admin/api/items', headers=ADMIN, params={'table': 'spots', 'limit': 20000}).status_code == 200


def test_osm_import():
    import json
    import osm_import
    tile = json.load(open(os.path.join(os.path.dirname(__file__), 'testdata_osm_tile.json'), encoding='utf-8'))
    osm_import.run(server.DB_PATH, 'pending', tiles=[(0, 0, 1, 1)], fetch=lambda _: tile, pause=0)
    st = osm_import.status()
    assert not st['running'] and st['errors'] == []
    assert st['inserted'] == 3 and st['by_kind'] == {'jetty': 1, 'beach': 1, 'port': 1}
    items = client.get('/admin/api/items', headers=ADMIN, params={'table': 'spots', 'source': 'osm'}).json()
    names = sorted(i['name'] for i in items['items'])
    assert names == ['Plage Des Sablettes', 'Port de pêche', 'رصيف - Jetée']
    assert all(i['status'] == 'pending' for i in items['items'])
    # Running again adds nothing (same OSM ids).
    osm_import.run(server.DB_PATH, 'pending', tiles=[(0, 0, 1, 1)], fetch=lambda _: tile, pause=0)
    assert osm_import.status()['inserted'] == 0 and osm_import.status()['duplicates'] == 3
    assert client.get('/admin/api/import/osm').status_code == 401
    assert client.get('/admin/api/import/osm', headers=ADMIN).json()['done'] == 1


def test_convert_spots_and_shops():
    import sqlite3
    with sqlite3.connect(server.DB_PATH) as c:
        c.execute("INSERT INTO spots(name, lat, lon, description, status, source, created_at) "
                  "VALUES ('Magasin mal rangé', 33.6, -7.6, 'Tel 0661 23 45 67', 'approved', 'convcase', 0)")
        c.execute("INSERT INTO spots(name, lat, lon, status, source, created_at) "
                  "VALUES ('Vrai spot', 33.7, -7.4, 'approved', 'convcase', 0)")
    items = client.get('/admin/api/items', headers=ADMIN, params={'table': 'spots', 'source': 'convcase'}).json()
    wrong = next(i for i in items['items'] if i['name'] == 'Magasin mal rangé')
    r = client.post('/admin/api/spots/convert', headers=ADMIN, json={'ids': [wrong['id']]}).json()
    assert r == {'converted': 1, 'into': 'shops'}
    shop = client.get('/admin/api/items', headers=ADMIN,
                      params={'table': 'shops', 'q': 'Magasin mal rangé'}).json()['items'][0]
    assert shop['phone'] == '0661234567' and shop['status'] == 'approved'
    # And back, using the filter instead of ids.
    r = client.post('/admin/api/shops/convert', headers=ADMIN,
                    json={'all_matching': True, 'source': 'convcase'}).json()
    assert r['converted'] == 1
    left = client.get('/admin/api/items', headers=ADMIN, params={'table': 'spots', 'source': 'convcase'}).json()
    assert left['total'] == 2
    assert client.post('/admin/api/spots/convert', json={'ids': [1]}).status_code == 401


def test_import_log_and_upload_cleanup():
    up = os.path.join(server.OLD_APP_DIR, 'uploads')
    os.makedirs(up, exist_ok=True)
    for name in ('used.csv', 'unused.csv'):
        with open(os.path.join(up, name), 'w', encoding='utf-8') as f:
            f.write('name,lat,lon' + chr(10) + 'Spot csv,33.1,-8.6' + chr(10))
    client.post('/admin/api/import', headers=ADMIN, json={'file': 'uploads/used.csv', 'into': 'spots'})
    files = {f['file']: f for f in client.get('/admin/api/import/files', headers=ADMIN).json()['files']}
    assert files['uploads/used.csv']['imported']['inserted'] == 1
    assert files['uploads/unused.csv']['imported'] is None and files['uploads/unused.csv']['uploaded']
    assert files['ast.db']['uploaded'] is False
    r = client.post('/admin/api/import/cleanup', headers=ADMIN).json()
    assert r['deleted'] == ['uploads/unused.csv']
    assert os.path.exists(os.path.join(up, 'used.csv'))
    # Only uploaded files can be deleted, one by one.
    assert client.post('/admin/api/import/delete', headers=ADMIN, json={'file': 'ast.db'}).status_code == 400
    assert client.post('/admin/api/import/delete', headers=ADMIN,
                       json={'file': 'uploads/../../x'}).status_code == 400
    assert client.post('/admin/api/import/delete', headers=ADMIN,
                       json={'file': 'uploads/used.csv'}).json() == {'deleted': ['uploads/used.csv']}


def test_shop_phones_and_old_app_json():
    import importer
    assert importer.extract_phone('Hassan Peche//\nwww.x.com//\n0528 33 22 32//') == '0528332232'
    assert importer.extract_phone('0912406462') == '0912406462'
    assert importer.extract_phone('686845248045036//hasweb') == ''  # page id, not a phone
    assert importer.extract_phone('Ouvert le matin') == ''
    path = os.path.join(server.OLD_APP_DIR, 'tifnit_complet.json')
    import json
    json.dump({'metadata': {'total': 2},
               'spots': [{'nom': 'Anza', 'latitude': 30.45, 'longitude': -9.66, 'photo_url': 'https://x/1.jpg'}],
               'magasins': [{'nom': 'Hassan Peche', 'latitude': 30.35, 'longitude': -9.53,
                             'description': 'Hassan Peche//\nwww.hassan-peche.com//\n0528332232//',
                             'telephone': '0528332232', 'photo_url': 'https://x/s.jpg'}]},
              open(path, 'w', encoding='utf-8'))
    files = [f for f in client.get('/admin/api/import/files', headers=ADMIN).json()['files']
             if f['file'] == 'tifnit_complet.json']
    assert {(f['table'], f['target']) for f in files} == {('spots', 'spots'), ('magasins', 'shops')}
    r = client.post('/admin/api/import', headers=ADMIN,
                    json={'file': 'tifnit_complet.json', 'table': 'magasins'}).json()
    assert r['inserted'] == 1 and r['into'] == 'shops'
    shop = [s for s in client.get('/shops', params={'min_lat': 30.3, 'max_lat': 30.4}).json()
            if s['name'] == 'Hassan Peche'][0]
    assert shop['phone'] == '0528332232' and shop['image_url'] == 'https://x/s.jpg'
    assert shop['description'] == 'Hassan Peche\nwww.hassan-peche.com\n0528332232'


OLD_ARTICLES = [
    {'id': 80, 'titre': 'Le leurre et la lumière', 'categorie': 'الاسئلة - Questions & Réponses',
     'images': ['https://www.tifnit.com/a.jpg'],
     'texte': 'Premier paragraphe.\nDeuxième ligne.\n31-12-2017\nلكديرة',
     'content_html': '<iframe src="https://www.youtube.com/embed/abcdefghijk"></iframe>'},
    {'id': 81, 'titre': 'Surfcasting à Agadir', 'categorie': 'القصبة الرامية - Surfcasting',
     'images': [], 'texte': 'Texte sans date', 'content_html': ''},
]


def _user(name='pecheur1'):
    forum.register_limit.clear()
    r = client.post('/auth/register', json={'username': name, 'password': 'secret123',
                                            'display_name': name.title()})
    assert r.status_code == 201, r.text
    return {'Authorization': 'Bearer ' + r.json()['token']}


def test_forum_accounts_articles_reactions_comments():
    alice = _user('alice')
    # Same name twice, wrong password, missing token.
    assert client.post('/auth/register', json={'username': 'ALICE', 'password': 'secret123'}).status_code == 409
    assert client.post('/auth/login', json={'username': 'alice', 'password': 'nope'}).status_code == 401
    assert client.post('/auth/login', json={'username': 'alice', 'password': 'secret123'}).status_code == 200
    assert client.get('/auth/me', headers=alice).json()['display_name'] == 'Alice'
    assert client.post('/forum/articles', json={'title': 'Hello', 'body': 'x'}).status_code == 401

    # Image upload: only real images.
    png = b'\x89PNG\r\n\x1a\n' + b'0' * 50
    up = client.post('/forum/images', headers=alice, files={'file': ('a.png', png, 'image/png')})
    assert up.status_code == 201
    url = up.json()['url']
    assert client.get(url).content == png
    bad = client.post('/forum/images', headers=alice, files={'file': ('a.png', b'<html>', 'image/png')})
    assert bad.status_code == 400

    r = client.post('/forum/articles', headers=alice, json={
        'title': 'Belle prise à Dakhla', 'body': 'Une courbine de 12 kg.', 'category': 'catches',
        'images': [url, 'https://evil.example/x.jpg']})
    assert r.status_code == 201
    art = r.json()
    assert art['images'] == [url] and art['author'] == 'Alice'

    bob = _user('bob')
    assert client.post(f"/forum/articles/{art['id']}/react", headers=bob, json={'type': 'fish'}).json() == \
        {'reactions': {'fish': 1}, 'my_reaction': 'fish'}
    client.post(f"/forum/articles/{art['id']}/react", headers=alice, json={'type': 'like'})
    # The same reaction again removes it.
    assert client.post(f"/forum/articles/{art['id']}/react", headers=bob, json={'type': 'fish'}).json()[
        'reactions'] == {'like': 1}
    comments = client.post(f"/forum/articles/{art['id']}/comments", headers=bob, json={'body': 'Bravo !'}).json()
    assert [c['author'] for c in comments] == ['Bob']

    items = client.get('/forum/articles', params={'category': 'catches'}).json()['items']
    assert items[0]['comments'] == 1 and items[0]['reactions'] == {'like': 1}
    full = client.get(f"/forum/articles/{art['id']}", headers=alice).json()
    assert full['my_reaction'] == 'like' and full['body'] == 'Une courbine de 12 kg.'

    # Only the author deletes the article; a banned user cannot post.
    assert client.delete(f"/forum/articles/{art['id']}", headers=bob).status_code == 404
    assert client.put(f"/admin/api/forum/users/{full['user_id']}", headers=ADMIN,
                      json={'banned': True}).status_code == 200
    assert client.post('/forum/articles', headers=alice, json={'title': 'Encore', 'body': 'x'}).status_code == 401
    users = client.get('/admin/api/forum/users', headers=ADMIN).json()
    assert {u['username']: u['banned'] for u in users}['alice'] == 1

    # Admin hides it: not public any more.
    client.put(f"/admin/api/forum/articles/{art['id']}", headers=ADMIN, json={'status': 'hidden'})
    assert client.get(f"/forum/articles/{art['id']}").status_code == 404


def test_forum_import_old_articles():
    import json
    a = forum.parse_old_article(OLD_ARTICLES[0])
    assert a['author'] == 'Admin' and a['category'] == 'qa' and a['kind'] == 'question'
    assert a['body'] == 'Premier paragraphe.\nDeuxième ligne.\n\nhttps://www.youtube.com/watch?v=abcdefghijk'
    assert a['created_at'] == 1514721600 and a['ext_id'] == 'tifnit:80'

    up = os.path.join(server.OLD_APP_DIR, 'uploads')
    os.makedirs(up, exist_ok=True)
    data = json.dumps(OLD_ARTICLES).encode()
    r = client.post('/admin/api/import/upload', headers=ADMIN,
                    files={'file': ('encyclopedie.json', data, 'application/json')}).json()
    # Imported as soon as it is sent; images are copied in the background.
    assert r['forum'][0]['inserted'] == 2
    assert client.get('/admin/api/forum/import', headers=ADMIN).json()['files'] == [
        {'file': 'uploads/encyclopedie.json', 'imported': 2}]
    again = client.post('/admin/api/forum/import', headers=ADMIN,
                        json={'file': 'uploads/encyclopedie.json', 'copy_images': False}).json()
    assert again['inserted'] == 0 and again['duplicates'] == 2
    titles = [x['title'] for x in client.get('/forum/articles', params={'q': 'Surfcasting'}).json()['items']]
    assert titles == ['Surfcasting à Agadir']
    # Not offered as a spots file.
    assert all(f['file'] != 'uploads/encyclopedie.json'
               for f in client.get('/admin/api/import/files', headers=ADMIN).json()['files'])


def test_weather_grid_cache():
    import urllib.error
    import weather
    calls = []

    def fake(url):
        calls.append(url)
        if len(calls) > 1:
            raise urllib.error.URLError('overloaded')
        return b'[{"hourly": {"time": ["2026-11-02T00:00"], "wind_speed_10m": [12]}}]'

    weather.fetch, real = fake, weather.fetch
    weather._cache.clear()
    try:
        q = {'latitude': '30,31', 'longitude': '-9,-9', 'hourly': 'wind_speed_10m,wind_direction_10m'}
        r = client.get('/weather/grid', params=q)
        assert r.status_code == 200 and r.headers['x-cache'] == 'miss'
        assert 'api.open-meteo.com' in calls[0] and 'wind_speed_unit=kmh' in calls[0]
        # Same grid for another user: from the cache.
        assert client.get('/weather/grid', params=q).headers['x-cache'] == 'hit'
        assert len(calls) == 1
        # Open-Meteo down after an hour: the old grid is still served.
        for k, (t, body) in list(weather._cache.items()):
            weather._cache[k] = (t - 2 * 3600, body)
        r = client.get('/weather/grid', params=q)
        assert r.headers['x-cache'] == 'stale' and r.json()[0]['hourly']['wind_speed_10m'] == [12]
        # A grid never fetched while Open-Meteo is down.
        assert client.get('/weather/grid', params={**q, 'latitude': '20,21'}).status_code == 503
        # Waves go to the marine API; bad input is refused.
        weather._cache.clear()
        calls.clear()
        client.get('/weather/grid', params={**q, 'hourly': 'wave_height,wave_direction'})
        assert 'marine-api' in calls[0] and 'cell_selection=nearest' in calls[0]
        assert client.get('/weather/grid', params={**q, 'hourly': 'wave_height,temperature_2m'}).status_code == 422
        assert client.get('/weather/grid', params={**q, 'hourly': 'secret'}).status_code == 422
        assert client.get('/weather/grid', params={**q, 'latitude': ','.join(['1'] * 201),
                                                   'longitude': ','.join(['1'] * 201)}).status_code == 422
    finally:
        weather.fetch = real


def test_forum_kinds_bulk_and_ai():
    import ai
    forum.register_limit.clear()
    forum.ai_limit.clear()
    h = _user('carla')
    q = client.post('/forum/articles', headers=h, json={
        'title': 'Quel leurre pour le bar ?', 'body': 'A Essaouira en hiver', 'kind': 'question'}).json()
    art = client.post('/forum/articles', headers=h, json={'title': 'Sortie à Mirleft', 'body': 'Belle journée'}).json()
    assert q['kind'] == 'question' and art['kind'] == 'article'
    kinds = lambda k: {x['id'] for x in client.get('/forum/articles', params={'kind': k, 'limit': 100}).json()['items']}
    assert q['id'] in kinds('question') and q['id'] not in kinds('article')

    # Admin: every filtered article signed Admin, one switched to a question.
    r = client.post('/admin/api/forum/articles/bulk', headers=ADMIN,
                    json={'action': 'author_admin', 'all_matching': True}).json()
    assert r['changed'] >= 2
    assert {x['author'] for x in client.get('/forum/articles', params={'limit': 100}).json()['items']} == {'Admin'}
    client.post('/admin/api/forum/articles/bulk', headers=ADMIN, json={'action': 'to_question', 'ids': [art['id']]})
    assert art['id'] in kinds('question')
    stats = client.get('/admin/api/forum/articles', headers=ADMIN, params={'kind': 'question'}).json()
    assert all(x['kind'] == 'question' for x in stats['items']) and stats['stats']['questions'] >= 2

    # AI: refused without a key, otherwise a suggestion the admin saves.
    os.environ.pop('ANTHROPIC_API_KEY', None)
    os.environ.pop('GEMINI_API_KEY', None)
    assert client.get('/forum/ai').json() == {'enabled': False}
    assert client.post(f"/admin/api/forum/articles/{art['id']}/improve", headers=ADMIN).status_code == 503
    seen = []
    real = ai.improve
    def fake(title, body, kind='article'):
        seen.append((title, body, kind))
        return {'title': title + ' (revu)', 'body': body + '.'}
    ai.improve = fake
    try:
        s = client.post(f"/admin/api/forum/articles/{art['id']}/improve", headers=ADMIN).json()
        assert s == {'title': 'Sortie à Mirleft (revu)', 'body': 'Belle journée.'}
        assert seen[-1][2] == 'question'
        client.put(f"/admin/api/forum/articles/{art['id']}", headers=ADMIN, json=s)
        assert client.get(f"/forum/articles/{art['id']}").json()['body'] == 'Belle journée.'
        # Users while writing; login required.
        assert client.post('/forum/ai/improve', json={'body': 'x'}).status_code == 401
        assert client.post('/forum/ai/improve', headers=h, json={'title': 'T', 'body': 'b'}).json()['body'] == 'b.'
    finally:
        ai.improve = real


def test_gemini_rewrite_and_claude_fallback():
    import json
    import urllib.error
    import ai
    sent = []

    def fake_call(path, payload=None):
        sent.append((path, payload))
        if path.startswith('models?'):
            return {'models': [
                {'name': 'models/gemini-2.5-flash', 'supportedGenerationMethods': ['generateContent']},
                {'name': 'models/gemini-3.6-flash', 'supportedGenerationMethods': ['generateContent']},
                {'name': 'models/gemini-3.6-flash-lite', 'supportedGenerationMethods': ['generateContent']},
                {'name': 'models/gemini-3.7-pro', 'supportedGenerationMethods': ['generateContent']},
                {'name': 'models/text-embedding-004', 'supportedGenerationMethods': ['embedContent']},
            ]}
        text = json.dumps({'title': 'Le bar en hiver', 'body': 'Quel leurre utiliser ?'})
        return {'candidates': [{'content': {'parts': [{'text': text}]}}]}

    real_call, real_claude = ai._gemini_call, ai.claude
    ai._gemini_call, ai._gemini_model = fake_call, None
    os.environ['GEMINI_API_KEY'] = 'test-key'
    try:
        assert ai.enabled()
        out = ai.improve('bar', 'quel leure pour le bar', 'question')
        assert out == {'title': 'Le bar en hiver', 'body': 'Quel leurre utiliser ?'}
        # Newest free Flash model, the system prompt and a JSON answer.
        path, payload = sent[-1]
        assert path == 'models/gemini-3.6-flash:generateContent'
        assert 'Sayad' in payload['systemInstruction']['parts'][0]['text']
        assert payload['generationConfig']['responseMimeType'] == 'application/json'
        assert payload['contents'][0]['parts'][0]['text'].startswith('Question')

        # Gemini over its free quota: Claude takes over when its key is set.
        def busy(path, payload=None):
            raise urllib.error.HTTPError('u', 429, 'quota', {}, None)
        ai._gemini_call = busy
        try:
            ai.improve('t', 'b')
            assert False, 'expected 429'
        except Exception as e:
            assert getattr(e, 'status_code', None) == 429
        os.environ['ANTHROPIC_API_KEY'] = 'sk-test'
        ai.claude = lambda prompt: {'title': 'Par Claude', 'body': 'ok'}
        assert ai.improve('t', 'b')['title'] == 'Par Claude'
    finally:
        ai._gemini_call, ai.claude, ai._gemini_model = real_call, real_claude, None
        os.environ.pop('GEMINI_API_KEY', None)
        os.environ.pop('ANTHROPIC_API_KEY', None)


def test_dashboard_javascript_is_valid():
    """A syntax error in the page's script silently breaks the login button."""
    import shutil
    import subprocess
    node = shutil.which('node')
    if not node:
        return  # Node.js not installed: nothing to check.
    html = open(os.path.join(os.path.dirname(__file__), 'dashboard', 'index.html'), encoding='utf-8').read()
    start = html.index('<script>', html.index('</dialog>')) + len('<script>')
    script = html[start:html.rindex('</script>')]
    path = os.path.join(TMP, 'dashboard.js')
    open(path, 'w', encoding='utf-8').write(script)
    r = subprocess.run([node, '--check', path], capture_output=True, text=True)
    assert r.returncode == 0, r.stderr


if __name__ == '__main__':
    for name, fn in list(globals().items()):
        if name.startswith('test_'):
            fn()
            print('ok', name)
