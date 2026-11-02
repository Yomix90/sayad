import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Base map tiles: 'standard' (OpenStreetMap), 'satellite' (Esri World
/// Imagery) or 'night' (CARTO Dark Matter).
Widget baseLayer(String layer) => switch (layer) {
      'satellite' => TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.sayad.sayad',
          maxNativeZoom: 18,
        ),
      'night' => TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: true,
          userAgentPackageName: 'com.sayad.sayad',
        ),
      _ => TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sayad.sayad',
        ),
    };

List<SourceAttribution> baseAttributions(String layer) => switch (layer) {
      'satellite' => const [
          TextSourceAttribution('Esri, Maxar, Earthstar Geographics'),
        ],
      'night' => const [
          TextSourceAttribution('OpenStreetMap contributors'),
          TextSourceAttribution('CARTO'),
        ],
      _ => const [TextSourceAttribution('OpenStreetMap contributors')],
    };
