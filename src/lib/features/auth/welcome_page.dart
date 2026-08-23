import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/language_tile.dart';
import '../../../core/widgets/klear_lottie.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';

/// Welcome screen — shown to unauthenticated users.
///
/// Fixed single-screen layout (never scrolls):
/// - The language switcher is a single icon pinned to the top trailing edge
///   (flips sides automatically in RTL).
/// - The hero animation lives in an [Expanded] slot, so it absorbs whatever
///   height is left after the text and buttons and shrinks gracefully on
///   short viewports instead of overflowing. The Lottie must never size
///   itself from its intrinsic composition (welcome.json is 800×800).
/// - The stagger wave is preserved with explicit [Entrance] delays matching
///   [StaggerList]'s default 70 ms rhythm.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language switcher — single icon, top trailing edge.
                  const Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: LanguageMenuButton(),
                  ),
                  // Hero mark — flexible slot so it shrinks on short screens.
                  // Falls back to the branded gradient disc when no Lottie
                  // asset is provided yet.
                  Expanded(
                    child: Entrance(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: KlearLottieAsset(
                          LottieAssets.welcome,
                          fallback: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [scheme.secondary, scheme.primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      scheme.primary.withValues(alpha: 0.30),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              size: 68,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Entrance(
                    delay: const Duration(milliseconds: 70),
                    child: Text(
                      l10n.welcomeTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      l10n.welcomeSubtitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Entrance(
                    delay: const Duration(milliseconds: 210),
                    child: FilledButton.icon(
                      onPressed: () => context.go(KlearRoutes.signUp),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(l10n.createAccount),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    delay: const Duration(milliseconds: 280),
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(KlearRoutes.signIn),
                      icon: const Icon(Icons.login),
                      label: Text(l10n.signInTitle),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
