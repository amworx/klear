import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/error_suggestions.dart';
import '../data/diagnostics_repository.dart';

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
        // Show a suggested fix for the most recent error at the top.
        LogEntry? latestError;
        for (final e in entries) {
          if (e.level == LogLevel.error) {
            latestError = e;
            break;
          }
        }
        final suggestion = latestError != null
            ? ErrorSuggestions.forError('${latestError.error ?? latestError.message}')
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Diagnostics — Logs'),
            actions: [
              if (entries.isNotEmpty)
                IconButton(
                  tooltip: 'Share with admin',
                  icon: const Icon(Icons.outgoing_mail),
                  onPressed: () => _shareWithAdmin(context, ref, logger),
                ),
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
              : Column(
                  children: [
                    if (suggestion != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Suggested fix',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    suggestion,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ErrorSuggestions.generic,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final e = entries[index];
                          return _LogTile(entry: e);
                        },
                      ),
                    ),
                    if (entries.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _shareWithAdmin(context, ref, logger),
                              icon: const Icon(Icons.outgoing_mail),
                              label: const Text('Share with admin'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

Future<void> _shareWithAdmin(
  BuildContext context,
  WidgetRef ref,
  AppLogger logger,
) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Share with admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe what you were doing when the error happened. The last logs will be sent automatically.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Tapped Sign in → entered email → saw error',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Send'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final description = controller.text.trim();
  String summary = 'User report from Diagnostics';
  for (final e in logger.entries.reversed) {
    if (e.level == LogLevel.error) {
      summary = e.message;
      break;
    }
  }
  if (summary == 'User report from Diagnostics' && logger.entries.isNotEmpty) {
    summary = logger.entries.last.message;
  }
  final logs = logger.exportAsText();

  // Show progress
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending report…')),
    );
  }

  try {
    const repo = DiagnosticsRepository();
    final id = await repo.submitReport(
      errorSummary: summary,
      logs: logs,
      description: description.isEmpty ? null : description,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id != null ? 'Report sent (id ${id.substring(0, 8)})' : 'Report sent'),
      ),
    );
    AppLogger.instance.i('diagnostics', 'user shared report ${id ?? 'no-id'}');
  } catch (e, st) {
    AppLogger.instance.e('diagnostics', 'share failed', e, st);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send: $e'),
        action: SnackBarAction(
          label: 'Copy logs',
          onPressed: () => Clipboard.setData(ClipboardData(text: logs)),
        ),
      ),
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
            if (entry.level == LogLevel.error)
              Builder(builder: (context) {
                final s = ErrorSuggestions.forError('${entry.error ?? entry.message}');
                if (s == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: Theme.of(context).colorScheme.onSecondaryContainer),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
