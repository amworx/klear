import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Branded splash shown while the persisted session is recovered at startup.
///
/// Uses the brand primary color as a full-bleed background so the transition
/// from the native Android launch screen (same color + white water drop) is
/// seamless. The router keeps the user here (via the `isInitializing` gate)
/// until the auth state is fully resolved, so the welcome / profile-setup
/// forms never flash on launch.
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
                  // Brand mark: white circle + water drop (mirrors the
                  // native launch screen artwork).
                  Container(
                    width: 96,
                    height: 96,
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
                    child: Icon(
                      Icons.water_drop,
                      size: 56,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onPrimary,
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