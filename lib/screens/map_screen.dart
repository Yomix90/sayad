import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng, LengthUnit;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/places_service.dart';
import '../services/spots_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import '../widgets/sub_page.dart';
import 'home_screen.dart';
import 'target_screen.dart';

enum _Filter { all, community, mine, places }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  List<Place> _places = [];
  List<ServerSpot> _community = [];
  List<ServerSpot> _serverShops = [];
  bool _loadingCommunity = false;
  // Area already loaded from the spots server, to avoid reloading on pans.
  LatLngBounds? _loadedArea;
  bool _loadingPlaces = false;
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final showMine = _filter != _Filter.places;
    final showPlaces = _filter != _Filter.mine;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(children: [
        ScreenHead(
          title: t.tabMap,
          trailing: StatusChip(
              label: t.spotsCount(state.spots.length), dot: true, dotColor: p.ok),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(p.radius),
              border: Border.all(color: p.border),
              boxShadow: p.shadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              // Map gestures and tiles stay left-to-right in Arabic too.
              Directionality(
                textDirection: TextDirection.ltr,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: state.position,
                    initialZoom: 10,
                    onLongPress: (_, point) => _addSpot(point),
                    onMapEvent: (e) {
                      if (e is MapEventMoveEnd ||
                          e is MapEventFlingAnimationEnd ||
                          e is MapEventDoubleTapZoomEnd ||
                          e is MapEventScrollWheelZoom) {
                        _loadCommunity();
                      }
                    },
                    onMapReady: _loadCommunity,
                    onTap: (_, point) =>
                        _openSheet(point, title: t.selectedPoint, kind: t.pointKind),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sayad.sayad',
                    ),
                    TileLayer(
                      urlTemplate:
                          'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sayad.sayad',
                    ),
                    MarkerLayer(markers: [
                      if (_filter == _Filter.all || _filter == _Filter.community)
                        for (final s in _community)
                          _pin(s.position, p.classic ? p.primary : p.accent, 'fish',
                              () => _openSheet(s.position,
                                  title: s.name,
                                  kind: s.species.isEmpty
                                      ? t.communitySpot
                                      : '${t.communitySpot} · ${s.species}')),
                      if (showPlaces)
                        for (final s in _serverShops)
                          _pin(s.position, s.gold ? const Color(0xFFD4A017) : p.warn, 'store',
                              () => _openSheet(s.position,
                                  title: s.name,
                                  kind: s.phone.isEmpty
                                      ? t.fishingShop
                                      : '${t.fishingShop} · ${s.phone}')),
                      if (showPlaces)
                        for (final pl in _places)
                          _pin(pl.position, _placeColor(p, pl.type),
                              _placeIcon(pl.type),
                              () => _openSheet(pl.position,
                                  title: pl.name ?? _placeLabel(t, pl.type),
                                  kind: _placeLabel(t, pl.type))),
                      if (showMine)
                        for (final s in state.spots)
                          _pin(s.position, p.ok, 'star',
                              () => _openSheet(s.position,
                                  title: s.name, kind: t.mySpot, spot: s)),
                      Marker(
                        point: state.position,
                        width: 40,
                        height: 40,
                        child: _MeMarker(color: p.danger),
                      ),
                    ]),
                    const RichAttributionWidget(attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                      TextSourceAttribution('OpenSeaMap'),
                    ]),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 10,
                start: 10,
                end: 10,
                child: Center(
                  child: StatusChip(label: t.addSpotHint, icon: 'info'),
                ),
              ),
              PositionedDirectional(
                end: 12,
                bottom: 12,
                child: Material(
                  color: p.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: p.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await state.locate();
                      _controller.move(state.position, 12);
                    },
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Center(
                        child: LineIcon('cross',
                            size: 21, color: p.classic ? p.primary : p.accentInk),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _filterChip(_Filter.all, t.all, null),
            const SizedBox(width: 8),
            if (SpotsApi.enabled) ...[
              _filterChip(_Filter.community, t.communitySpots,
                  p.classic ? p.primary : p.accent,
                  loading: _loadingCommunity),
              const SizedBox(width: 8),
            ],
            _filterChip(_Filter.mine, t.mySpots, p.ok),
            const SizedBox(width: 8),
            _filterChip(_Filter.places, t.placesFilter, p.warn,
                loading: _loadingPlaces),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(_Filter f, String label, Color? dot, {bool loading = false}) {
    final sel = _filter == f;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = f);
        if (f != _Filter.mine && _places.isEmpty && !_loadingPlaces) _loadPlaces();
      },
      child: StatusChip(
        label: label,
        compact: false,
        tone: sel ? ChipTone.solid : ChipTone.neutral,
        dot: dot != null,
        dotColor: dot,
        icon: loading ? 'clock' : null,
      ),
    );
  }

  Marker _pin(LatLng at, Color color, String icon, VoidCallback onTap) => Marker(
        point: at,
        width: 34,
        height: 44,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: onTap,
          child: CustomPaint(
            painter: _PinPainter(color),
            child: Align(
              alignment: const Alignment(0, -0.42),
              child: LineIcon(icon, size: 13, color: Palette.of(context).primary),
            ),
          ),
        ),
      );

  Future<void> _loadPlaces() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingPlaces = true);
    try {
      final places = await PlacesService().around(_controller.camera.center);
      setState(() => _places = places);
      messenger.showSnackBar(SnackBar(content: Text(t.placesFound(places.length))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.placesError)));
    } finally {
      if (mounted) setState(() => _loadingPlaces = false);
    }
  }

  void _openSheet(LatLng point,
      {required String title, required String kind, Spot? spot}) {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final p = Palette.of(context);
    final km = const Distance().as(LengthUnit.Meter, state.position, point) / 1000;
    final kmText = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: p.title(19)),
                const SizedBox(height: 8),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  StatusChip(label: kind),
                  if (spot != null)
                    StatusChip(label: t.saved, tone: ChipTone.ok, icon: 'check'),
                ]),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(p.radiusS),
                  ),
                  child: Row(children: [
                    Expanded(child: _kv(t.direct, '$kmText km')),
                    Expanded(
                      flex: 2,
                      child: _kv(t.coords, formatCoords(point.latitude, point.longitude),
                          small: true),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: IconLabel(
                          icon: LineIcon('nav',
                              size: 19,
                              color: p.classic
                                  ? const Color(0xFFF3E9D2)
                                  : const Color(0xFF04222B)),
                          label: t.navigate),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: spot == null
                        ? OutlinedButton(
                            onPressed: () {
                              Navigator.pop(c);
                              _addSpot(point, suggested: title == t.selectedPoint ? '' : title);
                            },
                            child: IconLabel(
                                icon: LineIcon('bookmark', size: 19, color: p.text),
                                label: t.save),
                          )
                        : OutlinedButton(
                            onPressed: () {
                              state.removeSpot(spot);
                              Navigator.pop(c);
                            },
                            child: IconLabel(
                                icon: Icon(Icons.delete_outline, color: p.dangerInk),
                                label: t.delete),
                          ),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TargetScreen(name: title, target: point)));
                    },
                    child: IconLabel(
                        icon: LineIcon('compass', size: 19, color: p.text),
                        label: t.guideOffline),
                  ),
                ),
                if (SpotsApi.enabled && spot == null)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(c);
                        _proposeShop(point);
                      },
                      icon: LineIcon('store', size: 18, color: p.accentInk),
                      label: Text(t.proposeShop,
                          style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w700)),
                    ),
                  ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SubPage(
                          title: title,
                          body: ForecastView(position: point),
                        ),
                      ));
                    },
                    icon: LineIcon('cloud', size: 18, color: p.accentInk),
                    label: Text(t.forecastHere,
                        style: TextStyle(
                            color: p.accentInk, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {bool small = false}) {
    final p = Palette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: p.muted)),
      Text(v, style: p.num(small ? 13.5 : 17)),
    ]);
  }

  /// Loads community spots and shops for the visible area (zoom 7+).
  Future<void> _loadCommunity() async {
    if (!SpotsApi.enabled || _loadingCommunity) return;
    final cam = _controller.camera;
    if (cam.zoom < 7) return;
    final visible = cam.visibleBounds;
    if (_loadedArea != null &&
        _loadedArea!.contains(visible.southWest) &&
        _loadedArea!.contains(visible.northEast)) {
      return;
    }
    // Load a margin around the view so small pans need no new request.
    final dLat = (visible.north - visible.south) / 2;
    final dLon = (visible.east - visible.west) / 2;
    final area = LatLngBounds(LatLng(visible.south - dLat, visible.west - dLon),
        LatLng(visible.north + dLat, visible.east + dLon));
    setState(() => _loadingCommunity = true);
    try {
      final api = SpotsApi();
      final results = await Future.wait(
          [api.spots(area.southWest, area.northEast), api.shops(area.southWest, area.northEast)]);
      if (!mounted) return;
      setState(() {
        _community = results[0];
        _serverShops = results[1];
        _loadedArea = area;
      });
    } catch (_) {
      // Offline or server down: keep what is shown.
    } finally {
      if (mounted) setState(() => _loadingCommunity = false);
    }
  }

  Future<void> _proposeShop(LatLng point) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = TextEditingController(), phone = TextEditingController(), city = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.proposeShop),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: t.shopName)),
          const SizedBox(height: 10),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.phone)),
          const SizedBox(height: 10),
          TextField(controller: city, decoration: InputDecoration(labelText: t.city)),
          const SizedBox(height: 8),
          Text(t.shareSpotSub, style: const TextStyle(fontSize: 12.5)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.send)),
        ],
      ),
    );
    if (ok != true || name.text.trim().length < 2) return;
    try {
      await SpotsApi().submitShop(name.text.trim(), point,
          phone: phone.text.trim(), city: city.text.trim());
      messenger.showSnackBar(SnackBar(content: Text(t.spotShared)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.spotShareFailed)));
    }
  }

  Future<void> _addSpot(LatLng point, {String suggested = ''}) async {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController(text: suggested);
    var share = false;
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.addSpot),
        content: StatefulBuilder(
          builder: (c, setDialog) => Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(labelText: t.spotName),
              onSubmitted: (v) => Navigator.pop(c, v),
            ),
            if (SpotsApi.enabled)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: share,
                onChanged: (v) => setDialog(() => share = v ?? false),
                title: Text(t.shareSpot),
                subtitle: Text(t.shareSpotSub),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text), child: Text(t.save)),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await state.addSpot(Spot(name.trim(), point));
      messenger.showSnackBar(SnackBar(content: Text(t.spotSaved)));
      if (share) {
        try {
          await SpotsApi().submitSpot(name.trim(), point);
          messenger.showSnackBar(SnackBar(content: Text(t.spotShared)));
        } catch (_) {
          messenger.showSnackBar(SnackBar(content: Text(t.spotShareFailed)));
        }
      }
    }
  }

  static String _placeIcon(PlaceType type) => switch (type) {
        PlaceType.shop => 'store',
        _ => 'anchor',
      };

  static Color _placeColor(Palette p, PlaceType type) => switch (type) {
        PlaceType.shop => p.warn,
        _ => p.classic ? p.primary : p.accent,
      };

  static String _placeLabel(AppLocalizations t, PlaceType type) =>
      switch (type) {
        PlaceType.shop => t.fishingShop,
        PlaceType.port => t.port,
        PlaceType.marina => t.marina,
        PlaceType.slipway => t.slipway,
      };
}

