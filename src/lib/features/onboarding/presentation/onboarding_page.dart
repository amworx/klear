import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';

/// New-user welcome/onboarding — a 3-step, fully animated showcase shown once
/// after a fresh sign-up. Each step has a bespoke water-themed hero
/// (ripple / wave / shine) that loops, plus staggered text entrance and a
/// parallax hero as the user swipes. Reduced-motion renders a static frame.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  static const int _count = 3;
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _count - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (mounted) context.go(KlearRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final titles = <String>[
      l10n.onboardingStep1Title,
      l10n.onboardingStep2Title,
      l10n.onboardingStep3Title,
    ];
    final bodies = <String>[
      l10n.onboardingStep1Body,
      l10n.onboardingStep2Body,
      l10n.onboardingStep3Body,
    ];
    const heroes = <_HeroKind>[
      _HeroKind.ripple,
      _HeroKind.wave,
      _HeroKind.shine,
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip (top-right; respects RTL automatically).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(l10n.onboardingSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _count,
                itemBuilder: (context, i) => _OnboardingStep(
                  index: i,
                  controller: _pageController,
                  hero: heroes[i],
                  title: titles[i],
                  body: bodies[i],
                ),
              ),
            ),
            _Dots(count: _count, active: _page),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _page < _count - 1
                      ? l10n.onboardingNext
                      : l10n.onboardingGetStarted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding page: parallax hero + staggered title/body.
class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.index,
    required this.controller,
    required this.hero,
    required this.title,
    required this.body,
  });

  final int index;
  final PageController controller;
  final _HeroKind hero;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heroWidget = switch (hero) {
      _HeroKind.ripple => const RippleHero(),
      _HeroKind.wave => const WaveHero(),
      _HeroKind.shine => const ShineHero(),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Parallax: hero scales/fades as it moves away from the viewport
          // center, giving depth to the swipe.
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.page ?? 0.0;
              final offset = (page - index).abs();
              final scale = 1.0 - offset * 0.12;
              final opacity = (1.0 - offset * 0.6).clamp(0.2, 1.0);
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: SizedBox(width: 248, height: 248, child: heroWidget),
          ),
          const SizedBox(height: 44),
          StaggerList(
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Morphing progress dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: i == active ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: i == active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

enum _HeroKind { ripple, wave, shine }

/// Shared teardrop path (tip up), normalized control points matching the
/// brand mark. `s` is the drop's bounding-box side; `c` is its center.
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

/// ---- Hero 1: concentric ripples expanding from a water-drop badge ----
class RippleHero extends StatefulWidget {
  const RippleHero({super.key});

  @override
  State<RippleHero> createState() => _RippleHeroState();
}

class _RippleHeroState extends State<RippleHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
    final scheme = Theme.of(context).colorScheme;
    final t = _reduced ? 0.0 : _controller.value;
    return CustomPaint(
      painter: _RipplePainter(
        t,
        scheme.primary,
        scheme.secondary,
        _reduced,
      ),
      size: const Size(248, 248),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.primary, this.secondary, this.reduced);

  final double t;
  final Color primary;
  final Color secondary;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final badgeR = size.width * 0.26;

    if (!reduced) {
      for (var k = 0; k < 3; k++) {
        _ring(canvas, c, badgeR, (t + k / 3.0) % 1.0, size.width);
      }
    } else {
      _ring(canvas, c, badgeR * 1.35, 0.2, size.width);
    }

    // Badge: primary disc holding a white drop.
    canvas.drawCircle(c, badgeR, Paint()..color = primary);
    final s = badgeR * 1.5;
    canvas.drawPath(_dropPath(c, s), Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(c.dx - s * 0.08, c.dy - s * 0.02),
      s * 0.06,
      Paint()..color = primary.withValues(alpha: 0.85),
    );
  }

  void _ring(
    Canvas canvas,
    Offset c,
    double badgeR,
    double t,
    double w,
  ) {
    final maxR = math.min(badgeR * 2.3, w * 0.46);
    final r = badgeR + (maxR - badgeR) * t;
    final alpha = math.sin(t * math.pi) * 0.5;
    if (alpha <= 0.001) return;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = primary.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.t != t || old.reduced != reduced;
}

