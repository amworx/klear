import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

/// Centralized Lottie asset paths for the branded animations.
///
/// Drop the corresponding `.json` files into `assets/lottie/` and they will
/// automatically replace the built-in fallback animations — no other code
/// changes required.
class LottieAssets {
  const LottieAssets._();

  /// Full-bleed brand animation for the startup splash.
  static const String splash = 'assets/lottie/splash.json';

  /// Hero animation for the unauthenticated welcome screen.
  static const String welcome = 'assets/lottie/welcome.json';

  /// Per-step hero animations for the new-user onboarding flow.
  static const List<String> onboarding = [
    'assets/lottie/onboarding_1.json',
    'assets/lottie/onboarding_2.json',
    'assets/lottie/onboarding_3.json',
  ];
}

/// Renders a Lottie animation from an asset while gracefully degrading.
///
/// If the asset is missing (e.g. not yet sourced), this falls back to
/// [fallback] so the screen always renders and the build never breaks while
/// assets are being collected. Respects the platform reduced-motion setting by
/// showing the first frame instead of looping.
class KlearLottieAsset extends StatelessWidget {
  const KlearLottieAsset(
    this.assetPath, {
    super.key,
    this.fallback,
    this.animate,
    this.repeat = true,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final Widget? fallback;
  final bool? animate;
  final bool repeat;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return FutureBuilder<String>(
      // Probing the asset via the bundle lets us fall back cleanly when the
      // file has not been added yet, without surfacing Lottie's error UI.
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.trim().isNotEmpty) {
          return Lottie.asset(
            assetPath,
            animate: animate ?? !reduced,
            repeat: repeat,
            fit: fit,
            // If the asset is present but malformed, degrade to the fallback
            // rather than surfacing Lottie's error UI.
            errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
          );
        }
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
