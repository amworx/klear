import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'klear_drop_loader.dart';

/// Branded splash shown while the persisted session is recovered at startup.
///
/// White background + the animated cyan water drop filling up, matching the
/// native Android launch screen (same colors) so the cold-start transition
/// is seamless. The router keeps the user here (via the `isInitializing`
/// gate) until the auth state is fully resolved, so the welcome /
/// profile-setup forms never flash on launch.
class KlearSplashPage extends StatelessWidget {
  const KlearSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: l10n.loading,
            container: true,
            child: ExcludeSemantics(
              child: const KlearDropLoader(),
            ),
          ),
        ),
      ),
    );
  }
}