/// ---- Hero 2: a rising water wave inside a disc ----
class WaveHero extends StatefulWidget {
  const WaveHero({super.key});

  @override
  State<WaveHero> createState() => _WaveHeroState();
}

class _WaveHeroState extends State<WaveHero>
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
    final scheme = Theme.of(context).colorScheme;
    final t = _reduced ? 0.0 : _controller.value;
    return CustomPaint(
      painter: _WavePainter(t, scheme.primary, scheme.secondary, _reduced),
      size: const Size(248, 248),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t, this.primary, this.secondary, this.reduced);

  final double t;
  final Color primary;
  final Color secondary;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: radius)));

    // Disc background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = primary,
    );

    // Rising water surface.
    final phase = reduced ? 0.0 : t * math.pi * 2;
    final surfaceY = reduced
        ? size.height * 0.45
        : size.height * (0.62 - 0.22 * (math.sin(phase) * 0.5 + 0.5));
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, surfaceY);
    const samples = 44;
    for (var i = 0; i <= samples; i++) {
      final x = size.width * i / samples;
      final y = surfaceY +
          math.sin(phase + i / samples * math.pi * 4) * (size.height * 0.02);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = secondary);

    // Rising bubbles.
    if (!reduced) {
      final bubble = Paint()..color = Colors.white.withValues(alpha: 0.7);
      for (var i = 0; i < 4; i++) {
        final bt = (t + i * 0.25) % 1.0;
        final by = size.height - bt * (size.height - surfaceY);
        final bx = size.width * (0.3 + 0.12 * i) + math.sin(phase + i) * 8;
        canvas.drawCircle(
          Offset(bx, by),
          size.width * 0.018,
          bubble,
        );
      }
    }
    canvas.restore();

    // Soft rim.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02,
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.t != t || old.reduced != reduced;
}

/// ---- Hero 3: a glowing drop with a rotating sparkle ----
class ShineHero extends StatefulWidget {
  const ShineHero({super.key});

  @override
  State<ShineHero> createState() => _ShineHeroState();
}

class _ShineHeroState extends State<ShineHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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
    final scheme = Theme.of(context).colorScheme;
    final t = _reduced ? 0.0 : _controller.value;
    return CustomPaint(
      painter: _ShinePainter(t, scheme.primary, scheme.secondary, _reduced),
      size: const Size(248, 248),
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter(this.t, this.primary, this.secondary, this.reduced);

  final double t;
  final Color primary;
  final Color secondary;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30;

    // Pulsing halo.
    final glow = reduced ? 0.3 : 0.25 + 0.2 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      c,
      radius * 1.7,
      Paint()..color = primary.withValues(alpha: glow * 0.4),
    );

    // Drop.
    final s = radius * 2.0;
    canvas.drawPath(_dropPath(c, s), Paint()..color = primary);

    // Glint.
    canvas.drawCircle(
      Offset(c.dx - s * 0.1, c.dy - s * 0.02),
      s * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Rotating 4-point sparkle.
    final spin = reduced ? 0.0 : t * math.pi * 2;
    final sparkleR = radius * 1.25;
    final sparkle = Paint()..color = secondary.withValues(alpha: 0.9);
    for (var i = 0; i < 4; i++) {
      final a = spin + i * math.pi / 2;
      final inner = sparkleR * 0.18;
      final outer = sparkleR;
      final tip = Offset(c.dx + math.cos(a) * outer, c.dy + math.sin(a) * outer);
      final b1 = Offset(
        c.dx + math.cos(a + 0.35) * inner,
        c.dy + math.sin(a + 0.35) * inner,
      );
      final b2 = Offset(
        c.dx + math.cos(a - 0.35) * inner,
        c.dy + math.sin(a - 0.35) * inner,
      );
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(b1.dx, b1.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(b2.dx, b2.dy)
          ..close(),
        sparkle,
      );
    }
  }

  @override
  bool shouldRepaint(_ShinePainter old) =>
      old.t != t || old.reduced != reduced;
}
