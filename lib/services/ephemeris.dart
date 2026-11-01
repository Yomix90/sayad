import 'dart:math';

/// Low-precision Sun and Moon ephemeris (after Meeus, "Astronomical
/// Algorithms", main terms only): about 0.01° for the Sun, 0.1–0.3° for the
/// Moon, enough for rise/set times to a few minutes and for tide strength.

const _deg = pi / 180;

double _norm(double a) => (a % 360 + 360) % 360;

/// Julian day of a UTC instant.
double julianDay(DateTime t) =>
    t.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

class SkyBody {
  SkyBody(this.longitude, this.latitude, this.distanceKm, this.ra, this.dec);

  /// Ecliptic longitude / latitude (degrees).
  final double longitude, latitude;
  final double distanceKm;

  /// Right ascension / declination (degrees).
  final double ra, dec;
}

double _obliquity(double t) => 23.439291 - 0.0130042 * t;

(double, double) _toEquatorial(double lon, double lat, double eps) {
  final l = lon * _deg, b = lat * _deg, e = eps * _deg;
  final ra = atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l));
  final dec = asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l));
  return (_norm(ra / _deg), dec / _deg);
}

SkyBody sunAt(DateTime time) {
  final t = (julianDay(time) - 2451545.0) / 36525;
  final l0 = 280.46646 + 36000.76983 * t;
  final m = (357.52911 + 35999.05029 * t) * _deg;
  final c = (1.914602 - 0.004817 * t) * sin(m) + 0.019993 * sin(2 * m) + 0.000289 * sin(3 * m);
  final lon = _norm(l0 + c);
  const e = 0.016708634;
  final r = 1.000001018 * (1 - e * e) / (1 + e * cos(m + c * _deg));
  final (ra, dec) = _toEquatorial(lon, 0, _obliquity(t));
  return SkyBody(lon, 0, r * 149597870.7, ra, dec);
}

SkyBody moonAt(DateTime time) {
  final t = (julianDay(time) - 2451545.0) / 36525;
  final lp = 218.3164477 + 481267.88123421 * t;
  final d = (297.8501921 + 445267.1114034 * t) * _deg;
  final m = (357.5291092 + 35999.0502909 * t) * _deg;
  final mp = (134.9633964 + 477198.8675055 * t) * _deg;
  final f = (93.2720950 + 483202.0175233 * t) * _deg;

  final lon = lp +
      6.288774 * sin(mp) +
      1.274027 * sin(2 * d - mp) +
      0.658314 * sin(2 * d) +
      0.213618 * sin(2 * mp) -
      0.185116 * sin(m) -
      0.114332 * sin(2 * f) +
      0.058793 * sin(2 * d - 2 * mp) +
      0.057066 * sin(2 * d - m - mp) +
      0.053322 * sin(2 * d + mp) +
      0.045758 * sin(2 * d - m) -
      0.040923 * sin(m - mp) -
      0.034720 * sin(d) -
      0.030383 * sin(m + mp);
  final lat = 5.128122 * sin(f) +
      0.280602 * sin(mp + f) +
      0.277693 * sin(mp - f) +
      0.173237 * sin(2 * d - f) +
      0.055413 * sin(2 * d - mp + f) +
      0.046271 * sin(2 * d - mp - f);
  final dist = 385000.56 -
      20905.355 * cos(mp) -
      3699.111 * cos(2 * d - mp) -
      2955.968 * cos(2 * d) -
      569.925 * cos(2 * mp) +
      48.888 * cos(m) -
      3.149 * cos(2 * f) +
      246.158 * cos(2 * d - 2 * mp) -
      152.138 * cos(2 * d - m - mp) -
      170.733 * cos(2 * d + mp) -
      204.586 * cos(2 * d - m) -
      129.620 * cos(m - mp) +
      108.743 * cos(d) +
      104.755 * cos(m + mp);
  final (ra, dec) = _toEquatorial(_norm(lon), lat, _obliquity(t));
  return SkyBody(_norm(lon), lat, dist, ra, dec);
}

/// Altitude and azimuth (degrees, azimuth from north, clockwise) of a body
/// seen from [lat], [lon] at [time]. For the Moon, the altitude is
/// topocentric (corrected for parallax).
(double alt, double az) altAz(SkyBody b, double lat, double lon, DateTime time) {
  final jd = julianDay(time);
  final gmst = _norm(280.46061837 + 360.98564736629 * (jd - 2451545.0));
  final h = (gmst + lon - b.ra) * _deg;
  final phi = lat * _deg, dec = b.dec * _deg;
  var alt = asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(h)) / _deg;
  final az = _norm(atan2(-sin(h), tan(dec) * cos(phi) - sin(phi) * cos(h)) / _deg);
  if (b.distanceKm < 1e6) {
    // Horizontal parallax of the Moon (~0.95°).
    alt -= asin(6378.14 / b.distanceKm) / _deg * cos(alt * _deg);
  }
  return (alt, az);
}

