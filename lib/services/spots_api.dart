import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;

class ServerSpot {
  ServerSpot({
    required this.id,
    required this.name,
    required this.position,
    this.kind = 'other',
    this.species = '',
    this.phone = '',
    this.gold = false,
    this.description = '',
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final LatLng position;
  final String kind;
  final String species;
  final String phone;
  final bool gold;
  final String description;
  final String imageUrl;

  factory ServerSpot.fromJson(Map<String, dynamic> j) => ServerSpot(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String,
        position: LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()),
        kind: (j['kind'] as String?) ?? 'other',
        species: (j['species'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        gold: (j['gold'] as num? ?? 0) != 0,
        description: (j['description'] as String?) ?? '',
        imageUrl: (j['image_url'] as String?) ?? '',
      );

  /// Lines of the description, without the ones that only repeat the name
  /// or the phone number.
  List<String> get infoLines => [
        for (final l in description.split(RegExp(r'\s*(?://|\n)\s*')))
          if (l.isNotEmpty &&
              l != name &&
              l.replaceAll(RegExp(r'[\s.-]'), '') != phone)
            l
      ];

  /// International number for WhatsApp (Moroccan mobiles only).
  String? get whatsapp {
    final d = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final m = RegExp(r'^(?:\+212|00212|0)([67]\d{8})$').firstMatch(d);
    return m == null ? null : '212${m.group(1)}';
  }
}

/// Client of the Sayad spots server (see server/). Disabled unless the app
/// is built with `--dart-define=SAYAD_API=https://your-server`.
class SpotsApi {
  SpotsApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment('SAYAD_API');
  static bool get enabled => baseUrl.isNotEmpty;

  final http.Client _client;

  @visibleForTesting
  static String? overrideBase;

  static String get base => overrideBase ?? baseUrl;

  Future<List<ServerSpot>> _list(String path, LatLng sw, LatLng ne) async {
    final uri = Uri.parse('$base$path').replace(queryParameters: {
      'min_lat': '${sw.latitude}',
      'max_lat': '${ne.latitude}',
      'min_lon': '${sw.longitude}',
      'max_lon': '${ne.longitude}',
      'limit': '3000',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Spots server ${res.statusCode}');
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((e) => ServerSpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approved spots inside the box south-west [sw] / north-east [ne].
  Future<List<ServerSpot>> spots(LatLng sw, LatLng ne) => _list('/spots', sw, ne);

  Future<List<ServerSpot>> shops(LatLng sw, LatLng ne) => _list('/shops', sw, ne);

  /// Proposes a tackle shop; it appears once the admin approves it.
  Future<void> submitShop(String name, LatLng at, {String phone = '', String city = ''}) async {
    final res = await _client
        .post(Uri.parse('$base/shops'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'lat': at.latitude,
              'lon': at.longitude,
              'phone': phone,
              'city': city,
            }))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 201) throw Exception('Spots server ${res.statusCode}');
  }

  /// Proposes a spot to everyone; it appears once the admin approves it.
  Future<void> submitSpot(String name, LatLng at, {String kind = 'other'}) async {
    final res = await _client
        .post(Uri.parse('$base/spots'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'lat': at.latitude,
              'lon': at.longitude,
              'kind': kind,
            }))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 201) throw Exception('Spots server ${res.statusCode}');
  }
}
