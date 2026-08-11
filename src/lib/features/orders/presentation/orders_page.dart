import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookings/domain/klear_booking.dart';
import 'orders_providers.dart';

/// User's booking history (Orders tab).
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookingsAsync = ref.watch(myBookingsProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navOrders)),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.errorLoadingServices, textAlign: TextAlign.center),
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return _EmptyOrders(l10n: l10n);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBookingsProvider);
              await ref.read(myBookingsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Entrance(
                  delay: Duration(milliseconds: 40 * index),
                  child: _OrderCard(
                    booking: booking,
                    langCode: langCode,
                    l10n: l10n,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ordersEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ordersEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(KlearRoutes.bookSelectService),
              icon: const Icon(Icons.local_car_wash),
              label: Text(l10n.btnBookNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.booking,
    required this.langCode,
    required this.l10n,
  });

  final KlearBooking booking;
  final String langCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat(
      langCode == 'ar' ? 'yyyy/MM/dd HH:mm' : 'MMM dd, yyyy h:mm a',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.service.nameFor(langCode),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: booking.status, l10n: l10n),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(booking.dateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            if (booking.totalPrice != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${booking.totalPrice!.toStringAsFixed(0)} ${booking.service.currency}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
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
