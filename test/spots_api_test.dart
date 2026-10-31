import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:sayad/services/spots_api.dart';

void main() {
  setUp(() => SpotsApi.overrideBase = 'https://api.example');

  test('lists spots of a box and submits a new one', () async {
    final calls = <http.Request>[];
    final api = SpotsApi(
      client: MockClient((req) async {
        calls.add(req);
        if (req.method == 'GET') {
          return http.Response.bytes(
              utf8.encode(jsonEncode([
                {'id': 1, 'name': 'Jetée', 'lat': 33.7, 'lon': -7.39, 'kind': 'jetty', 'species': 'Bar'},
              ])),
              200);
        }
        return http.Response('{"id": 2, "status": "pending"}', 201);
      }),
    );
    final spots = await api.spots(const LatLng(33, -8), const LatLng(34, -7));
    expect(spots.single.name, 'Jetée');
    expect(spots.single.position, const LatLng(33.7, -7.39));
    expect(calls.first.url.path, '/spots');
    expect(calls.first.url.queryParameters['min_lat'], '33.0');

    await api.submitSpot('Nouveau', const LatLng(35, -5));
    expect(calls.last.method, 'POST');
    expect(jsonDecode(calls.last.body)['name'], 'Nouveau');
  });

  test('server errors are reported', () async {
    final api = SpotsApi(client: MockClient((_) async => http.Response('no', 500)));
    expect(() => api.spots(const LatLng(0, 0), const LatLng(1, 1)), throwsException);
  });
}
