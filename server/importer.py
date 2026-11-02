"""Import spots and shops from SQLite (.db), CSV, JSON or GeoJSON files.

Used by the command line (import_spots.py) and the admin dashboard.
Column names are detected automatically (e.g. the old app's tables
`Masaid` / `Matajir` with Name, Lat, Long, Icon, Inf).
"""
import csv
import json
import os
import re
import sqlite3
import time

NAME = ('name', 'nom', 'title', 'titre', 'label', 'spot')
LAT = ('lat', 'latitude', 'lati', 'y')
LON = ('lon', 'lng', 'long', 'longitude', 'longi', 'x')
PHONE = ('phone', 'tel', 'telephone', 'mobile', 'gsm')
INFO = ('inf', 'info', 'infos', 'description', 'desc', 'details', 'notes')
ICON = ('icon', 'type', 'kind', 'category', 'categorie')
IMAGE = ('imageurl', 'image', 'image_url', 'photo_url', 'photo', 'img')
SHOP_HINTS = ('matajir', 'shop', 'magasin', 'store', 'متاجر')
SUPPORTED = ('.db', '.sqlite', '.sqlite3', '.csv', '.json', '.geojson')

# Moroccan phone numbers in free text: 06…, 07…, 05…, +212…
PHONE_RE = re.compile(r'(?:\+212|00212|0)\s?[5-7](?:[\s.-]?\d){8}')
# Any other number written alone on a line (other countries, landlines).
OTHER_PHONE_RE = re.compile(r'^\s*(\+?\d[\d\s.-]{6,18}\d)\s*$')


def extract_phone(text: str) -> str:
    """First phone number of a shop's free text, without spaces."""
    text = text or ''
    m = PHONE_RE.search(text)
    if m:
        return re.sub(r'[\s.-]', '', m.group(0))
    for part in re.split(r'//|\n', text):
        m = OTHER_PHONE_RE.match(part)
        if m:
            digits = re.sub(r'[\s.-]', '', m.group(1))
            if 8 <= len(digits.lstrip('+')) <= 13:
                return digits
    return ''


def clean_info(text: str) -> str:
    """The old app separates the lines of its texts with '//'."""
    parts = [p.strip() for p in re.split(r'//', text or '')]
    return '\n'.join(p for p in parts if p)


def _pick(cols, names):
    low = {c.lower(): c for c in cols}
    for n in names:
        if n in low:
            return low[n]
    for c in cols:
        if any(c.lower().startswith(n) for n in names if len(n) > 2):
            return c
    return None


def _guess_target(table: str, file: str) -> str:
    text = f'{table} {os.path.basename(file)}'.lower()
    return 'shops' if any(h in text for h in SHOP_HINTS) else 'spots'


def _sqlite_tables(path):
    con = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    try:
        out = []
        for (t,) in con.execute("SELECT name FROM sqlite_master WHERE type='table'"):
            cols = [r[1] for r in con.execute(f'PRAGMA table_info("{t}")')]
            if _pick(cols, LAT) and _pick(cols, LON):
                n = con.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
                out.append({'table': t, 'rows': n, 'columns': cols})
        return out
    finally:
        con.close()


def _read_rows(path, table=None):
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.db', '.sqlite', '.sqlite3'):
        con = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
        con.row_factory = sqlite3.Row
        try:
            if table is None:
                tables = _sqlite_tables(path)
                if not tables:
                    return []
                table = tables[0]['table']
            return [dict(r) for r in con.execute(f'SELECT * FROM "{table}"')]
        finally:
            con.close()
    if ext == '.csv':
        with open(path, encoding='utf-8-sig', newline='') as f:
            return list(csv.DictReader(f))
    data = json.load(open(path, encoding='utf-8'))
    if isinstance(data, dict) and table and isinstance(data.get(table), list):
        return data[table]
    if isinstance(data, dict) and 'features' in data:
        rows = []
        for feat in data['features']:
            lon, lat = feat['geometry']['coordinates'][:2]
            rows.append({**(feat.get('properties') or {}), 'lat': lat, 'lon': lon})
        return rows
    return data if isinstance(data, list) else []


def _json_tables(path):
    """Lists of places inside one JSON object, e.g. {"spots": [...], "magasins": [...]}."""
    data = json.load(open(path, encoding='utf-8'))
    if not isinstance(data, dict) or 'features' in data:
        return []
    out = []
    for key, rows in data.items():
        if isinstance(rows, list) and rows and isinstance(rows[0], dict):
            cols = list(rows[0].keys())
            if _pick(cols, LAT) and _pick(cols, LON):
                out.append({'table': key, 'rows': len(rows), 'columns': cols})
    return out


