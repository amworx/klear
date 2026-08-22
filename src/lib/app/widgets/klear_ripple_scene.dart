import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated Klear "Ripple" splash mark.
///
/// A white badge (circle) holds the brand cyan drop, with concentric white
/// ripple rings expanding outward like a water drop landing — the car-wash
/// metaphor. The background is brand cyan and the badge matches the native
/// Android launch screen (same white-circle + cyan-drop mark), so the
/// cold-start handoff is seamless. Honors reduced motion.
class KlearRippleScene extends StatefulWidget {
  const KlearRippleScene({super.key, this.size = 280});

  /// Side length of the square the scene is drawn into.
  final double size;

  @override
  State<KlearRippleScene> createState() => _KlearRippleSceneState();
}

class _KlearRippleSceneState extends State<KlearRippleScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reduced) {
      _reduced = reduced;
      if (reduced) {
        _controller.stop();
      } else if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _reduced ? 0.0 : _controller.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RipplePainter(
              progress: t,
              brand: brand,
              reduced: _reduced,
            ),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.progress,
    required this.brand,
    required this.reduced,
  });

  final double progress;
  final Color brand;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final badgeR = size.width * 0.30;

    // ---- Ripple rings (behind the badge) ----
    if (!reduced) {
      _drawRipple(canvas, c, badgeR, progress, size.width);
      _drawRipple(canvas, c, badgeR, (progress + 0.5) % 1.0, size.width);
    } else {
      _ring(canvas, c, badgeR * 1.4, 0.15, size.width);
    }

    // ---- White badge circle ----
    canvas.drawCircle(c, badgeR, Paint()..color = Colors.white);

    // ---- Cyan brand drop inside the badge ----
    final s = badgeR * 1.55;
    canvas.drawPath(_dropPath(c, s), Paint()..color = brand);

    // ---- Specular glint, upper-left of the bulb ----
    canvas.drawCircle(
      Offset(c.dx - s * 0.08, c.dy - s * 0.02),
      s * 0.0625,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  /// One ripple ring: expands from the badge edge outward and fades in then
  /// out (sine envelope) so there is never a hard outline at t=0.
  void _drawRipple(
    Canvas canvas,
    Offset c,
    double badgeR,
    double t,
    double w,
  ) {
    final maxR = math.min(badgeR * 2.15, w * 0.47);
    final r = badgeR + (maxR - badgeR) * t;
    final alpha = math.sin(t * math.pi) * 0.5;
    _ring(canvas, c, r, alpha, w);
  }

  void _ring(Canvas canvas, Offset c, double r, double alpha, double w) {
    if (alpha <= 0.001) return;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.01,
    );
  }

  /// Symmetric teardrop, tip up, normalized control points matching the
  /// native launch-screen vector and the previous loader so the shapes stay
  /// consistent across the native -> Flutter handoff.
  Path _dropPath(Offset c, double s) {
    Offset p(double nx, double ny) =>
        Offset(c.dx + (nx - 0.5) * s, c.dy + (ny - 0.5) * s);
    return Path()
      ..moveTo(p(0.50, 0.06).dx, p(0.50, 0.06).dy)
      ..cubicTo(p(0.50, 0.06).dx, p(0.50, 0.06).dy, p(0.88, 0.44).dx,
          p(0.88, 0.44).dy, p(0.88, 0.62).dx, p(0.88, 0.62).dy)
      ..cubicTo(p(0.88, 0.80).dx, p(0.88, 0.80).dy, p(0.725, 0.94).dx,
          p(0.725, 0.94).dy, p(0.50, 0.94).dx, p(0.50, 0.94).dy)
      ..cubicTo(p(0.275, 0.94).dx, p(0.275, 0.94).dy, p(0.12, 0.80).dx,
          p(0.12, 0.80).dy, p(0.12, 0.62).dx, p(0.12, 0.62).dy)
      ..cubicTo(p(0.12, 0.44).dx, p(0.12, 0.44).dy, p(0.50, 0.06).dx,
          p(0.50, 0.06).dy, p(0.50, 0.06).dx, p(0.50, 0.06).dy)
      ..close();
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.brand != brand ||
        oldDelegate.reduced != reduced;
  }
}
