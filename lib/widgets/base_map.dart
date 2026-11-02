import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Base map tiles, all free without a key: 'standard' (OpenStreetMap),
/// 'satellite' (Esri World Imagery) or 'night' (Esri Dark Gray).
Widget baseLayer(String layer) => switch (layer) {
      'satellite' => TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.sayad.sayad',
          maxNativeZoom: 18,
        ),
      'night' => TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.sayad.sayad',
          maxNativeZoom: 16,
        ),
      _ => TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sayad.sayad',
        ),
    };

/// Town and road names drawn over the night map.
Widget? labelsLayer(String layer) => layer == 'night'
    ? TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.sayad.sayad',
        maxNativeZoom: 16,
      )
    : null;

List<SourceAttribution> baseAttributions(String layer) => switch (layer) {
      'satellite' => const [
          TextSourceAttribution('Esri, Maxar, Earthstar Geographics'),
        ],
      'night' => const [
          TextSourceAttribution('Esri, HERE, Garmin'),
          TextSourceAttribution('OpenStreetMap contributors'),
        ],
      _ => const [TextSourceAttribution('OpenStreetMap contributors')],
    };
