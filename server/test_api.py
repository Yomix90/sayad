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

server.DB_PATH = os.environ['SAYAD_DB']
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


if __name__ == '__main__':
    for name, fn in list(globals().items()):
        if name.startswith('test_'):
            fn()
            print('ok', name)