/// Times in [day] (local) when the body crosses [horizon] degrees, rising
/// then setting; null when it does not happen that day.
(DateTime? rise, DateTime? set) riseSet(
    SkyBody Function(DateTime) body, double lat, double lon, DateTime day,
    {required double horizon}) {
  final start = DateTime(day.year, day.month, day.day);
  DateTime? rise, set;
  double alt(DateTime t) => altAz(body(t), lat, lon, t).$1 - horizon;
  var prevT = start;
  var prev = alt(start);
  for (var m = 10; m <= 24 * 60; m += 10) {
    final t = start.add(Duration(minutes: m));
    final a = alt(t);
    if (prev < 0 && a >= 0 && rise == null) {
      rise = prevT.add(Duration(seconds: (600 * (-prev / (a - prev))).round()));
    } else if (prev >= 0 && a < 0 && set == null) {
      set = prevT.add(Duration(seconds: (600 * (prev / (prev - a))).round()));
    }
    prevT = t;
    prev = a;
  }
  return (rise, set);
}

/// Sun rises/sets at −0.833° (refraction + radius); the Moon at +0.125°
/// once parallax is applied to its altitude.
(DateTime?, DateTime?) sunRiseSet(double lat, double lon, DateTime day) =>
    riseSet(sunAt, lat, lon, day, horizon: -0.833);

(DateTime?, DateTime?) moonRiseSetExact(double lat, double lon, DateTime day) =>
    riseSet(moonAt, lat, lon, day, horizon: 0.125);

/// Moon minus Sun ecliptic longitude: 0 new moon, 180 full moon.
double elongation(DateTime t) => _norm(moonAt(t).longitude - sunAt(t).longitude);

class Syzygy {
  Syzygy(this.time, this.full);
  final DateTime time;
  final bool full;
}

/// New and full moons between [from] and [to].
List<Syzygy> syzygies(DateTime from, DateTime to) {
  final out = <Syzygy>[];
  double phase(DateTime t, double target) {
    final e = elongation(t) - target;
    return (e + 540) % 360 - 180; // −180..180
  }

  for (final target in [0.0, 180.0]) {
    var t = from;
    var prev = phase(t, target);
    while (t.isBefore(to)) {
      final next = t.add(const Duration(hours: 6));
      final cur = phase(next, target);
      if (prev < 0 && cur >= 0 && cur - prev < 90) {
        var a = t, b = next;
        for (var i = 0; i < 30; i++) {
          final mid = a.add(Duration(milliseconds: b.difference(a).inMilliseconds ~/ 2));
          if (phase(mid, target) < 0) {
            a = mid;
          } else {
            b = mid;
          }
        }
        out.add(Syzygy(a, target == 180));
      }
      t = next;
      prev = cur;
    }
  }
  out.sort((a, b) => a.time.compareTo(b.time));
  return out;
}

/// Semidiurnal tide amplitude (relative units): Moon and Sun tidal forces
/// (∝ 1/r³, × cos² declination) combined with the angle between them. The
/// Sun/Moon ratio is the one observed on the Atlantic coast (S2/M2 ≈ 0.34)
/// rather than the theoretical 0.46. Spring tides lag the moon phase by
/// about 1.5 days, so the astronomy is taken 36 h earlier.
double tideForce(DateTime t) {
  final at = t.subtract(const Duration(hours: 36));
  final m = moonAt(at), s = sunAt(at);
  final fm = pow(384400 / m.distanceKm, 3) * pow(cos(m.dec * _deg), 2);
  final fs = 0.34 * pow(149597870.7 / s.distanceKm, 3) * pow(cos(s.dec * _deg), 2);
  final phase = 2 * (m.longitude - s.longitude) * _deg;
  return sqrt(fm * fm + fs * fs + 2 * fm * fs * cos(phase));
}

/// Tide coefficient on the usual 20–120 scale, proportional to the tidal
/// range (mean spring tide = 95), from the astronomy alone. Approximate.
int tideCoefficient(DateTime t) {
  // Mean spring-tide force of this model over 2020–2039.
  const meanSpring = _meanSpringForce;
  return (95 * tideForce(t) / meanSpring).round().clamp(20, 120);
}

const _meanSpringForce = 1.266;
