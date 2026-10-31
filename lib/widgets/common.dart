import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../theme.dart';
import 'line_icons.dart';

/// Surface card. In the classic style it gets a double rule and two
/// gilded corner brackets, like an old chart cartouche.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final radius = BorderRadius.circular(p.radius);
    Widget content = Padding(padding: padding, child: child);
    if (p.classic) {
      content = CustomPaint(
        foregroundPainter: _CartouchePainter(p.border, p.accent, p.radius),
        child: content,
      );
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: p.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _CartouchePainter extends CustomPainter {
  _CartouchePainter(this.rule, this.gold, this.radius);
  final Color rule, gold;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(3.5, 3.5, size.width - 7, size.height - 7),
          Radius.circular(max(0, radius - 3))),
      Paint()
        ..color = rule
        ..style = PaintingStyle.stroke,
    );
    final g = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
        Path()
          ..moveTo(6, 20)
          ..lineTo(6, 6)
          ..lineTo(20, 6),
        g);
    canvas.drawPath(
        Path()
          ..moveTo(size.width - 6, size.height - 20)
          ..lineTo(size.width - 6, size.height - 6)
          ..lineTo(size.width - 20, size.height - 6),
        g);
  }

  @override
  bool shouldRepaint(_CartouchePainter old) =>
      old.rule != rule || old.gold != gold;
}

/// Card title row: heading on one side, optional chip on the other.
class CardHead extends StatelessWidget {
  const CardHead({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Text(title, style: p.title(16.5))),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(flex: 2, child: trailing!),
        ],
      ]),
    );
  }
}

/// Screen title row (big heading + chip).
class ScreenHead extends StatelessWidget {
  const ScreenHead({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Text(title, style: p.title(21))),
        ?trailing,
      ]),
    );
  }
}

enum ChipTone { neutral, ok, warn, danger, solid }

/// Rounded status pill, optionally with a coloured dot or icon.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.dot = false,
    this.icon,
    this.dotColor,
    this.compact = true,
    this.onTap,
  });

  final String label;
  final ChipTone tone;
  final bool dot;
  final String? icon;
  final Color? dotColor;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (bg, fg, dotC, border) = switch (tone) {
      ChipTone.ok => (p.okSoft, p.okInk, p.ok, Colors.transparent),
      ChipTone.warn => (p.warnSoft, p.warnInk, p.warn, Colors.transparent),
      ChipTone.danger => (p.dangerSoft, p.dangerInk, p.danger, Colors.transparent),
      ChipTone.solid => (
          p.primary,
          p.classic ? const Color(0xFFF3E9D2) : Colors.white,
          p.accent,
          p.classic ? p.accent : p.primary
        ),
      ChipTone.neutral => (p.surface2, p.text, p.accent, p.border),
    };
    final chip = Container(
      constraints: BoxConstraints(minHeight: compact ? 34 : 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: dotColor ?? dotC, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
        ],
        if (icon != null) ...[
          LineIcon(icon!, size: 15, color: fg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
        ),
      ]),
    );
    return onTap == null
        ? chip
        : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: chip);
  }
}

/// Weather tile: small icon + label, a big figure (≥ 28 px), a sub-line.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.sub,
    this.valueColor,
  });

  final String icon;
  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          LineIcon(icon, size: 18, color: p.classic ? p.accent : p.accentInk),
          const SizedBox(width: 7),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: p.muted)),
          ),
        ]),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: [
          TextSpan(text: value, style: p.num(30, color: valueColor)),
          if (unit != null)
            TextSpan(
                text: ' $unit',
                style: p.num(15, weight: FontWeight.w600, color: p.muted)),
        ])),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: TextStyle(fontSize: 13, color: p.muted)),
        ],
      ]),
    );
  }
}

/// Section used by secondary screens: card with an icon and a title.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon});

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: p.classic ? p.accent : p.accentInk),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(title, style: p.title(16.5))),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

/// Label + figure, used inside section cards.
class Metric extends StatelessWidget {
  const Metric({super.key, required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, color: p.muted)),
      const SizedBox(height: 2),
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Text(value, style: p.num(20)),
      ]),
    ]);
  }
}

/// Diamond frieze separator (classic style only), after Amazigh patterns.
class Frieze extends StatelessWidget {
  const Frieze({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (!p.classic) return const SizedBox(height: 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 16),
      child: SizedBox(
        height: 14,
        width: double.infinity,
        child: CustomPaint(painter: _FriezePainter(p.text.withValues(alpha: 0.38))),
      ),
    );
  }
}

class _FriezePainter extends CustomPainter {
  _FriezePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var x = 0.0; x + 26 <= size.width; x += 26) {
      canvas.drawPath(
          Path()
            ..moveTo(x + 13, 2)
            ..lineTo(x + 24, 7)
            ..lineTo(x + 13, 12)
            ..lineTo(x + 2, 7)
            ..close(),
          paint);
    }
  }

  @override
  bool shouldRepaint(_FriezePainter old) => old.color != color;
}