/// Teardrop pin with a white disc for the glyph.
class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = size.width * 0.36;
    final cy = r + 2;
    final body = Path()
      ..moveTo(cx, size.height - 2)
      ..cubicTo(cx - r * 0.75, cy + r * 1.1, cx - r, cy + r * 0.6, cx - r, cy)
      ..arcToPoint(Offset(cx + r, cy), radius: Radius.circular(r))
      ..cubicTo(cx + r, cy + r * 0.6, cx + r * 0.75, cy + r * 1.1, cx, size.height - 2)
      ..close();
    canvas.drawShadow(body, Colors.black, 2, false);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
        body,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.72,
        Paint()..color = Colors.white.withValues(alpha: 0.94));
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

/// Red dot with an expanding ring.
class _MeMarker extends StatefulWidget {
  const _MeMarker({required this.color});
  final Color color;

  @override
  State<_MeMarker> createState() => _MeMarkerState();
}

class _MeMarkerState extends State<_MeMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(alignment: Alignment.center, children: [
        Container(
          width: 13 * 2 * (0.4 + 0.85 * _c.value),
          height: 13 * 2 * (0.4 + 0.85 * _c.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: widget.color.withValues(alpha: 0.8 * (1 - _c.value)),
                width: 2),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ]),
    );
  }
}
