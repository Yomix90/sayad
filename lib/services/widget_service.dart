import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../l10n/app_localizations.dart';
import '../widgets/common.dart' show compassPoint;
import 'forecast_service.dart';
import 'tide_service.dart';

/// Writes today's summary for the Android home-screen widget
/// (android/.../SayadWidgetProvider.kt) and asks it to redraw.
Future<void> updateHomeWidget({
  required AppLocalizations t,
  required String locale,
  required String place,
  required Forecast forecast,
  required int score,
  required String scoreLabel,
  required double lat,
  required double lon,
}) async {
  try {
    final hm = DateFormat.Hm(locale);
    final now = DateTime.now();
    String tide = '–';
    try {
      final data = await TideService().load(lat, lon, forecast);
      final next = data.extremes.where((e) => e.time.isAfter(now)).firstOrNull;
      if (next != null) {
        tide = '${next.isHigh ? t.highTide : t.lowTide} ${hm.format(next.time)}';
      }
    } catch (_) {}
    final values = <String, String>{
      'place': place,
      'index': '$score',
      'indexLabel': scoreLabel,
      'wind': '${t.wind} ${forecast.windSpeed.round()} ${t.kmh} ${compassPoint(forecast.windDirection)}',
      'waves': forecast.waveHeight == null
          ? ''
          : '${t.swell} ${forecast.waveHeight!.toStringAsFixed(1)} m'
              '${forecast.wavePeriod == null ? '' : ' · ${forecast.wavePeriod!.round()} s'}',
      'tide': tide,
      'updated': hm.format(now),
    };
    for (final e in values.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(androidName: 'SayadWidgetProvider');
  } catch (_) {
    // No widget support (tests, iOS without extension): nothing to update.
  }
}