/// Arrow pointing where the wind blows to (meteorological degrees = from).
class WindArrow extends StatelessWidget {
  const WindArrow({super.key, required this.degrees, this.size = 20, this.color});

  final double degrees;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Arrows must not be mirrored in RTL: compass directions are absolute.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Transform.rotate(
        angle: (degrees + 180) * pi / 180,
        child: LineIcon('up', size: size, color: color),
      ),
    );
  }
}

/// Weather-code (WMO) to icon.
IconData weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_outlined;
  if (code <= 3) return Icons.cloud_queue;
  if (code <= 48) return Icons.foggy;
  if (code <= 67 || (code >= 80 && code <= 82)) return Icons.water_drop_outlined;
  if (code <= 77 || code == 85 || code == 86) return Icons.ac_unit;
  return Icons.thunderstorm_outlined;
}

/// 16-point compass name for a direction in degrees.
String compassPoint(double deg) {
  const names = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW',
      'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  return names[((deg % 360) / 22.5).round() % 16];
}

/// Sea state from wind and waves: 0 calm, 1 moderate, 2 rough.
int seaState(double windKmh, double? waveM) {
  final w = waveM ?? 0;
  if (windKmh >= 30 || w >= 2.0) return 2;
  if (windKmh >= 20 || w >= 1.0) return 1;
  return 0;
}

/// Moon disc drawn from its age (days since new moon), with craters.
class MoonIcon extends StatelessWidget {
  const MoonIcon({super.key, required this.age, this.size = 28});

  final double age;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MoonPainter(age, p.moonLit, p.moonDark)),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.age, this.lit, this.dark);
  final double age;
  final Color lit, dark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = dark);

    final phase = age / 29.530588853; // 0 new, 0.5 full
    final waxing = phase < 0.5;
    final k = cos(phase * 2 * pi); // 1 new, -1 full
    final litPath = Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcToPoint(Offset(c.dx, c.dy + r),
          radius: Radius.circular(r), clockwise: waxing)
      ..arcToPoint(Offset(c.dx, c.dy - r),
          radius: Radius.elliptical((r * k).abs().clamp(0.01, r), r),
          clockwise: waxing ? k < 0 : k > 0);
    canvas.drawPath(litPath, Paint()..color = lit);
    if (size.shortestSide >= 40) {
      final crater = Paint()..color = dark.withValues(alpha: 0.18);
      canvas.drawCircle(c + Offset(r * 0.37, -r * 0.3), r * 0.16, crater);
      canvas.drawCircle(c + Offset(r * 0.22, r * 0.37), r * 0.11, crater);
      canvas.drawCircle(c + Offset(r * 0.55, r * 0.07), r * 0.08, crater);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.age != age || old.lit != lit || old.dark != dark;
}

/// Text in the three app languages, picked from the current locale.
class L3 {
  const L3(this.ar, this.fr, this.en);

  final String ar;
  final String fr;
  final String en;

  String of(BuildContext context) =>
      switch (Localizations.localeOf(context).languageCode) {
        'ar' => ar,
        'en' => en,
        _ => fr,
      };
}

/// Horizontal row of day chips (weekday + date), one selected.
class DayChips extends StatelessWidget {
  const DayChips({
    super.key,
    required this.start,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final DateTime start;
  final int count;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = start.add(Duration(days: i));
          final sel = i == selected;
          final selInk = p.classic ? const Color(0xFFF3E9D2) : Colors.white;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                color: sel ? p.primary : p.surface,
                borderRadius: BorderRadius.circular(p.radiusS),
                border: Border.all(
                    color: sel ? (p.classic ? p.accent : p.primary) : p.border,
                    width: sel && p.classic ? 2 : 1),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    _weekday(locale, d),
                    style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                        color: sel ? selInk.withValues(alpha: 0.75) : p.muted)),
                Text('${d.day}', style: p.num(18, color: sel ? selInk : p.text)),
              ]),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _weekday(String locale, DateTime d) =>
      MaterialLocalizationsWeekday.short(locale, d);
}

/// Short weekday name without trailing dot (e.g. "SAM", "SAT", "السبت").
class MaterialLocalizationsWeekday {
  static String short(String locale, DateTime d) {
    final s = DateFormat.E(locale).format(d).replaceAll('.', '');
    return locale.startsWith('ar') ? s : s.toUpperCase();
  }
}

/// Two-column grid whose rows take the height of their tallest tile.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.gap = 12, this.columns = 2});
  final List<Widget> children;
  final double gap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < children.length; i += columns)
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < children.length ? gap : 0),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var j = i; j < i + columns; j++) ...[
                if (j > i) SizedBox(width: gap),
                Expanded(child: j < children.length ? children[j] : const SizedBox()),
              ],
            ]),
          ),
        ),
    ]);
  }
}

/// Button content: icon then a label that shrinks instead of overflowing.
class IconLabel extends StatelessWidget {
  const IconLabel({super.key, required this.icon, required this.label});
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );
}
