import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/species.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/astro.dart';
import '../services/forecast_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sub_page.dart';

class CatchLogScreen extends StatelessWidget {
  const CatchLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final state = AppScope.of(context);
    final locale = Localizations.localeOf(context).toString();
    final catches = state.catches;
    final heaviest = catches
        .where((c) => c.weightKg != null)
        .fold<Catch?>(null, (b, c) => b == null || c.weightKg! > b.weightKg! ? c : b);

    return SubPage(
      title: t.catchLog,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCatchScreen())),
        icon: const Icon(Icons.add),
        label: Text(t.addCatch),
      ),
      body: catches.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.set_meal, size: 64, color: p.border),
                  const SizedBox(height: 12),
                  Text(t.noCatches,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.muted)),
                ]),
              ),
            )
          : ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 96), children: [
              TileGrid(
                columns: 3,
                gap: 10,
                children: [
                  StatTile(icon: 'fish', label: t.totalCatches, value: '${catches.length}'),
                  StatTile(
                      icon: 'gauge',
                      label: t.biggestCatch,
                      value: heaviest == null ? '–' : heaviest.weightKg!.toStringAsFixed(1),
                      unit: heaviest == null ? null : 'kg'),
                  StatTile(icon: 'star', label: t.topSpecies, value: '${_topCount(catches)}',
                      sub: _topSpecies(context, catches)),
                ],
              ),
              const SizedBox(height: 14),
              for (final c in catches)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    c.moonAge == null
                        ? Icon(Icons.set_meal, color: p.accentInk)
                        : MoonIcon(age: c.moonAge!, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_name(context, c), style: p.title(15.5)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            DateFormat.yMMMd(locale).add_Hm().format(c.time),
                            if (c.weightKg != null) '${c.weightKg} kg',
                            if (c.lengthCm != null) '${c.lengthCm!.round()} cm',
                            if (c.windSpeed != null)
                              '${t.wind} ${c.windSpeed!.round()} ${t.kmh}',
                            if (c.waveHeight != null)
                              '${t.swell} ${c.waveHeight!.toStringAsFixed(1)} m',
                            if (c.note.isNotEmpty) c.note,
                          ].join(' · '),
                          style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.4),
                        ),
                      ]),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: p.muted),
                      tooltip: t.delete,
                      onPressed: () => state.removeCatch(c),
                    ),
                  ]),
                ),
            ]),
    );
  }

  static String _name(BuildContext context, Catch c) {
    final s = c.speciesId == null ? null : speciesById(c.speciesId!);
    return s?.name.of(context) ?? c.speciesName;
  }

  static Map<String, int> _counts(List<Catch> catches) {
    final counts = <String, int>{};
    for (final c in catches) {
      final key = c.speciesId ?? c.speciesName;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  static int _topCount(List<Catch> catches) =>
      _counts(catches).values.reduce((a, b) => a > b ? a : b);

  static String _topSpecies(BuildContext context, List<Catch> catches) {
    final top = _counts(catches).entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return speciesById(top)?.name.of(context) ?? top;
  }
}

class AddCatchScreen extends StatefulWidget {
  const AddCatchScreen({super.key});

  @override
  State<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends State<AddCatchScreen> {
  String? _speciesId = species.first.id;
  final _other = TextEditingController();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SubPage(
      title: t.addCatch,
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: _speciesId,
          decoration: InputDecoration(labelText: t.species),
          items: [
            for (final s in species)
              DropdownMenuItem(value: s.id, child: Text(s.name.of(context))),
            DropdownMenuItem(value: null, child: Text(t.otherSpecies)),
          ],
          onChanged: (v) => setState(() => _speciesId = v),
        ),
        if (_speciesId == null) ...[
          const SizedBox(height: 12),
          TextField(
              controller: _other,
              decoration: InputDecoration(labelText: t.speciesName)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.weightKg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _length,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.lengthCm),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLines: 3,
          decoration: InputDecoration(labelText: t.note),
        ),
        const SizedBox(height: 8),
        Text(t.catchAutoInfo,
            style: TextStyle(fontSize: 13, color: Palette.of(context).muted)),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(t.save),
        ),
      ]),
    );
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final state = AppScope.of(context);
    final name = _speciesId == null ? _other.text.trim() : _speciesId!;
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final pos = state.position;

    // Conditions are a bonus: save the catch even when offline.
    Forecast? f;
    try {
      f = await ForecastService()
          .fetch(pos.latitude, pos.longitude)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    await state.addCatch(Catch(
      speciesId: _speciesId,
      speciesName: name,
      time: now,
      position: pos,
      weightKg: _num(_weight),
      lengthCm: _num(_length),
      note: _note.text.trim(),
      windSpeed: f?.windSpeed,
      waveHeight: f?.waveHeight,
      pressure: f?.pressure,
      moonAge: moonInfo(now).age,
    ));
    if (mounted) Navigator.of(context).pop();
  }
}
