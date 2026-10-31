import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Animated loading page: an underwater fishing scene behind the logo.
/// Calls [onDone] once the intro has played (or right away when the system
/// asks to reduce animations).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 3600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Ambient loop (waves, fish, bubbles) and one-shot intro (logo, line, bar).
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: SplashScreen.duration);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
      Future.delayed(const Duration(milliseconds: 600), widget.onDone);
    } else {
      _loop.repeat();
      _intro.forward().whenComplete(widget.onDone);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final messages = [t.loadingTides, t.loadingMoon, t.loadingSpots];
    return Scaffold(
      backgroundColor: _Sea.abyss,
      body: GestureDetector(
        // A tap skips the intro.
        onTap: () {
          if (_intro.isAnimating) {
            _intro.stop();
            widget.onDone();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _intro]),
          builder: (context, _) {
            final intro = _intro.value;
            final logoIn = Curves.easeOutBack.transform(
                ((intro - 0.08) / 0.35).clamp(0.0, 1.0));
            final textIn = Curves.easeOut.transform(
                ((intro - 0.35) / 0.3).clamp(0.0, 1.0));
            final msg = messages[(intro * messages.length * 0.999).floor()];
            return Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _ScenePainter(_loop.value, intro)),
              SafeArea(
                child: Column(children: [
                  const Spacer(flex: 5),
                  Opacity(
                    opacity: logoIn.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, sin(_loop.value * 2 * pi * 2) * 4),
                      child: Transform.scale(
                        scale: 0.75 + 0.25 * logoIn,
                        child: _GlowingLogo(pulse: _loop.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: textIn,
                    child: Text(t.subtitle,
                        style: const TextStyle(
                            color: Color(0xFFBFE6F5),
                            fontSize: 16,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(flex: 4),
                  Opacity(
                    opacity: textIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56),
                      child: Column(children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(msg,
                              key: ValueKey(msg),
                              style: const TextStyle(
                                  color: Color(0xFF9CC9DC), fontSize: 13.5)),
                        ),
                        const SizedBox(height: 10),
                        _WaveProgress(value: intro, phase: _loop.value),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 36),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Sea {
  static const sky1 = Color(0xFF16466F);
  static const sky2 = Color(0xFF2A78A6);
  static const surface = Color(0xFF0E5E8E);
  static const mid = Color(0xFF0A3A63);
  static const abyss = Color(0xFF041A30);
  static const sun = Color(0xFFFFB627);
  static const float = Color(0xFFFF6B2C);
  static const foam = Color(0xFFBFF3FF);
}

class _GlowingLogo extends StatelessWidget {
  const _GlowingLogo({required this.pulse});
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final glow = 0.35 + 0.15 * sin(pulse * 2 * pi * 2);
    return Container(
      width: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12B5CB).withValues(alpha: glow),
            blurRadius: 60,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Image.asset('assets/brand/logo_full.png', fit: BoxFit.contain),
    );
  }
}

/// Loading bar whose filled part has a wavy top edge.
class _WaveProgress extends StatelessWidget {
  const _WaveProgress({required this.value, required this.phase});
  final double value, phase;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 12,
        width: double.infinity,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(painter: _WaveBarPainter(value, phase)),
        ),
      );
}

class _WaveBarPainter extends CustomPainter {
  _WaveBarPainter(this.value, this.phase);
  final double value, phase;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(99));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.save();
    canvas.clipRRect(r);
    final w = size.width * value;
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= w; x += 2) {
      path.lineTo(x, 3 + sin(x / 9 + phase * 2 * pi * 4) * 2);
    }
    path
      ..lineTo(w, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF12B5CB), Color(0xFF8CF1FF)],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaveBarPainter old) => old.value != value || old.phase != phase;
}

/// Sky at dusk, wavy surface with a bobbing float, a line and hook sinking,
/// light rays, fish, bubbles, and seaweed on the bottom.
class _ScenePainter extends CustomPainter {
  _ScenePainter(this.t, this.intro);

  /// Ambient loop position (0–1) and intro progress (0–1).
  final double t, intro;

  static final _rand = Random(7);
  static final _bubbles = List.generate(
      28,
      (_) => (
            _rand.nextDouble(), // x
            0.25 + _rand.nextDouble() * 0.6, // speed
            1.5 + _rand.nextDouble() * 4, // radius
            _rand.nextDouble(), // phase
          ));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tau = 2 * pi;
    final surfaceY = h * 0.15;

    // Sky with a low sun.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, surfaceY + 20),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Sea.sky1, _Sea.sky2],
        ).createShader(Rect.fromLTWH(0, 0, w, surfaceY + 20)),
    );
    final sunC = Offset(w * 0.22, surfaceY + 6);
    canvas.drawCircle(
      sunC,
      w * 0.3,
      Paint()
        ..shader = RadialGradient(colors: [
          _Sea.sun.withValues(alpha: 0.55),
          _Sea.sun.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: sunC, radius: w * 0.3)),
    );
    canvas.drawCircle(sunC, w * 0.07, Paint()..color = _Sea.sun);

    // Water body.
    double surface(double x) =>
        surfaceY + sin(x / w * tau * 2 + t * tau * 2) * 5 + sin(x / w * tau * 5 - t * tau * 3) * 2;
    final water = Path()..moveTo(0, surface(0));
    for (var x = 0.0; x <= w; x += 6) {
      water.lineTo(x, surface(x));
    }
    water
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      water,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Sea.surface, _Sea.mid, _Sea.abyss],
          stops: [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(0, surfaceY, w, h - surfaceY)),
    );
    // Foam line on the surface.
    final foam = Path()..moveTo(0, surface(0));
    for (var x = 0.0; x <= w; x += 6) {
      foam.lineTo(x, surface(x));
    }
    canvas.drawPath(
        foam,
        Paint()
          ..color = _Sea.foam.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Light rays fanning down from the surface.
    for (var i = 0; i < 5; i++) {
      final sway = sin(t * tau + i) * 0.04;
      final x0 = w * (0.1 + i * 0.2);
      final ray = Path()
        ..moveTo(x0 - 14, surfaceY)
        ..lineTo(x0 + 14, surfaceY)
        ..lineTo(x0 + w * (0.12 + sway), h * 0.75)
        ..lineTo(x0 - w * (0.02 - sway), h * 0.75)
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, surfaceY, w, h * 0.6)),
      );
    }

    // Seabed with swaying seaweed.
    final bed = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 8) {
      bed.lineTo(x, h * 0.93 + sin(x / w * tau * 1.3) * 10);
    }
    bed
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bed, Paint()..color = const Color(0xFF02101F));
    final weed = Paint()
      ..color = const Color(0xFF0F5A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final (fx, len) in [(0.08, 0.16), (0.12, 0.11), (0.88, 0.14), (0.93, 0.09), (0.62, 0.07)]) {
      final base = Offset(w * fx, h * 0.95);
      final p = Path()..moveTo(base.dx, base.dy);
      for (var k = 1; k <= 10; k++) {
        final y = base.dy - h * len * k / 10;
        p.lineTo(base.dx + sin(t * tau * 2 + k * 0.6 + fx * 10) * k * 1.6, y);
      }
      canvas.drawPath(p, weed);
    }

    // Fish swimming across at different depths.
    for (final (depth, speed, scale, dir, phase) in [
      (0.34, 1.0, 1.0, 1.0, 0.0),
      (0.58, 2.0, 0.7, -1.0, 0.4),
      (0.78, 1.0, 1.25, 1.0, 0.7),
      (0.48, 1.0, 0.55, -1.0, 0.15),
    ]) {
      final p = (t * speed + phase) % 1;
      final x = dir > 0 ? -60 + p * (w + 120) : w + 60 - p * (w + 120);
      final y = h * depth + sin(p * tau * 3) * 6;
      _fish(canvas, Offset(x, y), 26 * scale, dir, t * tau * 6 + phase * 10,
          Color.lerp(const Color(0xFF2EC4D6), const Color(0xFF0B3E66), (depth - 0.3) * 1.4)!
              .withValues(alpha: 0.85));
    }

    // Float bobbing on the surface, line and hook sinking during the intro.
    final fx = w * 0.8;
    final floatY = surface(fx) - 4 + sin(t * tau * 3) * 2;
    final hookY = surfaceY + (h * 0.5) * Curves.easeOut.transform(intro.clamp(0.0, 1.0));
    final hookX = fx + sin(t * tau * 2) * 6;
    canvas.drawLine(Offset(fx, floatY - 40), Offset(fx, floatY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1.2);
    canvas.drawLine(Offset(fx, floatY + 8), Offset(hookX, hookY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 1.2);
    final floatPath = Path()
      ..moveTo(fx, floatY - 12)
      ..quadraticBezierTo(fx + 9, floatY - 2, fx, floatY + 9)
      ..quadraticBezierTo(fx - 9, floatY - 2, fx, floatY - 12);
    canvas.drawPath(floatPath, Paint()..color = _Sea.float);
    canvas.drawRect(Rect.fromLTWH(fx - 5, floatY - 1, 10, 3),
        Paint()..color = Colors.white.withValues(alpha: 0.9));
    final hook = Path()
      ..moveTo(hookX, hookY)
      ..lineTo(hookX, hookY + 16)
      ..arcToPoint(Offset(hookX - 12, hookY + 16),
          radius: const Radius.circular(6), clockwise: true)
      ..lineTo(hookX - 12, hookY + 10);
    canvas.drawPath(
        hook,
        Paint()
          ..color = const Color(0xFFD7E3EC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);

    // Bubbles rising and wobbling.
    for (final (bx, speed, r, phase) in _bubbles) {
      final p = (t * speed * 2 + phase) % 1;
      final y = h * 0.95 - p * (h * 0.95 - surfaceY);
      final x = w * bx + sin(p * tau * 3 + phase * 6) * 8;
      final fade = (1 - p).clamp(0.0, 1.0) * 0.5 + 0.1;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = _Sea.foam.withValues(alpha: fade * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      canvas.drawCircle(Offset(x - r * 0.35, y - r * 0.35), r * 0.25,
          Paint()..color = Colors.white.withValues(alpha: fade * 0.7));
    }
  }

  /// Simple fish silhouette with a wagging tail; [dir] 1 = to the right.
  void _fish(Canvas canvas, Offset at, double s, double dir, double wag, Color color) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(dir, 1);
    final tail = sin(wag) * s * 0.18;
    final body = Path()
      ..moveTo(s, 0)
      ..quadraticBezierTo(s * 0.3, -s * 0.55, -s * 0.55, 0)
      ..quadraticBezierTo(s * 0.3, s * 0.55, s, 0)
      ..close();
    final tailPath = Path()
      ..moveTo(-s * 0.45, 0)
      ..lineTo(-s * 1.0, -s * 0.38 + tail)
      ..lineTo(-s * 0.85, tail * 0.5)
      ..lineTo(-s * 1.0, s * 0.38 + tail)
      ..close();
    final paint = Paint()..color = color;
    canvas.drawPath(tailPath, paint);
    canvas.drawPath(body, paint);
    canvas.drawCircle(Offset(s * 0.6, -s * 0.1), s * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.intro != intro;
}
