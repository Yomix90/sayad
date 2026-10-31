import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/regions.dart';
import '../theme.dart';

class Spot {
  Spot(this.name, this.position);

  final String name;
  final LatLng position;

  Map<String, dynamic> toJson() =>
      {'name': name, 'lat': position.latitude, 'lon': position.longitude};

  factory Spot.fromJson(Map<String, dynamic> j) => Spot(
      j['name'] as String,
      LatLng((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble()));
}

/// One logged catch, with the conditions at the time it was saved.
class Catch {
  Catch({
    required this.speciesId,
    required this.speciesName,
    required this.time,
    required this.position,
    this.weightKg,
    this.lengthCm,
    this.note = '',
    this.windSpeed,
    this.waveHeight,
    this.pressure,
    this.moonAge,
  });

  final String? speciesId;
  final String speciesName;
  final DateTime time;
  final LatLng position;
  final double? weightKg;
  final double? lengthCm;
  final String note;
  final double? windSpeed;
  final double? waveHeight;
  final double? pressure;
  final double? moonAge;

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'speciesName': speciesName,
        'time': time.toIso8601String(),
        'lat': position.latitude,
        'lon': position.longitude,
        'weightKg': weightKg,
        'lengthCm': lengthCm,
        'note': note,
        'windSpeed': windSpeed,
        'waveHeight': waveHeight,
        'pressure': pressure,
        'moonAge': moonAge,
      };

  factory Catch.fromJson(Map<String, dynamic> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    return Catch(
      speciesId: j['speciesId'] as String?,
      speciesName: j['speciesName'] as String,
      time: DateTime.parse(j['time'] as String),
      position: LatLng(d('lat')!, d('lon')!),
      weightKg: d('weightKg'),
      lengthCm: d('lengthCm'),
      note: (j['note'] as String?) ?? '',
      windSpeed: d('windSpeed'),
      waveHeight: d('waveHeight'),
      pressure: d('pressure'),
      moonAge: d('moonAge'),
    );
  }
}

/// App-wide state: language, current position and saved spots.
class AppState extends ChangeNotifier {
  static const defaultPosition = LatLng(33.5731, -7.5898); // Casablanca

  static const languages = ['ar', 'fr', 'en'];

  Locale? locale;
  AppStyle style = AppStyle.modern;
  bool onboarded = false;
  String regionId = 'casablanca';

  /// Days added to the computed Hijri date (Morocco follows moon sighting).
  int hijriOffset = -1;
  LatLng position = defaultPosition;
  bool locationDenied = false;

  /// True when [position] comes from GPS rather than the chosen region.
  bool usingGps = false;

  Region get region => regionById(regionId);
  List<Spot> spots = [];
  List<Catch> catches = [];

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final code = _prefs.getString('locale');
    locale = code == null ? null : Locale(code);
    style = _prefs.getString('style') == 'classic' ? AppStyle.classic : AppStyle.modern;
    onboarded = _prefs.getBool('onboarded') ?? false;
    regionId = _prefs.getString('region') ?? regionId;
    hijriOffset = _prefs.getInt('hijriOffset') ?? hijriOffset;
    position = region.position;
    final raw = _prefs.getString('spots');
    if (raw != null) {
      spots = (jsonDecode(raw) as List)
          .map((e) => Spot.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final rawCatches = _prefs.getString('catches');
    if (rawCatches != null) {
      catches = (jsonDecode(rawCatches) as List)
          .map((e) => Catch.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> addCatch(Catch c) async {
    catches = [c, ...catches]..sort((a, b) => b.time.compareTo(a.time));
    await _saveCatches();
  }

  Future<void> removeCatch(Catch c) async {
    catches = catches.where((x) => x != c).toList();
    await _saveCatches();
  }

  Future<void> _saveCatches() async {
    await _prefs.setString(
        'catches', jsonEncode(catches.map((c) => c.toJson()).toList()));
    notifyListeners();
  }

  Future<void> setLocale(Locale? value) async {
    locale = value;
    if (value == null) {
      await _prefs.remove('locale');
    } else {
      await _prefs.setString('locale', value.languageCode);
    }
    notifyListeners();
  }

  Future<void> setHijriOffset(int value) async {
    hijriOffset = value;
    await _prefs.setInt('hijriOffset', value);
    notifyListeners();
  }

  Future<void> setStyle(AppStyle value) async {
    style = value;
    await _prefs.setString('style', value.name);
    notifyListeners();
  }

  Future<void> setRegion(String id) async {
    regionId = id;
    await _prefs.setString('region', id);
    if (!usingGps) position = region.position;
    notifyListeners();
  }

  /// Uses the chosen region instead of GPS.
  void useRegion() {
    usingGps = false;
    position = region.position;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await _prefs.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        locationDenied = true;
      } else {
        final p = await Geolocator.getCurrentPosition();
        position = LatLng(p.latitude, p.longitude);
        locationDenied = false;
        usingGps = true;
      }
    } catch (_) {
      locationDenied = true;
    }
    if (!usingGps) position = region.position;
    notifyListeners();
  }

  Future<void> addSpot(Spot spot) async {
    spots = [...spots, spot];
    await _saveSpots();
  }

  Future<void> removeSpot(Spot spot) async {
    spots = spots.where((s) => s != spot).toList();
    await _saveSpots();
  }

  Future<void> _saveSpots() async {
    await _prefs.setString(
        'spots', jsonEncode(spots.map((s) => s.toJson()).toList()));
    notifyListeners();
  }
}

/// Gives the widget tree access to [AppState].
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
