import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';

/// In-app diagnostics: shows the last ~120 log entries (errors, warnings,
/// workflow steps). Every entry is also mirrored to `adb logcat`, so the
/// workflow can be inspected from the device without retyping long SnackBars.
///
/// Entry point: Account tab → Diagnostics → View logs (also reachable via
/// the SnackBar's "Copy" / "View logs" actions).
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(appLoggerProvider);
    // Rebuild when the logger notifies (ChangeNotifier).
    return AnimatedBuilder(
      animation: logger,
      builder: (context, _) {
        final entries = logger.entries.toList().reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Diagnostics — Logs'),
            actions: [
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Copy all',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: logger.exportAsText()),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logs copied to clipboard')),
                    );
                  },
                ),
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => logger.clear(),
                ),
            ],
          ),
          body: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bug_report_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Errors, warnings and workflow steps appear here. '
                          'Every error SnackBar is also logged, so a long message '
                          'never has to be retyped — just open this screen and copy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return _LogTile(entry: e);
                  },
                ),
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});
  final LogEntry entry;

  Color _levelColor(BuildContext context) {
    switch (entry.level) {
      case LogLevel.error:
        return Theme.of(context).colorScheme.error;
      case LogLevel.warning:
        return Colors.orange.shade700;
      case LogLevel.info:
        return Theme.of(context).colorScheme.primary;
      case LogLevel.debug:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _levelIcon() {
    switch (entry.level) {
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.warning:
        return Icons.warning_amber_outlined;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.debug:
        return Icons.bug_report_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_levelIcon(), size: 16, color: _levelColor(context)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _levelColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.levelLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _levelColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.tag,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  entry.formattedTime,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: entry.toString()));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Entry copied')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              entry.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (entry.error != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                '${entry.error}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
              ),
            ],
            if (entry.stackTrace != null) ...[
              const SizedBox(height: 4),
              SelectableText(
                '${entry.stackTrace}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                maxLines: 8,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
