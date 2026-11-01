"""Import fishing places of the Moroccan coast from OpenStreetMap (Overpass).

Piers, breakwaters, groynes, beaches, capes, slipways, marinas, harbours and
fishing spots, with their real positions. Data © OpenStreetMap contributors,
ODbL licence: keep the attribution visible where the spots are shown.

Runs in a background thread (Overpass can take a minute per area); the
dashboard polls `status()`.
"""
import json
import sqlite3
import threading
import time
import urllib.parse
import urllib.request

ENDPOINTS = (
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
)
USER_AGENT = 'Sayad/1.1 (fishing spots import)'

# Boxes (south, west, north, east) following the coast from Saïdia to the
# Mauritanian border, kept narrow to spare the Overpass servers.
COAST_TILES = [
    (34.9, -4.0, 35.6, -1.9),    # Méditerranée est
    (35.0, -5.5, 35.95, -4.0),   # Méditerranée ouest
    (34.4, -6.8, 35.95, -5.5),   # Tanger - Larache
    (33.5, -8.0, 34.4, -6.5),    # Rabat - Casablanca
    (32.6, -9.3, 33.5, -7.9),    # El Jadida
    (31.5, -10.0, 32.6, -8.8),   # Safi - Essaouira
    (30.0, -10.0, 31.5, -9.3),   # Agadir
    (28.8, -11.2, 30.0, -9.4),   # Sidi Ifni
    (27.8, -13.2, 28.8, -10.8),  # Tan-Tan - Tarfaya
    (26.5, -14.0, 27.8, -12.4),  # Laâyoune
    (24.5, -15.4, 26.5, -13.8),  # Boujdour
    (22.5, -16.6, 24.5, -14.8),  # Dakhla
    (20.7, -17.3, 22.5, -16.0),  # Lagouira
]

KINDS = {
    'fishing': ('other', 'Spot de pêche', 'موقع صيد'),
    'pier': ('jetty', 'Jetée', 'رصيف'),
    'breakwater': ('jetty', 'Digue', 'حاجز الأمواج'),
    'groyne': ('jetty', 'Épi', 'حاجز'),
    'beach': ('beach', 'Plage', 'شاطئ'),
    'cape': ('rock', 'Cap', 'رأس'),
    'slipway': ('port', 'Cale de mise à l\'eau', 'منحدر القوارب'),
    'marina': ('port', 'Marina', 'مرسى'),
    'harbour': ('port', 'Port', 'ميناء'),
}

_QUERY = """[out:json][timeout:120];
(
  nwr["leisure"="fishing"]({b});
  nwr["man_made"~"^(pier|breakwater|groyne)$"]({b});
  nwr["leisure"~"^(slipway|marina)$"]({b});
  nwr["natural"~"^(beach|cape)$"]({b});
  nwr["harbour"]({b});
);
out center tags;"""

_state = {'running': False, 'done': 0, 'total': len(COAST_TILES), 'inserted': 0,
          'duplicates': 0, 'errors': [], 'by_kind': {}, 'finished_at': None}
_lock = threading.Lock()


def status():
    with _lock:
        return dict(_state, by_kind=dict(_state['by_kind']), errors=list(_state['errors']))


def fetch_tile(tile):
    """Overpass elements of one coast box (tries each endpoint)."""
    s, w, n, e = tile
    data = urllib.parse.urlencode({'data': _QUERY.replace('{b}', f'{s},{w},{n},{e}')})
    last = None
    for url in ENDPOINTS:
        for attempt in range(2):
            try:
                req = urllib.request.Request(f'{url}?{data}', headers={'User-Agent': USER_AGENT})
                with urllib.request.urlopen(req, timeout=180) as r:
                    return json.loads(r.read().decode('utf-8'))['elements']
            except Exception as ex:  # busy server: wait and retry, then next endpoint
                last = ex
                time.sleep(10 * (attempt + 1))
    raise RuntimeError(f'Overpass unavailable: {last}')


def classify(tags):
    """OSM tags -> key of KINDS, or None."""
    if tags.get('leisure') in ('fishing', 'slipway', 'marina'):
        return tags['leisure']
    if tags.get('man_made') in ('pier', 'breakwater', 'groyne'):
        return tags['man_made']
    if tags.get('natural') in ('beach', 'cape'):
        return tags['natural']
    if 'harbour' in tags:
        return 'harbour'
    return None


def to_spot(el):
    """(ext_id, name, lat, lon, kind, description) for an Overpass element."""
    tags = el.get('tags') or {}
    key = classify(tags)
    c = el.get('center') or el
    lat, lon = c.get('lat'), c.get('lon')
    if key is None or lat is None or lon is None:
        return None
    kind, fr, ar = KINDS[key]
    name = tags.get('name:fr') or tags.get('name') or tags.get('name:ar') or ''
    if not name:
        name = f'{ar} - {fr}'
    elif tags.get('name:ar') and tags['name:ar'] not in name:
        name = f"{tags['name:ar']} - {name}"
    return (f"osm:{el['type']}/{el['id']}", name[:120], float(lat), float(lon), kind,
            f'{fr} · Source : OpenStreetMap')


def save(db_path, spots, status_value):
    """Inserts new places; skips ones already imported (same OSM id) or with
    another spot of the same kind within ~50 m. Returns (inserted, dupes)."""
    inserted = dupes = 0
    now = int(time.time())
    con = sqlite3.connect(db_path)
    try:
        for ext, name, lat, lon, kind, desc in spots:
            if con.execute('SELECT 1 FROM spots WHERE ext_id = ? LIMIT 1', (ext,)).fetchone() or \
               con.execute('SELECT 1 FROM spots WHERE kind = ? AND abs(lat - ?) < 0.0005 '
                           'AND abs(lon - ?) < 0.0005 LIMIT 1', (kind, lat, lon)).fetchone():
                dupes += 1
                continue
            con.execute('INSERT INTO spots(name, lat, lon, kind, description, status, source, ext_id, created_at) '
                        'VALUES (?,?,?,?,?,?, "osm", ?, ?)',
                        (name, lat, lon, kind, desc, status_value, ext, now))
            inserted += 1
        con.commit()
    finally:
        con.close()
    return inserted, dupes


def run(db_path, status_value='pending', tiles=None, fetch=fetch_tile, pause=3.0):
    tiles = tiles or COAST_TILES
    with _lock:
        _state.update(running=True, done=0, total=len(tiles), inserted=0, duplicates=0,
                      errors=[], by_kind={}, finished_at=None)
    try:
        for tile in tiles:
            try:
                spots = [s for s in (to_spot(e) for e in fetch(tile)) if s]
                ins, dup = save(db_path, spots, status_value)
                with _lock:
                    _state['inserted'] += ins
                    _state['duplicates'] += dup
                    for s in spots:
                        _state['by_kind'][s[4]] = _state['by_kind'].get(s[4], 0) + 1
            except Exception as ex:
                with _lock:
                    _state['errors'].append(f'{tile}: {ex}')
            with _lock:
                _state['done'] += 1
            time.sleep(pause)
    finally:
        with _lock:
            _state['running'] = False
            _state['finished_at'] = int(time.time())


def start(db_path, status_value='pending'):
    """Starts the import in the background; False if one is already running."""
    with _lock:
        if _state['running']:
            return False
        _state['running'] = True
    threading.Thread(target=run, args=(db_path, status_value), daemon=True).start()
    return True
