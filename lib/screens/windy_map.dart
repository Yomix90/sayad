import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Windy's public embedded map, centred on the current place. Windy's terms
/// require its logo to stay visible, so the map is shown whole.
class WindyMapView extends StatefulWidget {
  const WindyMapView({super.key});

  @override
  State<WindyMapView> createState() => _WindyMapViewState();
}

class _WindyMapViewState extends State<WindyMapView> {
  static const _layers = ['wind', 'gust', 'waves', 'rain', 'temp', 'pressure'];
  String _layer = 'wind';
  WebViewController? _web;
  bool _loading = true;

  Uri _url(double lat, double lon) => Uri.https('embed.windy.com', '/embed.html', {
        'type': 'map',
        'location': 'coordinates',
        'metricRain': 'mm',
        'metricTemp': '°C',
        'metricWind': 'km/h',
        'zoom': '7',
        'overlay': _layer,
        'product': 'ecmwf',
        'level': 'surface',
        'lat': '$lat',
        'lon': '$lon',
        'message': 'true',
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_web == null) {
      final pos = AppScope.of(context).position;
      _web = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ))
        ..loadRequest(_url(pos.latitude, pos.longitude));
    }
  }

  void _show(String layer) {
    final pos = AppScope.of(context).position;
    setState(() {
      _layer = layer;
      _loading = true;
    });
    _web!.loadRequest(_url(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final labels = {
      'wind': t.wind,
      'gust': t.gusts,
      'waves': t.waves,
      'rain': t.wxRain,
      'temp': t.temperature,
      'pressure': t.pressure,
    };
    return Column(children: [
      SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          children: [
            for (final l in _layers)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: StatusChip(
                  label: labels[l]!,
                  tone: l == _layer ? ChipTone.solid : ChipTone.neutral,
                  onTap: () => _show(l),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(p.radius),
            border: Border.all(color: p.border),
          ),
          child: Stack(children: [
            WebViewWidget(controller: _web!),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ]),
        ),
      ),
    ]);
  }
}