def scan(directory):
    """Files that can be imported in [directory], with their tables."""
    found = []
    if not directory or not os.path.isdir(directory):
        return found
    for root, _, files in os.walk(directory):
        for name in sorted(files):
            path = os.path.join(root, name)
            ext = os.path.splitext(name)[1].lower()
            if ext not in SUPPORTED:
                continue
            rel = os.path.relpath(path, directory).replace('\\', '/')
            try:
                if ext in ('.db', '.sqlite', '.sqlite3'):
                    for t in _sqlite_tables(path):
                        found.append({'file': rel, **t, 'target': _guess_target(t['table'], name)})
                elif ext == '.json' and _json_tables(path):
                    for t in _json_tables(path):
                        found.append({'file': rel, **t, 'target': _guess_target(t['table'], name)})
                else:
                    rows = _read_rows(path)
                    cols = list(rows[0].keys()) if rows else []
                    if _pick(cols, LAT) and _pick(cols, LON):
                        found.append({'file': rel, 'table': None, 'rows': len(rows),
                                      'columns': cols, 'target': _guess_target('', name)})
            except Exception as e:  # unreadable file: show it with the error
                found.append({'file': rel, 'table': None, 'rows': 0, 'columns': [],
                              'target': 'spots', 'error': str(e)})
    return found


def import_file(db_path, path, table=None, into=None, status='approved',
                source='import', dry_run=False):
    """Imports one file/table. Duplicates (same name within ~10 m) are skipped.
    Returns counts and a preview of the first rows."""
    rows = _read_rows(path, table)
    into = into or _guess_target(table or '', path)
    cols = list(rows[0].keys()) if rows else []
    c = {k: _pick(cols, v) for k, v in
         {'name': NAME, 'lat': LAT, 'lon': LON, 'phone': PHONE, 'info': INFO,
          'icon': ICON, 'image': IMAGE}.items()}
    result = {'file': os.path.basename(path), 'table': table, 'into': into, 'rows': len(rows),
              'mapping': c, 'inserted': 0, 'duplicates': 0, 'invalid': 0, 'preview': []}
    if not (c['lat'] and c['lon']):
        result['error'] = 'latitude/longitude columns not found'
        return result

    def text(row, key):
        col = c[key]
        v = row.get(col) if col else None
        return '' if v is None else str(v).strip()

    clean = []
    for r in rows:
        try:
            lat, lon = float(r[c['lat']]), float(r[c['lon']])
        except (TypeError, ValueError):
            result['invalid'] += 1
            continue
        if not (-90 <= lat <= 90 and -180 <= lon <= 180) or (lat == 0 and lon == 0):
            result['invalid'] += 1
            continue
        info = clean_info(text(r, 'info'))
        phone = re.sub(r'[\s.-]', '', text(r, 'phone'))
        if not phone and into == 'shops':
            phone = extract_phone(info)
        clean.append({'name': text(r, 'name') or ('Magasin' if into == 'shops' else 'Spot'),
                      'lat': lat, 'lon': lon, 'info': info[:500], 'phone': phone,
                      'icon': text(r, 'icon')[:30], 'image': text(r, 'image')[:300]})
    result['preview'] = clean[:5]
    if dry_run:
        result['valid'] = len(clean)
        return result

    now = int(time.time())
    con = sqlite3.connect(db_path)
    try:
        for s in clean:
            dup = con.execute(
                f'SELECT 1 FROM {into} WHERE name = ? AND abs(lat - ?) < 0.0001 AND abs(lon - ?) < 0.0001 LIMIT 1',
                (s['name'], s['lat'], s['lon'])).fetchone()
            if dup:
                result['duplicates'] += 1
                continue
            if into == 'spots':
                con.execute(
                    'INSERT INTO spots(name, lat, lon, description, icon, image_url, status, source, created_at) '
                    'VALUES (?,?,?,?,?,?,?,?,?)',
                    (s['name'], s['lat'], s['lon'], s['info'], s['icon'], s['image'], status, source, now))
            else:
                con.execute(
                    'INSERT INTO shops(name, lat, lon, phone, description, icon, image_url, gold, status, source, created_at) '
                    'VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                    (s['name'], s['lat'], s['lon'], s['phone'], s['info'], s['icon'], s['image'],
                     1 if s['icon'] in ('shop3', 'gold') else 0, status, source, now))
            result['inserted'] += 1
        con.commit()
    finally:
        con.close()
    return result
