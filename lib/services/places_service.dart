import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;

enum PlaceType { shop, port, marina, slipway }

class Place {
  Place(this.type, this.position, this.name);

  final PlaceType type;
  final LatLng position;
  final String? name;
}

/// Fishing shops, ports, marinas and slipways from OpenStreetMap (Overpass).
class PlacesService {
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  Future<List<Place>> around(LatLng center, {int radiusM = 30000}) async {
    final a = '(around:$radiusM,${center.latitude},${center.longitude})';
    final query = '[out:json][timeout:25];('
        'nwr["shop"~"^(fishing|hunting|outdoor)\$"]$a;'
        'nwr["harbour"]$a;'
        'nwr["landuse"="harbour"]$a;'
        'nwr["leisure"~"^(marina|slipway)\$"]$a;'
        ');out center tags 300;';

    Object? lastError;
    for (final url in _endpoints) {
      try {
        final res = await http
            .get(Uri.parse(url).replace(queryParameters: {'data': query}),
                // Overpass rejects requests without an identifying agent.
                headers: {'User-Agent': 'Sayad/0.1 (com.sayad.sayad)'})
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) {
          lastError = 'HTTP ${res.statusCode}';
          continue;
        }
        return _parse(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Overpass unavailable: $lastError');
  }

  List<Place> _parse(Map<String, dynamic> json) {
    final places = <Place>[];
    for (final e in (json['elements'] as List).cast<Map<String, dynamic>>()) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
      final c = (e['center'] as Map?) ?? e;
      final lat = (c['lat'] as num?)?.toDouble();
      final lon = (c['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final type = tags.containsKey('shop')
          ? PlaceType.shop
          : tags['leisure'] == 'marina'
              ? PlaceType.marina
              : tags['leisure'] == 'slipway'
                  ? PlaceType.slipway
                  : PlaceType.port;
      places.add(Place(type, LatLng(lat, lon), tags['name'] as String?));
    }
    return places;
  }
}
