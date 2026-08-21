import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/language_tile.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import 'auth_providers.dart';

/// Account / profile tab (fourth tab).
/// - Authenticated: shows profile (name, phone, location) + sign-out button.
/// - Unauthenticated: shows "Guest user" + sign-in button.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) {
      return _GuestView(l10n: l10n);
    }
    return Column(
      children: [
        Expanded(
          child: _ProfileView(auth: auth, l10n: l10n, ref: ref),
        ),
        const LanguageTile(),
      ],
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccount)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: StaggerList(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 44,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.accountGuest,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                l10n.signInToBook,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(KlearRoutes.signIn),
                child: Text(l10n.signInTitle),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push(KlearRoutes.logs),
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Diagnostics — View logs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.auth,
    required this.l10n,
    required this.ref,
  });

  final AuthState auth;
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name.
          Center(
            child: StaggerList(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    _initials(profile?.fullName),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
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
                ListTile(
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
          // Diagnostics — in-app log viewer for errors & workflow.
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Diagnostics'),
              subtitle: const Text('View error & workflow logs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(KlearRoutes.logs),
            ),
          ),
          const SizedBox(height: 16),
          // Edit profile button.
          OutlinedButton.icon(
            onPressed: () => context.go(KlearRoutes.profileSetup),
            icon: const Icon(Icons.edit),
            label: Text(l10n.editProfile),
          ),
          const SizedBox(height: 12),
          // Sign-out.
          TextButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(KlearRoutes.welcome);
            },
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            label: Text(
              l10n.signOut,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
