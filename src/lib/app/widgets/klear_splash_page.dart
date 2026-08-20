import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'klear_drop_loader.dart';

/// Branded splash shown while the persisted session is recovered at startup.
///
/// Uses the brand primary color as a full-bleed background so the transition
/// from the native Android launch screen (same color + white circle brand
/// mark) is seamless. The router keeps the user here (via the `isInitializing`
/// gate) until the auth state is fully resolved, so the welcome /
/// profile-setup forms never flash on launch.
class KlearSplashPage extends StatelessWidget {
  const KlearSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: l10n.loading,
            container: true,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand mark + loader: the water drop fills up with an
                  // oscillating wave surface and rising bubbles.
                  const KlearDropLoader(size: 120),
                  const SizedBox(height: 32),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
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