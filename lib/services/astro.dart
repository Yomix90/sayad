import 'dart:math';

import 'package:adhan/adhan.dart';

import 'forecast_service.dart';

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  full,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class MoonInfo {
  MoonInfo(this.age, this.illumination, this.phase);

  /// Days since the last new moon (0–29.5).
  final double age;

  /// Lit fraction of the disc (0–1).
  final double illumination;
  final MoonPhase phase;
}

const _synodicMonth = 29.530588853;

MoonInfo moonInfo(DateTime date) {
  // Reference new moon: 2000-01-06 18:14 UTC.
  final ref = DateTime.utc(2000, 1, 6, 18, 14);
  final days = date.toUtc().difference(ref).inMinutes / 1440.0;
  final age = days % _synodicMonth;
  final illumination = (1 - cos(2 * pi * age / _synodicMonth)) / 2;
  final index = ((age / _synodicMonth) * 8 + 0.5).floor() % 8;
  return MoonInfo(age, illumination, MoonPhase.values[index]);
}

/// Prayer times with the angles used in Morocco (Fajr 19°, Isha 17°).
PrayerTimes prayerTimes(double lat, double lon, [DateTime? day]) {
  final params = CalculationMethod.muslim_world_league.getParameters()
    ..fajrAngle = 19
    ..ishaAngle = 17
    ..madhab = Madhab.shafi;
  return PrayerTimes(
    Coordinates(lat, lon),
    DateComponents.from(day ?? DateTime.now()),
    params,
  );
}

double qiblaDirection(double lat, double lon) =>
    Qibla(Coordinates(lat, lon)).direction;

/// Fishing index from 0 to 10.
///
/// A simple heuristic: new/full moon, falling or stable pressure, moderate
/// wind, calm sea and dawn/dusk all improve the score.
double fishingIndex(Forecast f, MoonInfo moon, PrayerTimes sun, DateTime now) {
  var score = 5.0;

  // Moon: best close to new or full moon.
  final distToNewOrFull =
      min((moon.age - _synodicMonth / 2).abs(), min(moon.age, _synodicMonth - moon.age));
  score += 1.5 * (1 - distToNewOrFull / (_synodicMonth / 4));

  // Pressure: slowly falling is good, sharply rising is bad.
  final trend = f.pressureTrend;
  if (trend < -0.5 && trend > -3) score += 1;
  if (trend > 2) score -= 1;

  // Wind.
  if (f.windSpeed < 5) score += 0.3;
  if (f.windSpeed >= 5 && f.windSpeed <= 20) score += 1;
  if (f.windSpeed > 30) score -= 2;

  // Sea state.
  final waves = f.waveHeight;
  if (waves != null) {
    if (waves > 0.3 && waves < 1.5) score += 0.5;
    if (waves > 2.5) score -= 2;
  }

  // Dawn and dusk.
  bool near(DateTime t) => now.difference(t).inMinutes.abs() < 90;
  if (near(sun.sunrise) || near(sun.maghrib)) score += 1;

  return score.clamp(0, 10).toDouble();
}

class SolunarPeriod {
  SolunarPeriod(this.start, this.end, this.major);
  final DateTime start;
  final DateTime end;
  final bool major;
}

/// Approximate solunar periods for [day].
///
/// Moon transit is estimated from solar noon plus the moon's age (the moon
/// crosses the meridian ~50 min later each day). Major periods are 2 h around
/// moon overhead/underfoot, minor periods 1 h around moonrise/moonset.
List<SolunarPeriod> solunarPeriods(double lat, double lon, DateTime day) {
  final noon = prayerTimes(lat, lon, day).dhuhr;
  final age = moonInfo(noon).age;
  final transit =
      noon.add(Duration(minutes: (age / _synodicMonth * 24 * 60).round()));
  const halfDay = Duration(hours: 12, minutes: 25);
  const quarterDay = Duration(hours: 6, minutes: 12);
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final periods = <SolunarPeriod>[];
  for (final shift in [-2, -1, 0, 1]) {
    final over = transit.add(halfDay * shift);
    periods.add(SolunarPeriod(over.subtract(const Duration(hours: 1)),
        over.add(const Duration(hours: 1)), true));
    for (final m in [over.subtract(quarterDay), over.add(quarterDay)]) {
      periods.add(SolunarPeriod(m.subtract(const Duration(minutes: 30)),
          m.add(const Duration(minutes: 30)), false));
    }
  }
  final seen = <int>{};
  return periods
      .where((p) => !p.start.isBefore(dayStart) && p.start.isBefore(dayEnd))
      .where((p) => seen.add(p.start.millisecondsSinceEpoch ~/ 600000))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// Day rating from 1 to 4 based on the moon (best around new and full moon)
/// and on a major period overlapping sunrise or sunset.
int solunarDayRating(double lat, double lon, DateTime day) {
  final sun = prayerTimes(lat, lon, day);
  final age = moonInfo(sun.dhuhr).age;
  final dist =
      min((age - _synodicMonth / 2).abs(), min(age, _synodicMonth - age));
  var rating = dist < 1.5
      ? 3
      : dist < 4
          ? 2
          : 1;
  bool overlaps(SolunarPeriod p, DateTime t) =>
      p.major &&
      t.isAfter(p.start.subtract(const Duration(hours: 1))) &&
      t.isBefore(p.end.add(const Duration(hours: 1)));
  if (solunarPeriods(lat, lon, day)
      .any((p) => overlaps(p, sun.sunrise) || overlaps(p, sun.maghrib))) {
    rating++;
  }
  return rating.clamp(1, 4);
}

/// Approximate moon transit (moon highest in the sky) for [day].
DateTime moonTransit(double lat, double lon, DateTime day) {
  final noon = prayerTimes(lat, lon, day).dhuhr;
  final age = moonInfo(noon).age;
  return noon.add(Duration(minutes: (age / _synodicMonth * 24 * 60).round()));
}

/// Approximate moonrise and moonset around [day]'s transit (±6 h 12 min).
(DateTime rise, DateTime set) moonRiseSet(double lat, double lon, DateTime day) {
  final transit = moonTransit(lat, lon, day);
  const quarterDay = Duration(hours: 6, minutes: 12);
  return (transit.subtract(quarterDay), transit.add(quarterDay));
}
