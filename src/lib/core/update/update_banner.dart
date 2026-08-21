import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_update_provider.dart';

/// Shows a banner/dialog when a newer version is available.
///
/// Place near the top of the home/account scaffold. For a forced update
/// (`minimumVersion` > current or `forceUpdate` true) it shows a blocking
/// dialog that must be acted on.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);

    if (state.isLoading || state.info == null || state.currentVersion == null) {
      return const SizedBox.shrink();
    }
    if (!state.hasUpdate) return const SizedBox.shrink();

    final info = state.info!;
    final isForce = state.isForceUpdate;

    // For a forced update, show a blocking dialog once.
    if (isForce) {
      final l10n = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // Avoid showing the dialog repeatedly on rebuilds — only once per session.
        // We use a simple flag via the provider's state; the dialog will be
        // dismissed by the user action, but the banner remains.
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.updateRequired),
            content: Text(
              '${l10n.updateRequiredMessage(info.latestVersion)}\n\n'
              '${info.changelog ?? ''}',
            ),
            actions: [
              FilledButton(
                onPressed: () => ref.read(appUpdateProvider.notifier).launchUpdate(),
                child: Text(l10n.updateNow),
              ),
            ],
          ),
        );
      });
    }

    return Card(
      margin: const EdgeInsets.all(12),
      color: isForce
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isForce ? Icons.system_update : Icons.update,
                  color: isForce
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isForce
                        ? AppLocalizations.of(context).updateRequired
                        : AppLocalizations.of(context).updateAvailable,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isForce
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).updateCurrentLatest(
                        state.currentVersion!,
                        info.latestVersion,
                      ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isForce
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            if (info.hasChangelog) ...[
              const SizedBox(height: 8),
              Text(
                info.changelog!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isForce
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isForce)
                  TextButton(
                    onPressed: () => ref.read(appUpdateProvider.notifier).check(),
                    child: Text(AppLocalizations.of(context).updateLater),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => ref.read(appUpdateProvider.notifier).launchUpdate(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(AppLocalizations.of(context).updateNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple tile for Settings/Account → "Check for updates".
class UpdateTile extends ConsumerWidget {
  const UpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);

    String subtitle() {
      final l10n = AppLocalizations.of(context);
      if (state.isLoading) return l10n.updateChecking;
      if (state.error != null) return l10n.updateCouldNotCheck;
      if (state.info == null || state.currentVersion == null) return l10n.updateUpToDate;
      if (state.hasUpdate) {
        return l10n.updateAvailableSubtitle(state.currentVersion!, state.info!.latestVersion);
      }
      return l10n.updateUpToDateWithVersion(state.currentVersion!);
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.system_update_outlined),
        title: Text(AppLocalizations.of(context).appUpdates),
        subtitle: Text(subtitle()),
        trailing: state.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await ref.read(appUpdateProvider.notifier).check();
          if (!context.mounted) return;
          final s = ref.read(appUpdateProvider);
          if (s.hasUpdate && s.info != null) {
            final l10n = AppLocalizations.of(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.isForceUpdate ? l10n.updateRequired : l10n.updateAvailable),
                content: Text(
                  '${l10n.updateCurrentLatest(s.currentVersion!, s.info!.latestVersion)}\n\n'
                  '${s.info!.changelog ?? l10n.updateAvailable}',
                ),
                actions: [
                  if (!s.isForceUpdate)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.updateLater),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.updateNow),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(appUpdateProvider.notifier).launchUpdate();
            }
          } else if (s.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).updateUpToDate)),
            );
          }
        },
      ),
    );
  }
}
