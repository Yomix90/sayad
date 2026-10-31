import 'dart:math';

/// Correction of Stormglass (global TPXO model) towards the port's own tide
/// table: time shift, then height = scale × Stormglass + offset (also moves
/// heights onto the local chart datum used by tide tables).
class TideCorrection {
  const TideCorrection({
    required this.port,
    required this.lat,
    required this.lon,
    required this.minutes,
    required this.scale,
    required this.offset,
  });

  final String port;
  final double lat, lon;
  final int minutes;
  final double scale, offset;
}

/// Fitted on a day of the local tide table, then checked on the next two
/// days (error 4–19 min, ±0.08 m at Casablanca vs 70 min uncorrected).
const tideCorrections = [
  TideCorrection(
      port: 'Casablanca', lat: 33.60, lon: -7.62, minutes: 72, scale: 0.927, offset: 0.732),
];

/// Correction of the nearest calibrated port within 30 km, if any.
TideCorrection? correctionNear(double lat, double lon) {
  TideCorrection? best;
  var bestKm = 30.0;
  for (final c in tideCorrections) {
    final dLat = (c.lat - lat) * 111;
    final dLon = (c.lon - lon) * 111 * cos(lat * pi / 180);
    final km = sqrt(dLat * dLat + dLon * dLon);
    if (km < bestKm) {
      bestKm = km;
      best = c;
    }
  }
  return best;
}
