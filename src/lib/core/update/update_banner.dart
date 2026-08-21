import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        // Avoid showing the dialog repeatedly on rebuilds — only once per session.
        // We use a simple flag via the provider's state; the dialog will be
        // dismissed by the user action, but the banner remains.
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Update required'),
            content: Text(
              'A required update is available (${info.latestVersion}). '
              'Please update to continue.\n\n'
              '${info.changelog ?? ''}',
            ),
            actions: [
              FilledButton(
                onPressed: () => ref.read(appUpdateProvider.notifier).launchUpdate(),
                child: const Text('Update now'),
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
                    isForce ? 'Update required' : 'Update available',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isForce
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
                Text(
                  '${state.currentVersion} → ${info.latestVersion}',
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
                    child: const Text('Later'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => ref.read(appUpdateProvider.notifier).launchUpdate(),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Update'),
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
      if (state.isLoading) return 'Checking…';
      if (state.error != null) return 'Could not check for updates';
      if (state.info == null || state.currentVersion == null) return 'Up to date';
      if (state.hasUpdate) {
        return 'Update available: ${state.currentVersion} → ${state.info!.latestVersion}';
      }
      return 'Up to date (${state.currentVersion})';
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.system_update_outlined),
        title: const Text('App updates'),
        subtitle: Text(subtitle()),
        trailing: state.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await ref.read(appUpdateProvider.notifier).check();
          if (!context.mounted) return;
          final s = ref.read(appUpdateProvider);
          if (s.hasUpdate && s.info != null) {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.isForceUpdate ? 'Update required' : 'Update available'),
                content: Text(
                  'Current: ${s.currentVersion}\nLatest: ${s.info!.latestVersion}\n\n'
                  '${s.info!.changelog ?? 'A new version is available.'}',
                ),
                actions: [
                  if (!s.isForceUpdate)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Later'),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Update'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await ref.read(appUpdateProvider.notifier).launchUpdate();
            }
          } else if (s.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are on the latest version')),
            );
          }
        },
      ),
    );
  }
}
