import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../presentation/booking_providers.dart';

/// Step 4: user reviews all details and confirms the booking.
class ConfirmationPage extends ConsumerWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final draft = ref.watch(bookingDraftProvider);
    final dateFormat = DateFormat(
      langCode == 'ar' ? 'yyyy/MM/dd HH:mm' : 'MMM dd, yyyy h:mm a',
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmBooking)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.bookingSummary,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _SummaryTile(
              icon: Icons.local_car_wash,
              label: l10n.serviceLabel,
              value: draft.service?.nameFor(langCode) ?? '—',
            ),
            _SummaryTile(
              icon: Icons.location_on_outlined,
              label: l10n.addressLabel,
              value: draft.address ?? '—',
            ),
            _SummaryTile(
              icon: Icons.schedule_outlined,
              label: l10n.dateTimeLabel,
              value: draft.dateTime != null
                  ? dateFormat.format(draft.dateTime!)
                  : '—',
            ),
            _SummaryTile(
              icon: Icons.payments_outlined,
              label: l10n.totalPrice,
              value:
                  '${draft.estimatedTotal.toStringAsFixed(0)} ${draft.service?.currency ?? 'SYP'}',
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => ref.read(bookingDraftProvider.notifier).clear(),
              child: Text(l10n.cancelBooking),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: draft.isComplete
                ? () {
                    // TODO: submit booking to Supabase (P4).
                    // For now, clear the draft and show the success dialog.
                    ref.read(bookingDraftProvider.notifier).clear();
                    _showConfirmationDialog(context, l10n);
                  }
                : null,
            icon: const Icon(Icons.check_circle),
            label: Text(l10n.confirm),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.tertiary,
          size: 64,
        ),
        title: Text(l10n.bookingConfirmed),
        content: Text(l10n.bookingConfirmedMessage),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Pop all booking pages back to the home shell.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
