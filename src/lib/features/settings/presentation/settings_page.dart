import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/language_tile.dart';
import '../../../app/widgets/profile_avatar_button.dart';
import '../../../core/update/update_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';

/// App settings screen — the fourth bottom-nav tab.
///
/// Holds everything app-wide rather than user-specific: language, update
/// checks, diagnostics and signing out. User identity data lives in the
/// separate Profile screen, opened from the top-bar avatar on every main
/// screen.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: const [ProfileAvatarButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language — Arabic / English.
          const LanguageTile(),
          const SizedBox(height: 16),
          // Update check.
          const UpdateTile(),
          const SizedBox(height: 16),
          // Diagnostics — in-app log viewer for errors & workflow.
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.diagnosticsTitle),
              subtitle: Text(l10n.diagnosticsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(KlearRoutes.logs),
            ),
          ),
          const SizedBox(height: 32),
          // Sign out.
          TextButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(KlearRoutes.welcome);
            },
            icon: Icon(Icons.logout, color: scheme.error),
            label: Text(
              l10n.signOut,
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
