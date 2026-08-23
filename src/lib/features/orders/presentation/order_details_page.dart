import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookings/domain/klear_booking.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../bookings/presentation/booking_time_labels.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import '../../settings/presentation/settings_provider.dart';
import '../presentation/orders_providers.dart';

/// Full details for a single booking, with cancel for pending orders.
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final bookingsAsync = ref.watch(myBookingsProvider);
    final carsAsync = ref.watch(carsProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorLoadingServices)),
        data: (bookings) {
          final booking = _findBooking(bookings, bookingId);
          if (booking == null) {
            return Center(child: Text(l10n.notSelected));
          }
          final car = _findCar(carsAsync.valueOrNull ?? const [], booking.carId);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Status + total header.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.service.nameFor(langCode),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _StatusChip(status: booking.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 4),
              if (booking.totalPrice != null)
                Text(
                  '${booking.totalPrice!.toStringAsFixed(0)} '
                  '${booking.service.currency}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              if (booking.totalPrice != null && car != null) ...[
                const SizedBox(height: 12),
                _Breakdown(
                  basePrice: booking.service.finalPrice,
                  sizeLabel: switch (car.size) {
                    KlearCarSize.small => l10n.sizeSmall,
                    KlearCarSize.medium => l10n.sizeMedium,
                    KlearCarSize.large => l10n.sizeLarge,
                  },
                  factor: settings.priceFactorFor(car.size),
                  total: booking.totalPrice!,
                  currency: booking.service.currency,
                  l10n: l10n,
                ),
              ],
              const SizedBox(height: 16),
              _Tile(
                icon: Icons.directions_car_outlined,
                label: l10n.bookingCar,
                value: car != null
                    ? '${car.displayName} · ${car.plateNumber}'
                    : '—',
                trailing: car != null
                    ? Text(
                        switch (car.size) {
                          KlearCarSize.small => l10n.sizeSmall,
                          KlearCarSize.medium => l10n.sizeMedium,
                          KlearCarSize.large => l10n.sizeLarge,
                        },
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      )
                    : null,
              ),
              _Tile(
                icon: Icons.location_on_outlined,
                label: l10n.addressLabel,
                value: booking.address,
              ),
              _Tile(
                icon: Icons.schedule_outlined,
                label: l10n.dateTimeLabel,
                value: BookingTimeLabels.fullLabel(
                  start: booking.dateTime,
                  end: booking.scheduledEnd,
                  type: booking.timeType,
                  l10n: l10n,
                  langCode: langCode,
                ),
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _Tile(
                  icon: Icons.notes_outlined,
                  label: l10n.bookingNotes,
                  value: booking.notes!,
                ),
              const SizedBox(height: 24),
              if (_canEdit(booking.status) ||
                  booking.status == BookingStatus.pending)
                Row(
                  children: [
                    if (_canEdit(booking.status))
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _startEdit(context, ref, booking, car),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l10n.editOrderAction),
                        ),
                      ),
                    if (booking.status == BookingStatus.pending) ...[
                      if (_canEdit(booking.status)) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _confirmCancel(context, ref, l10n, booking),
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(l10n.cancelOrderAction),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  KlearBooking? _findBooking(List<KlearBooking> bookings, String id) {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  KlearCar? _findCar(List<KlearCar> cars, String? carId) {
    if (carId == null) return null;
    for (final car in cars) {
      if (car.id == carId) return car;
    }
    return null;
  }

  /// Bookings that haven't started can still be edited (change time, car,
  /// address or service). Completed and cancelled ones are read-only.
  bool _canEdit(BookingStatus status) {
    return status == BookingStatus.pending ||
        status == BookingStatus.confirmed;
  }

  /// Prefills the booking draft from the stored booking and opens the booking
  /// flow (step 1) so the user can adjust service, car, address or time.
  void _startEdit(
    BuildContext context,
    WidgetRef ref,
    KlearBooking booking,
    KlearCar? car,
  ) {
    ref.read(bookingDraftProvider.notifier).startEdit(
          bookingId: booking.id,
          service: booking.service,
          car: car,
          address: booking.address,
          dateTime: booking.dateTime,
          timeType: booking.timeType,
          scheduledEnd: booking.scheduledEnd,
          lat: booking.lat,
          lng: booking.lng,
          notes: booking.notes,
        );
    context.go(KlearRoutes.bookSelectService);
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    KlearBooking booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelBooking),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.cancelOrderAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
      ref.invalidate(myBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.orderCancelled)),
      );
      context.go(KlearRoutes.orders);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cancelFailed)),
      );
    }
  }
}

/// Transparent price breakdown for a stored booking (base / size / total).
class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.basePrice,
    required this.sizeLabel,
    required this.factor,
    required this.total,
    required this.currency,
    required this.l10n,
  });

  final double basePrice;
  final String sizeLabel;
  final double factor;
  final double total;
  final String currency;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final factorLabel = factor == factor.roundToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);

    Widget row(String label, String value, {bool emphasized = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: emphasized
                  ? Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row(l10n.priceBase, '${basePrice.toStringAsFixed(0)} $currency'),
            row(l10n.sizeAdjustment, '$sizeLabel · ×$factorLabel'),
            const Divider(height: 20),
            row(
              l10n.totalEstimate,
              '${total.toStringAsFixed(0)} $currency',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.l10n});

  final BookingStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      BookingStatus.pending => (
          l10n.statusPending,
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      BookingStatus.confirmed => (
          l10n.statusConfirmed,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      BookingStatus.inProgress => (
          l10n.statusInProgress,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      BookingStatus.completed => (
          l10n.statusCompleted,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      BookingStatus.cancelled => (
          l10n.statusCancelled,
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}