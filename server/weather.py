"""Shared cache of Open-Meteo weather grids for the app's weather map.

The app asks this server instead of Open-Meteo: each grid is fetched once
for every user, kept for an hour, and still served (up to 12 hours old)
when Open-Meteo is down or refuses too many requests.
"""
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import Response

FRESH = 3600          # seconds a grid is reused as is
STALE = 12 * 3600     # oldest grid served when Open-Meteo fails
MAX_POINTS = 200
MAX_ENTRIES = 400

HOURLY = {
    'wind_speed_10m', 'wind_direction_10m', 'wind_gusts_10m', 'temperature_2m',
    'precipitation', 'pressure_msl', 'wave_height', 'wave_direction',
}
MARINE = {'wave_height', 'wave_direction'}

_cache: 'OrderedDict[str, tuple[float, bytes]]' = OrderedDict()
_lock = threading.Lock()


def _coords(text: str) -> list:
    try:
        values = [round(float(v), 3) for v in text.split(',')]
    except ValueError:
        raise HTTPException(422, 'Invalid coordinates')
    if not values or len(values) > MAX_POINTS:
        raise HTTPException(422, f'1 to {MAX_POINTS} points')
    return values


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={'User-Agent': 'SayadServer/1.0'})
    with urllib.request.urlopen(req, timeout=40) as res:
        return res.read()


def create_router() -> APIRouter:
    router = APIRouter()

    @router.get('/weather/grid')
    def grid(request: Request, latitude: str = Query(...), longitude: str = Query(...),
             hourly: str = Query(...), forecast_days: int = Query(3, ge=1, le=7)):
        lats, lons = _coords(latitude), _coords(longitude)
        if len(lats) != len(lons):
            raise HTTPException(422, 'latitude and longitude lengths differ')
        fields = hourly.split(',')
        if not fields or not set(fields) <= HOURLY:
            raise HTTPException(422, 'Unknown hourly variable')
        marine = bool(set(fields) & MARINE)
        if marine and not set(fields) <= MARINE:
            raise HTTPException(422, 'Do not mix marine and weather variables')
        params = {
            'latitude': ','.join(f'{v:.3f}' for v in lats),
            'longitude': ','.join(f'{v:.3f}' for v in lons),
            'hourly': ','.join(fields),
            'forecast_days': str(forecast_days),
            'timezone': 'GMT',
        }
        if marine:
            params['cell_selection'] = 'nearest'
        else:
            params['wind_speed_unit'] = 'kmh'
        host = 'https://marine-api.open-meteo.com/v1/marine' if marine \
            else 'https://api.open-meteo.com/v1/forecast'
        url = host + '?' + urllib.parse.urlencode(params, safe=',')

        now = time.time()
        with _lock:
            hit = _cache.get(url)
        if hit and now - hit[0] < FRESH:
            return Response(hit[1], media_type='application/json', headers={'X-Cache': 'hit'})
        try:
            body = fetch(url)
        except (urllib.error.URLError, TimeoutError, OSError):
            if hit and now - hit[0] < STALE:
                return Response(hit[1], media_type='application/json', headers={'X-Cache': 'stale'})
            raise HTTPException(503, 'Weather source unavailable')
        with _lock:
            _cache[url] = (now, body)
            _cache.move_to_end(url)
            while len(_cache) > MAX_ENTRIES:
                _cache.popitem(last=False)
        return Response(body, media_type='application/json', headers={'X-Cache': 'miss'})

    return router
