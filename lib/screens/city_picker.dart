import 'package:flutter/material.dart';

import '../data/regions.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/line_icons.dart';

/// Opens the coastal town picker as a tall bottom sheet.
Future<void> showCityPicker(BuildContext context) {
  final p = Palette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: p.bg,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (c, controller) => CityPicker(
        scrollController: controller,
        onPicked: () => Navigator.of(c).pop(),
      ),
    ),
  );
}

/// GPS option plus every coastal town, grouped by coast, with a search box.
/// With no [scrollController] it is laid out inline (welcome flow).
class CityPicker extends StatefulWidget {
  const CityPicker({super.key, this.scrollController, this.onPicked});

  final ScrollController? scrollController;
  final VoidCallback? onPicked;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final state = AppScope.of(context);
    final q = normalizeSearch(_query);
    final matches = regions
        .where((r) =>
            q.isEmpty ||
            [r.name.ar, r.name.fr, r.name.en].any((n) => normalizeSearch(n).contains(q)))
        .toList();

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: t.searchCity,
            prefixIcon: Icon(Icons.search, color: p.muted),
            isDense: true,
          ),
        ),
      ),
      if (q.isEmpty)
        _Row(
          icon: LineIcon('cross', size: 20, color: p.accentInk),
          title: t.useGps,
          subtitle: t.useGpsSub,
          selected: state.usingGps,
          onTap: () {
            state.locate();
            widget.onPicked?.call();
          },
        ),
      for (final coast in Coast.values)
        if (matches.any((r) => r.coast == coast)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(_coastName(t, coast).toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: p.muted)),
          ),
          for (final r in matches.where((r) => r.coast == coast))
            _Row(
              icon: LineIcon('pin', size: 19, color: p.classic ? p.accent : p.accentInk),
              title: r.name.of(context),
              selected: !state.usingGps && state.regionId == r.id,
              onTap: () {
                state.setRegion(r.id);
                state.useRegion();
                widget.onPicked?.call();
              },
            ),
        ],
      if (matches.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.noCityFound,
              textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        ),
    ];

    if (widget.scrollController == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Text(t.chooseCity, style: p.title(19)),
      ),
      Expanded(
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: children,
        ),
      ),
    ]);
  }

  static String _coastName(AppLocalizations t, Coast c) => switch (c) {
        Coast.mediterranean => t.coastMediterranean,
        Coast.atlanticNorth => t.coastAtlanticNorth,
        Coast.atlanticCentre => t.coastAtlanticCentre,
        Coast.souss => t.coastSouss,
        Coast.sahara => t.coastSahara,
      };
}

/// Lower-case, without accents or Arabic vowel marks, for forgiving search.
String normalizeSearch(String s) {
  const from = 'àâäáéèêëîïíôöóûüùúçñأإآىة';
  const to = 'aaaaeeeeiiiooouuuucnاااىه';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    if (RegExp('[ً-ْ\'’\\- ]').hasMatch(ch)) continue;
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? p.surface2 : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(p.radiusS),
          side: BorderSide(color: selected ? p.accent : p.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(p.radiusS),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: p.text)),
                      if (subtitle != null)
                        Text(subtitle!, style: TextStyle(fontSize: 12.5, color: p.muted)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: p.accent, size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
