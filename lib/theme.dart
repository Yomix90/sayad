import 'dart:math';

import 'package:flutter/material.dart';

/// The two looks of the app: a clean modern ocean style and an old
/// nautical-chart style (parchment, ink, serif fonts).
enum AppStyle { modern, classic }

/// Every colour and font the screens use, for the active [AppStyle].
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.style,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.muted,
    required this.primary,
    required this.accent,
    required this.accentInk,
    required this.border,
    required this.ok,
    required this.okInk,
    required this.okSoft,
    required this.warn,
    required this.warnInk,
    required this.warnSoft,
    required this.danger,
    required this.dangerInk,
    required this.dangerSoft,
    required this.radius,
    required this.radiusS,
    required this.header,
    required this.headerInk,
    required this.headerMuted,
    required this.navBg,
    required this.navInk,
    required this.navActive,
    required this.bandMajor,
    required this.bandMinor,
    required this.moonLit,
    required this.moonDark,
    required this.shadow,
    this.titleFont,
    this.numFont,
  });

  final AppStyle style;
  final Color bg, surface, surface2, text, muted;
  final Color primary, accent, accentInk, border;
  final Color ok, okInk, okSoft, warn, warnInk, warnSoft;
  final Color danger, dangerInk, dangerSoft;
  final double radius, radiusS;
  final Gradient header;
  final Color headerInk, headerMuted;
  final Gradient navBg;
  final Color navInk, navActive;
  final Color bandMajor, bandMinor, moonLit, moonDark;
  final List<BoxShadow> shadow;

  /// Font families for titles and figures (null: theme default).
  final String? titleFont;
  final String? numFont;

  bool get classic => style == AppStyle.classic;

  /// Large tabular figures (times, heights, speeds).
  TextStyle num(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      TextStyle(
        fontFamily: numFont,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        fontFeatures: const [FontFeature.tabularFigures(), FontFeature.liningFigures()],
      );

  TextStyle title(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: titleFont,
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
        letterSpacing: classic ? 0.4 : 0.2,
      );

  static Palette of(BuildContext context) =>
      Theme.of(context).extension<Palette>() ?? modern;

  static const modern = Palette(
    style: AppStyle.modern,
    bg: Color(0xFFF4F7FA),
    surface: Colors.white,
    surface2: Color(0xFFE6F7FB),
    text: Color(0xFF0A2540),
    muted: Color(0xFF48607A),
    primary: Color(0xFF0A2540),
    accent: Color(0xFF00B4D8),
    accentInk: Color(0xFF075E76),
    border: Color(0xFFD7E3EC),
    ok: Color(0xFF2BB673),
    okInk: Color(0xFF0E6B44),
    okSoft: Color(0xFFE1F5EB),
    warn: Color(0xFFE8A93D),
    warnInk: Color(0xFF7C5310),
    warnSoft: Color(0xFFFBF1DC),
    danger: Color(0xFFFF6B4A),
    dangerInk: Color(0xFFAE3A1E),
    dangerSoft: Color(0xFFFFE9E2),
    radius: 20,
    radiusS: 14,
    header: LinearGradient(
      begin: Alignment(-0.6, -1),
      end: Alignment(0.6, 1),
      colors: [Color(0xFF0A2540), Color(0xFF0E3D63), Color(0xFF0F5B82)],
      stops: [0.08, 0.55, 1],
    ),
    headerInk: Color(0xFFEAF6FB),
    headerMuted: Color(0xFF9CC9DC),
    navBg: LinearGradient(colors: [Color(0xF2FFFFFF), Color(0xF2FFFFFF)]),
    navInk: Color(0xFF48607A),
    navActive: Color(0xFF075E76),
    bandMajor: Color(0xFF00B4D8),
    bandMinor: Color(0xFFBDE7F4),
    moonLit: Color(0xFFF1F7FF),
    moonDark: Color(0xFF1B3C5E),
    shadow: [
      BoxShadow(color: Color(0x1A0A2540), blurRadius: 28, offset: Offset(0, 10)),
    ],
  );

  static const classicPalette = Palette(
    style: AppStyle.classic,
    bg: Color(0xFFF3E9D2),
    surface: Color(0xFFF9F1DE),
    surface2: Color(0xFFEEE1C2),
    text: Color(0xFF3B2A1A),
    muted: Color(0xFF6E5A3F),
    primary: Color(0xFF2F4A5E),
    accent: Color(0xFFB08D57),
    accentInk: Color(0xFF8B2E1F),
    border: Color(0xFFC9B48B),
    ok: Color(0xFF4E6B3A),
    okInk: Color(0xFF3A5229),
    okSoft: Color(0xFFE7E9CE),
    warn: Color(0xFFB08D57),
    warnInk: Color(0xFF7A5B1E),
    warnSoft: Color(0xFFEFE3C4),
    danger: Color(0xFF8B2E1F),
    dangerInk: Color(0xFF8B2E1F),
    dangerSoft: Color(0xFFF0DACB),
    radius: 12,
    radiusS: 8,
    header: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF1E5C6), Color(0xFFEBDCB8)],
    ),
    headerInk: Color(0xFF3B2A1A),
    headerMuted: Color(0xFF7A6748),
    navBg: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4B3320), Color(0xFF33220F)],
    ),
    navInk: Color(0xFFB7A67F),
    navActive: Color(0xFFF3E9D2),
    bandMajor: Color(0xFF2F4A5E),
    bandMinor: Color(0xFFC7B78E),
    moonLit: Color(0xFFEFDFB4),
    moonDark: Color(0xFF5A4630),
    shadow: [
      BoxShadow(color: Color(0x293B2A1A), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );

  Palette withFonts(String? title, String? num) => Palette(
        style: style, bg: bg, surface: surface, surface2: surface2, text: text,
        muted: muted, primary: primary, accent: accent, accentInk: accentInk,
        border: border, ok: ok, okInk: okInk, okSoft: okSoft, warn: warn,
        warnInk: warnInk, warnSoft: warnSoft, danger: danger,
        dangerInk: dangerInk, dangerSoft: dangerSoft, radius: radius,
        radiusS: radiusS, header: header, headerInk: headerInk,
        headerMuted: headerMuted, navBg: navBg, navInk: navInk,
        navActive: navActive, bandMajor: bandMajor, bandMinor: bandMinor,
        moonLit: moonLit, moonDark: moonDark, shadow: shadow,
        titleFont: title, numFont: num,
      );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData buildAppTheme(AppStyle style, {required bool arabic}) {
  final base = style == AppStyle.classic ? Palette.classicPalette : Palette.modern;

  // Fonts are bundled in assets/fonts (see pubspec.yaml), so they work offline.
  final String body, title, num;
  if (style == AppStyle.modern) {
    body = arabic ? 'IBMPlexSansArabic' : 'Manrope';
    title = arabic ? 'IBMPlexSansArabic' : 'SpaceGrotesk';
    num = 'SpaceGrotesk';
  } else {
    body = arabic ? 'Amiri' : 'EBGaramond';
    title = arabic ? 'Amiri' : 'Cinzel';
    num = arabic ? 'Amiri' : 'EBGaramond';
  }
  final p = base.withFonts(title, num);

  final scheme = ColorScheme.fromSeed(seedColor: p.accent).copyWith(
    primary: p.classic ? p.primary : p.accentInk,
    onPrimary: Colors.white,
    secondary: p.accent,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.border,
    outlineVariant: p.border,
    error: p.danger,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surface2,
    primaryContainer: p.surface2,
    onPrimaryContainer: p.text,
  );

  final textTheme = ThemeData.light().textTheme.apply(
    fontFamily: body,
    fontFamilyFallback: const ['IBMPlexSansArabic', 'Amiri'],
    bodyColor: p.text,
    displayColor: p.text,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: body,
    fontFamilyFallback: const ['IBMPlexSansArabic', 'Amiri'],
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    textTheme: textTheme,
    extensions: [p],
    dividerColor: p.border,
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(p.radius),
        side: BorderSide(color: p.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.headerInk,
      elevation: 0,
      titleTextStyle: p.title(20, color: p.headerInk),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.classic ? p.primary : p.accent,
        foregroundColor: p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B),
        minimumSize: const Size(48, 48),
        textStyle: TextStyle(
            fontFamily: body,
            fontFamilyFallback: const ['IBMPlexSansArabic', 'Amiri'],
            fontWeight: FontWeight.w700,
            fontSize: 15.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(p.radiusS),
          side: p.classic ? BorderSide(color: p.accent, width: 1.5) : BorderSide.none,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: p.border, width: 1.5),
        textStyle: TextStyle(
            fontFamily: body,
            fontFamilyFallback: const ['IBMPlexSansArabic', 'Amiri'],
            fontWeight: FontWeight.w700,
            fontSize: 15.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.radiusS)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.classic ? p.primary : p.accent,
      foregroundColor: p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      dragHandleColor: p.border,
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.primary,
      contentTextStyle: TextStyle(
          fontFamily: body,
          fontFamilyFallback: const ['IBMPlexSansArabic', 'Amiri'],
          color: p.classic ? const Color(0xFFF3E9D2) : Colors.white,
          fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.radiusS)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusS),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusS),
        borderSide: BorderSide(color: p.border),
      ),
    ),
  );
}

