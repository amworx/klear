import 'package:flutter/material.dart';

import '../../../core/widgets/klear_lottie.dart';
import '../../../l10n/app_localizations.dart';
import 'klear_ripple_scene.dart';

/// Branded splash shown while the persisted session is recovered at startup.
///
/// Full-bleed brand-cyan background (matching the native Android launch
/// screen) with the animated Ripple mark: a white badge holding the cyan
/// drop and concentric ripple rings. The router keeps the user here (via the
/// `isInitializing` gate) until the auth state is fully resolved, so the
/// welcome / profile-setup forms never flash on launch.
class KlearSplashPage extends StatelessWidget {
  const KlearSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const bg = Color(0xFF0E7490); // brand cyan, matches native splash

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: l10n.loading,
            container: true,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KlearLottieAsset(
                    LottieAssets.splash,
                    fallback: const KlearRippleScene(size: 280),
                  ),
                  const SizedBox(height: 28),
                  const _FadeWordmark(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wordmark + tagline that gently fades in once the mark is on screen.
/// Static under reduced-motion.
class _FadeWordmark extends StatefulWidget {
  const _FadeWordmark();

  @override
  State<_FadeWordmark> createState() => _FadeWordmarkState();
}

class _FadeWordmarkState extends State<_FadeWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return FadeTransition(
      opacity: _opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.appTitle,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appTagline,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
