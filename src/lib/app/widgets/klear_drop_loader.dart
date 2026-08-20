import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated Klear brand loader: a water drop that fills from bottom to top
/// with an oscillating wave surface and rising bubbles, plus a subtle
/// "breathing" scale on the whole mark.
///
/// Doubles as the splash hero — the white circle + cyan drop matches the
/// native launch screen artwork, so the cold-start transition is seamless.
/// Honors reduced motion (renders a static full drop, no wave, no bubbles).
class KlearDropLoader extends StatefulWidget {
  const KlearDropLoader({super.key, this.size = 120});

  final double size;

  @override
  State<KlearDropLoader> createState() => _KlearDropLoaderState();
}

class _KlearDropLoaderState extends State<KlearDropLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reducedMotion) {
      setState(() => _reducedMotion = reduced);
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
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final progress = _reducedMotion ? 1.0 : t;
        // Gentle breathing: two subtle scale pulses per cycle.
        final scale =
            _reducedMotion ? 1.0 : 1.0 + 0.02 * math.sin(t * math.pi * 4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _FillingDropPainter(
                progress: progress,
                wavePhase: t * math.pi * 2,
                color: color,
                reduced: _reducedMotion,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FillingDropPainter extends CustomPainter {
  _FillingDropPainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    required this.reduced,
  });

  final double progress;
  final double wavePhase;
  final Color color;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drop = _dropPath(w, h);

    // Water surface rises from the drop base toward the tip as progress → 1.
    final bottom = h * 0.94;
    final nearTip = h * 0.22;
    final surfaceY = bottom + (nearTip - bottom) * progress;

    if (progress > 0.01) {
      canvas.save();
      canvas.clipPath(drop);
      canvas.drawPath(
        _waterPath(w, h, surfaceY),
        Paint()..color = color,
      );
      if (!reduced) {
        _drawBubbles(canvas, w, h, surfaceY);
      }
      canvas.restore();
    }

    // Outline.
    canvas.drawPath(
      drop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..color = color,
    );
  }

  /// Symmetric teardrop, tip pointing up.
  Path _dropPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..cubicTo(w * 0.5, h * 0.06, w * 0.82, h * 0.44, w * 0.82, h * 0.62)
      ..cubicTo(w * 0.82, h * 0.86, w * 0.68, h * 0.94, w * 0.5, h * 0.94)
      ..cubicTo(w * 0.32, h * 0.94, w * 0.18, h * 0.86, w * 0.18, h * 0.62)
      ..cubicTo(w * 0.18, h * 0.44, w * 0.5, h * 0.06, w * 0.5, h * 0.06)
      ..close();
  }

  /// Filled area with a sine-wave top edge (two crests across the width).
  Path _waterPath(double w, double h, double surfaceY) {
    const samples = 24;
    final amp = reduced ? 0.0 : w * 0.02;
    final left = w * 0.18;
    final right = w * 0.82;
    final path = Path()..moveTo(left, surfaceY);
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = left + (right - left) * t;
      final y = surfaceY + math.sin(wavePhase + t * math.pi * 4) * amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(right, h)
      ..lineTo(left, h)
      ..close();
    return path;
  }

  void _drawBubbles(Canvas canvas, double w, double h, double surfaceY) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 3; i++) {
      final t = (progress * 1.4 + i * 0.33) % 1.0;
      final y = surfaceY - t * (surfaceY - h * 0.16);
      final x = w * 0.5 + math.sin(wavePhase * 0.5 + i * 2.1) * w * 0.10;
      final r = w * (0.03 + 0.012 * ((i + 1) % 3));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_FillingDropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.color != color ||
        oldDelegate.reduced != reduced;
  }
}