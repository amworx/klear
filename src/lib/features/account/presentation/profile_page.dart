import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/profile_avatar_button.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';

/// User profile screen — opened from the top-bar avatar on every main
/// screen.
///
/// Holds everything tied to the user's identity: contact fields, cars,
/// address book and profile editing. App-wide preferences (language,
/// updates, diagnostics, sign-out) live in the separate Settings screen,
/// reachable from the gear icon in the app bar.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final profile = auth.profile;
    final clientNo = profile?.clientNo ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          // Shortcut to app-wide settings (language, updates, sign-out).
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(KlearRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name.
          Center(
            child: StaggerList(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: scheme.secondaryContainer,
                  child: Text(
                    klearInitials(profile?.fullName),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.displayName ?? '—',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Profile fields.
          Card(
            child: Column(
              children: [
                if (clientNo.isNotEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(l10n.clientIdLabel),
                    subtitle: Text(clientNo),
                  ),
                  const Divider(height: 1),
                ],                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(l10n.phoneNumber),
                  subtitle: Text(profile?.displayPhone ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(l10n.addressLabel),
                  subtitle: Text(
                    profile?.address?.isNotEmpty == true
                        ? profile!.address!
                        : l10n.notSelected,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text(l10n.useCurrentLocation),
                  subtitle: (profile?.lat != null && profile?.lng != null)
                      ? Text('${profile!.lat}, ${profile.lng}')
                      : Text(l10n.notSelected),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // My Cars — register vehicles for the wash team + sizing.
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(l10n.myCars),
              subtitle: Text(l10n.myCarsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(KlearRoutes.myCars),
            ),
          ),
          const SizedBox(height: 16),
          // Address book — manage saved locations for faster booking.
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.addressBookTitle),
              subtitle: Text(l10n.addressBookEmptyHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(KlearRoutes.addressBook),
            ),
          ),
          const SizedBox(height: 16),
          // Theme — light / dark / follow system (user-level preference).
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6_outlined,
                          color: scheme.onSurfaceVariant),
                      const SizedBox(width: 16),
                      Text(l10n.theme,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _ThemeSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Edit profile button.
          OutlinedButton.icon(
            onPressed: () => context.go(KlearRoutes.profileSetup),
            icon: const Icon(Icons.edit),
            label: Text(l10n.editProfile),
          ),
        ],
      ),
    );
  }
}

/// Light / Dark / System selector bound to [themeControllerProvider].
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeControllerProvider);

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(l10n.themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(l10n.themeDark),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.themeSystem),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) =>
          ref.read(themeControllerProvider.notifier).setMode(selection.first),
      showSelectedIcon: false,
    );
  }
}
