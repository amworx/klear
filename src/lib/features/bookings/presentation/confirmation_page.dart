import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../cars/domain/klear_car.dart';
import '../../orders/presentation/orders_providers.dart';
import '../domain/klear_booking.dart';
import '../presentation/booking_providers.dart';
import 'booking_time_labels.dart';
import 'widgets/booking_step_scaffold.dart';

/// Step 4: user reviews all details, sees the cost breakdown and confirms.
/// Persists the booking to Supabase on confirm.
class ConfirmationPage extends ConsumerStatefulWidget {
  const ConfirmationPage({super.key});

  @override
  ConsumerState<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<ConfirmationPage> {
  late final TextEditingController _notesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: ref.read(bookingDraftProvider).notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final draft = ref.read(bookingDraftProvider);
    if (!draft.isComplete) return;

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() => _submitting = true);
    try {
      final editablePayload = <String, dynamic>{
        'service_id': draft.service!.id,
        'car_id': draft.car!.id,
        'address': draft.address,
        'lat': draft.lat,
        'lng': draft.lng,
        'scheduled_at': draft.dateTime!.toIso8601String(),
        'time_type': draft.timeType.dbValue,
        'scheduled_end': draft.scheduledEnd?.toIso8601String(),
        'total_price': draft.estimatedTotalWithSurcharge,
        'note': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (draft.isEditing) {
        await ref.read(bookingRepositoryProvider).updateBooking(
              bookingId: draft.editingBookingId!,
              payload: editablePayload,
              service: draft.service!,
            );
      } else {
        final createPayload = <String, dynamic>{
          ...editablePayload,
          'customer_id': userId,
        };
        await ref
            .read(bookingRepositoryProvider)
            .createBooking(payload: createPayload, service: draft.service!);
      }

      if (!mounted) return;
      final editingId = draft.editingBookingId;
      ref.read(bookingDraftProvider.notifier).clear();
      ref.invalidate(myBookingsProvider);
      setState(() => _submitting = false);
      _showConfirmationDialog(
        context,
        AppLocalizations.of(context),
        editingBookingId: editingId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).bookingFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final draft = ref.watch(bookingDraftProvider);
    final scheme = Theme.of(context).colorScheme;
    final sizeLabel = _sizeLabel(draft.car?.size, langCode, l10n);

    return BookingStepScaffold(
      currentStep: 3,
      title: l10n.reviewAndPay,
      showPriceFooter: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
              trailing: draft.service?.durationMin != null
                  ? Text(
                      l10n.approxMinutes('${draft.service!.durationMin}'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    )
                  : null,
            ),
            _SummaryTile(
              icon: Icons.directions_car_outlined,
              label: l10n.bookingCar,
              value: draft.car != null
                  ? '${draft.car!.displayName} · ${draft.car!.plateNumber}'
                  : '—',
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
                  ? BookingTimeLabels.fullLabel(
                      start: draft.dateTime!,
                      end: draft.scheduledEnd,
                      type: draft.timeType,
                      l10n: l10n,
                      langCode: langCode,
                    )
                  : '—',
            ),
            const SizedBox(height: 8),
            // Notes (optional) — additional details for the wash team.
            TextField(
              controller: _notesController,
              onChanged: (value) =>
                  ref.read(bookingDraftProvider.notifier).setNotes(value),
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.bookingNotes,
                hintText: l10n.bookingNotesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Cost breakdown (Captainz-style transparent pricing).
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      l10n.priceEstimate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(
                      label: l10n.priceBase,
                      value:
                          '${draft.service?.basePrice.toStringAsFixed(0) ?? '0'} '
                          '${draft.service?.currency ?? 'SYP'}',
                    ),
                    _PriceRow(
                      label: l10n.sizeAdjustment,
                      value: draft.car == null
                          ? '—'
                          : '$sizeLabel · ×'
                              '${_formatFactor(draft.car!.size.priceFactor)}',
                    ),
                    if (draft.isUrgent)
                      _PriceRow(
                        label: l10n.urgentSurcharge,
                        value:
                            '+${(urgentSurchargePercent * 100).toStringAsFixed(0)}%',
                      ),
                    const Divider(height: 24),
                    _PriceRow(
                      label: l10n.totalEstimate,
                      value:
                          '${draft.estimatedTotalWithSurcharge.toStringAsFixed(0)} '
                          '${draft.service?.currency ?? 'SYP'}',
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment method — customer commitment step (MVP: cash only).
            Text(
              l10n.paymentMethod,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.primary, width: 2),
              ),
              color: scheme.primaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.payments_outlined,
                  color: scheme.onPrimaryContainer,
                ),
                title: Text(
                  l10n.payOnArrival,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(l10n.payOnArrivalSubtitle),
                trailing: Icon(Icons.check_circle, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                enabled: false,
                leading: const Icon(Icons.credit_card_off_outlined),
                title: Text(l10n.onlinePaymentSoon),
                subtitle: Text(l10n.comingSoon),
                trailing: Icon(
                  Icons.lock_outline,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(bookingDraftProvider.notifier).clear(),
              child: Text(l10n.cancelBooking),
            ),
          ],
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: draft.isComplete && !_submitting ? _submit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              _submitting
                  ? l10n.submitting
                  : draft.isEditing
                      ? l10n.saveChanges
                      : l10n.confirmBooking,
            ),
          ),
        ),
      ),
    );
  }

  String _sizeLabel(KlearCarSize? size, String langCode, AppLocalizations l10n) {
    switch (size) {
      case KlearCarSize.small:
        return l10n.sizeSmall;
      case KlearCarSize.medium:
        return l10n.sizeMedium;
      case KlearCarSize.large:
        return l10n.sizeLarge;
      case null:
        return '—';
    }
  }

  String _formatFactor(double factor) {
    return factor == factor.roundToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);
  }

  void _showConfirmationDialog(
    BuildContext context,
    AppLocalizations l10n, {
    String? editingBookingId,
  }) {
    final isEditing = editingBookingId != null;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.tertiary,
          size: 64,
        ),
        title: Text(isEditing ? l10n.bookingUpdated : l10n.bookingConfirmed),
        content: Text(
          isEditing ? l10n.bookingUpdatedMessage : l10n.bookingConfirmedMessage,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (isEditing) {
                context.go(
                  KlearRoutes.ordersDetail.replaceFirst(
                    ':id',
                    editingBookingId,
                  ),
                );
              } else {
                context.go(KlearRoutes.home);
              }
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
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

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
                if (trailing != null) ...[const SizedBox(height: 2), trailing!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: emphasized
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}