/// Ocean header (modern, with moving waves) or parchment header with a
/// slowly turning compass rose (classic).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.child, this.bottomPadding});

  final Widget child;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: p.header,
        border: p.classic
            ? Border(bottom: BorderSide(color: p.primary, width: 2))
            : null,
        boxShadow: p.classic
            ? [BoxShadow(color: p.accent, offset: const Offset(0, 1), spreadRadius: -0.5)]
            : null,
      ),
      child: ClipRect(
        child: Stack(children: [
          if (p.classic)
            PositionedDirectional(
              end: -34,
              top: -40,
              child: Opacity(
                opacity: 0.2,
                child: SpinningRose(size: 150, color: p.primary),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, bottomPadding ?? (p.classic ? 14 : 28)),
              child: child,
            ),
          ),
          if (!p.classic)
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 26,
              child: HeaderWaves(color: p.bg),
            ),
        ]),
      ),
    );
  }
}

/// Two wave layers sliding sideways at different speeds.
class HeaderWaves extends StatefulWidget {
  const HeaderWaves({super.key, required this.color});
  final Color color;

  @override
  State<HeaderWaves> createState() => _HeaderWavesState();
}

class _HeaderWavesState extends State<HeaderWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 13));

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
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WavesPainter(_c, widget.color),
        ),
      );
}

