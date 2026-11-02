import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import 'big_tides_screen.dart';
import 'catch_log_screen.dart';
import 'compass_screen.dart';
import 'guides_screens.dart';
import 'prayer_screen.dart';
import 'settings_screen.dart';
import 'sky_screen.dart';
import 'solunar_screen.dart';
import 'weather_map_screen.dart';

/// Grid of the other tools of the app.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    // Icon, two gradient colours, title, subtitle, page.
    final tools = <(String, Color, Color, String, String, Widget)>[
      ('cloud', const Color(0xFF1E88E5), const Color(0xFF00BCD4), t.weatherMap, t.weatherMapSub, const WeatherMapScreen()),
      ('book', const Color(0xFF5E35B1), const Color(0xFF8E7CF0), t.guide, t.knotsAndHooks, const GuideScreen()),
      ('info', const Color(0xFF00897B), const Color(0xFF4DD0A9), t.tips, t.tipsSub, const TipsScreen()),
      ('fish', const Color(0xFF0277BD), const Color(0xFF26C6DA), t.species, t.speciesSub, const SpeciesScreen()),
      ('waves', const Color(0xFF283593), const Color(0xFF3F8EFC), t.bigTides, t.bigTidesSub, const BigTidesScreen()),
      ('sun', const Color(0xFFEF6C00), const Color(0xFFFFB74D), t.sky, t.skySub, const SkyScreen()),
      ('moon', const Color(0xFF37474F), const Color(0xFF7986CB), t.solunarCalendar, t.solunarSub, const SolunarScreen()),
      ('bookmark', const Color(0xFF2E7D32), const Color(0xFF9CCC65), t.catchLog, t.catchLogSub, const CatchLogScreen()),
      ('compass', const Color(0xFFC62828), const Color(0xFFFF8A65), t.compass, t.compassSub, const CompassScreen()),
      ('mosque', const Color(0xFF00695C), const Color(0xFFD4A017), t.tabPrayer, t.prayerSub, const PrayerScreen()),
      ('gear', const Color(0xFF455A64), const Color(0xFF90A4AE), t.tabSettings, t.settingsSub, const SettingsScreen()),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      children: [
        ScreenHead(title: t.tabTools),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            for (final (icon, c1, c2, title, sub, screen) in tools)
              AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => screen)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ToolArt(
                      icon: icon,
                      // The classic theme keeps its ink and parchment tones.
                      colors: p.classic
                          ? [Color.lerp(c1, const Color(0xFF3B2A16), 0.55)!,
                              Color.lerp(c2, const Color(0xFFB08A4A), 0.5)!]
                          : [c1, c2],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: p.title(15).copyWith(height: 1.2)),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(sub,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontSize: 12.5, color: p.muted, height: 1.35)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const Frieze(),
      ],
    );
  }
}

/// Illustrated header of a tool: gradient sea, waves, bubbles and the
/// tool's icon in a glassy disc.
class ToolArt extends StatelessWidget {
  const ToolArt({super.key, required this.icon, required this.colors, this.height = 78});

  final String icon;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(p.radiusS),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ToolArtPainter(colors, icon.hashCode),
          child: Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(child: LineIcon(icon, size: 26, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolArtPainter extends CustomPainter {
  _ToolArtPainter(this.colors, this.seed);

  final List<Color> colors;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ).createShader(rect));
    // Soft light in the top corner.
    canvas.drawCircle(
        Offset(size.width * 0.12, -size.height * 0.1),
        size.height * 0.9,
        Paint()..color = Colors.white.withValues(alpha: 0.10));
    // Two waves at the bottom, shifted per tool so tiles are not identical.
    final shift = (seed % 7) / 7 * math.pi * 2;
    for (final (level, amp, alpha) in [(0.72, 4.0, 0.16), (0.84, 3.2, 0.22)]) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 4) {
        path.lineTo(x, size.height * level + math.sin(x / size.width * math.pi * 3 + shift + level * 4) * amp);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
    // A few bubbles.
    final rnd = math.Random(seed);
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
          Offset(size.width * (0.65 + rnd.nextDouble() * 0.3), size.height * (0.15 + rnd.nextDouble() * 0.5)),
          1.5 + rnd.nextDouble() * 3,
          bubble);
    }
  }

  @override
  bool shouldRepaint(_ToolArtPainter old) => old.colors != colors || old.seed != seed;
}
