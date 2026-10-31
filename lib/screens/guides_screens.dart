import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/knots.dart';
import '../data/species.dart';
import '../data/tips.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import '../widgets/sub_page.dart';

/// Knots and hooks: segmented control, grid of illustrated cards.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  GuideCat _cat = GuideCat.knot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final items = guide.where((g) => g.cat == _cat).toList();
    return SubPage(
      title: t.guide,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        ScreenHead(
          title: t.guide,
          trailing: StatusChip(label: t.knotsAndHooks, icon: 'book'),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(p.radiusS),
            border: Border.all(color: p.border),
          ),
          child: Row(children: [
            for (final (cat, label) in [
              (GuideCat.knot, t.knotsShort),
              (GuideCat.hook, t.hooks),
            ])
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cat = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _cat == cat ? p.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(p.radiusS - 4),
                      border: _cat == cat && p.classic
                          ? Border.all(color: p.accent, width: 1.5)
                          : null,
                      boxShadow: _cat == cat && !p.classic ? p.shadow : null,
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _cat == cat ? p.text : p.muted)),
                  ),
                ),
              ),
          ]),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: [
            for (final g in items)
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GuideDetailScreen(item: g))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 92,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(p.radiusS),
                        ),
                        child: Center(
                          child: LineIcon(g.icon,
                              size: 64,
                              color: p.classic
                                  ? const Color(0xFF33220F)
                                  : p.accentInk),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(g.name.of(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: p.title(15).copyWith(height: 1.25)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(g.use.of(context),
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontSize: 12.5, color: p.muted, height: 1.35)),
                      ),
                    ]),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Frieze(),
      ]),
    );
  }
}

class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.item});
  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final ink = p.classic ? const Color(0xFF33220F) : p.accentInk;
    return SubPage(
      title: item.name.of(context),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(child: LineIcon(item.icon, size: 120, color: ink)),
          ),
        ),
        Text(item.name.of(context), style: p.title(21)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          StatusChip(label: '${t.use} : ${item.use.of(context)}'),
          StatusChip(
            label:
                '${t.difficulty} : ${item.difficulty == 1 ? t.easy : t.medium} ${'●' * item.difficulty}${'○' * (2 - item.difficulty)}',
            tone: ChipTone.warn,
          ),
        ]),
        const SizedBox(height: 14),
        Text(t.steps, style: p.title(16)),
        const SizedBox(height: 10),
        for (var i = 0; i < item.steps.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.classic ? p.primary : p.accent,
                  shape: BoxShape.circle,
                  border: p.classic ? Border.all(color: p.accent, width: 1.5) : null,
                ),
                child: Text('${i + 1}',
                    style: p.num(15,
                        color: p.classic
                            ? const Color(0xFFF3E9D2)
                            : const Color(0xFF04222B))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.steps[i].of(context),
                    style: const TextStyle(fontSize: 16, height: 1.45)),
              ),
            ]),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.warnSoft,
            borderRadius: BorderRadius.circular(p.radiusS),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LineIcon('info', size: 19, color: p.warnInk),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${t.tip} — ${item.tip.of(context)}',
                  style: TextStyle(fontSize: 14.5, height: 1.45, color: p.warnInk)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class SpeciesScreen extends StatelessWidget {
  const SpeciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final month = DateTime.now().month;
    return SubPage(
      title: t.species,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        for (final s in species)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SpeciesDetailScreen(species: s))),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(p.radiusS),
                ),
                child: Center(
                  child: LineIcon('fish',
                      size: 26, color: p.classic ? p.primary : p.accentInk),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name.of(context), style: p.title(15.5)),
                      Text(s.latin,
                          style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: p.muted)),
                    ]),
              ),
              if (s.months.contains(month))
                StatusChip(label: t.inSeason, tone: ChipTone.ok, dot: true),
            ]),
          ),
        const SizedBox(height: 4),
        Text(t.sizeDisclaimer, style: TextStyle(fontSize: 12.5, color: p.muted)),
      ]),
    );
  }
}

class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({super.key, required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final s = species;
    final ink = p.classic ? p.accent : p.accentInk;

    Widget section(IconData icon, String title, String body) => AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: ink, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: p.title(14.5, color: ink)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 15, height: 1.45)),
              ]),
            ),
          ]),
        );

    return SubPage(
      title: s.name.of(context),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Text(s.latin,
            style: TextStyle(fontStyle: FontStyle.italic, color: p.muted)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CardHead(title: t.bestSeason),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var m = 1; m <= 12; m++)
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: s.months.contains(m)
                        ? (p.classic ? p.primary : p.accent)
                        : p.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat.MMM(locale).format(DateTime(2026, m)),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.months.contains(m)
                            ? (p.classic
                                ? const Color(0xFFF3E9D2)
                                : const Color(0xFF04222B))
                            : p.muted),
                  ),
                ),
            ]),
          ]),
        ),
        section(Icons.place_outlined, t.habitat, s.habitat.of(context)),
        section(Icons.bug_report_outlined, t.bait, s.bait.of(context)),
        section(Icons.phishing, t.technique, s.technique.of(context)),
        if (s.minSizeCm != null)
          section(Icons.straighten, t.minSize, '${s.minSizeCm} cm'),
        const SizedBox(height: 4),
        Text(t.sizeDisclaimer, style: TextStyle(fontSize: 12.5, color: p.muted)),
      ]),
    );
  }
}

/// Short articles: when to fish, spring and neap tides, safety.
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    return SubPage(
      title: t.tips,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        for (final tip in tips)
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CardHead(title: tip.title.of(context)),
              for (final point in tip.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: p.classic ? p.accent : p.accentInk,
                            shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(point.of(context),
                          style: const TextStyle(fontSize: 15, height: 1.45)),
                    ),
                  ]),
                ),
            ]),
          ),
      ]),
    );
  }
}