class _WavesPainter extends CustomPainter {
  _WavesPainter(this.anim, this.color) : super(repaint: anim);
  final Animation<double> anim;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double baseY, double amp, double wavelength, double phase, Color c) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 4; x += 4) {
        path.lineTo(x, baseY + sin((x / wavelength + phase) * 2 * pi) * amp);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    final t = anim.value;
    wave(size.height * 0.54, 5, 97, t, color.withValues(alpha: 0.55));
    // Second layer is slower (21 s vs 13 s) and moves the other way.
    wave(size.height * 0.69, 5, 120, -t * 13 / 21, color);
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.color != color;
}

/// Compass rose turning once every 140 s.
class SpinningRose extends StatefulWidget {
  const SpinningRose({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  State<SpinningRose> createState() => _SpinningRoseState();
}

class _SpinningRoseState extends State<SpinningRose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 140));

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
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: CompassRose(size: widget.size, color: widget.color),
      );
}

class CompassRose extends StatelessWidget {
  const CompassRose({super.key, required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RosePainter(color)),
      );
}

class _RosePainter extends CustomPainter {
  _RosePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.scale(s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(const Offset(50, 50), 46, stroke);
    for (var a = 0.0; a < 2 * pi; a += 2 * pi / 48) {
      canvas.drawLine(Offset(50 + cos(a) * 34, 50 + sin(a) * 34),
          Offset(50 + cos(a) * 32, 50 + sin(a) * 32), stroke);
    }
    final star = Path()
      ..moveTo(50, 6)
      ..lineTo(56, 44)
      ..lineTo(50, 50)
      ..lineTo(44, 44)
      ..close()
      ..moveTo(50, 94)
      ..lineTo(44, 56)
      ..lineTo(50, 50)
      ..lineTo(56, 56)
      ..close()
      ..moveTo(6, 50)
      ..lineTo(44, 44)
      ..lineTo(50, 50)
      ..lineTo(44, 56)
      ..close()
      ..moveTo(94, 50)
      ..lineTo(56, 56)
      ..lineTo(50, 50)
      ..lineTo(56, 44)
      ..close();
    canvas.drawPath(star, stroke);
    final thin = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (final (a, b) in [
      (const Offset(20, 20), const Offset(46, 46)),
      (const Offset(80, 20), const Offset(54, 46)),
      (const Offset(20, 80), const Offset(46, 54)),
      (const Offset(80, 80), const Offset(54, 54)),
    ]) {
      canvas.drawLine(a, b, thin);
    }
    canvas.drawCircle(const Offset(50, 50), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RosePainter old) => old.color != color;
}

/// Page background: flat in the modern style, warm paper in the classic one.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    if (!p.classic) return ColoredBox(color: p.bg, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bg,
        gradient: RadialGradient(
          center: const Alignment(0.75, -1.1),
          radius: 1.3,
          colors: [p.accent.withValues(alpha: 0.14), p.bg.withValues(alpha: 0)],
        ),
      ),
      child: child,
    );
  }
}
