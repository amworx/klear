import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../../features/account/presentation/auth_providers.dart';
import '../../l10n/app_localizations.dart';

/// Derives up-to-two-letter initials from a full name ('?' when empty).
String klearInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Top-bar entry point to the user's profile screen.
///
/// Shown in the app bar of every main screen: renders the signed-in user's
/// initials as a small avatar, or a generic person icon when no profile is
/// loaded yet. Tapping opens the full-screen profile page.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(authProvider).profile;

    return IconButton(
      tooltip: l10n.profile,
      onPressed: () => context.push(KlearRoutes.profile),
      icon: CircleAvatar(
        radius: 15,
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Text(
          klearInitials(profile?.fullName),
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
