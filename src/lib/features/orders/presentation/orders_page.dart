import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/app_data_refresh.dart';
import '../../../app/widgets/profile_avatar_button.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookings/domain/klear_booking.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../bookings/presentation/booking_time_labels.dart';
import '../../cars/presentation/cars_providers.dart';
import 'orders_providers.dart';

/// User's booking history (Orders tab), with filter tabs:
/// Current / Finished / Cancelled.
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: OrdersFilter.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navOrders),
        actions: const [ProfileAvatarButton()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.ordersTabCurrent),
            Tab(text: l10n.ordersTabFinished),
            Tab(text: l10n.ordersTabCancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final filter in OrdersFilter.values)
            _OrdersTab(
              filter: filter,
              langCode: langCode,
              l10n: l10n,
            ),
        ],
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({
    required this.filter,
    required this.langCode,
    required this.l10n,
  });

  final OrdersFilter filter;
  final String langCode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.errorLoadingServices, textAlign: TextAlign.center),
        ),
      ),
      data: (bookings) {
        final filtered = bookings.where(filter.matches).toList();
        if (filtered.isEmpty) {
          return _EmptyOrders(
            l10n: l10n,
            title: switch (filter) {
              OrdersFilter.current => l10n.ordersEmptyCurrentTitle,
              OrdersFilter.finished => l10n.ordersEmptyFinishedTitle,
              OrdersFilter.cancelled => l10n.ordersEmptyCancelledTitle,
            },
            subtitle: switch (filter) {
              OrdersFilter.current => l10n.ordersEmptyCurrentSubtitle,
              OrdersFilter.finished => l10n.ordersEmptyFinishedSubtitle,
              OrdersFilter.cancelled => l10n.ordersEmptyCancelledSubtitle,
            },
            onBookNow: () {
              ref.read(bookingDraftProvider.notifier).startNew();
              context.go(KlearRoutes.bookSelectService);
            },
          );
        }
        // "Current" tab groups expired (past their window, never served)
        // bookings first with an alert so they are no longer presented as
        // upcoming; the remaining active bookings follow normally.
        final expired = OrdersFilter.current == filter
            ? filtered.where((b) => b.isExpired).toList()
            : const <KlearBooking>[];
        final active = OrdersFilter.current == filter
            ? filtered.where((b) => !b.isExpired).toList()
            : filtered;

        return RefreshIndicator(
          onRefresh: () => refreshAppData(ref),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: expired.length + active.length,
            itemBuilder: (context, index) {
              final isExpiredCard = index < expired.length;
              final booking = isExpiredCard ? expired[index] : active[index - expired.length];
                  final child = isExpiredCard
                      ? _ExpiredOrderCard(
                          booking: booking,
                          langCode: langCode,
                          l10n: l10n,
                          onTap: () => context.go(
                            KlearRoutes.ordersDetail
                                .replaceFirst(':id', booking.id),
                          ),
                          onReschedule: () => _startReschedule(
                            context,
                            ref,
                            booking,
                          ),
                          onCancel: () => _confirmCancel(
                            context,
                            ref,
                            l10n,
                            booking,
                          ),
                        )
                      : _OrderCard(
                          booking: booking,
                          langCode: langCode,
                          l10n: l10n,
                          onTap: () => context.go(
                            KlearRoutes.ordersDetail
                                .replaceFirst(':id', booking.id),
                          ),
                        );
              return Entrance(
                delay: Duration(milliseconds: 40 * index),
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({
    required this.l10n,
    required this.title,
    required this.subtitle,
    required this.onBookNow,
  });

  final AppLocalizations l10n;
  final String title;
  final String subtitle;
  final VoidCallback onBookNow;

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
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onBookNow,
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
    required this.onTap,
  });

  final KlearBooking booking;
  final String langCode;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              if (booking.isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: scheme.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.expiringSoonBanner,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      BookingTimeLabels.fullLabel(
                        start: booking.dateTime,
                        end: booking.scheduledEnd,
                        type: booking.timeType,
                        l10n: l10n,
                        langCode: langCode,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
      BookingStatus.accepted => (
          l10n.statusAccepted,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      BookingStatus.onTheWay => (
          l10n.statusOnTheWay,
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

/// A booking whose scheduled window passed without being served. Shown with a
/// prominent alert style and direct actions (reschedule / cancel) so the
/// customer can resolve an expired booking instead of it silently lingering.
class _ExpiredOrderCard extends StatelessWidget {
  const _ExpiredOrderCard({
    required this.booking,
    required this.langCode,
    required this.l10n,
    required this.onTap,
    required this.onReschedule,
    required this.onCancel,
  });

  final KlearBooking booking;
  final String langCode;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: scheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.error, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.service.nameFor(langCode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.expiredBookingBanner,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                BookingTimeLabels.fullLabel(
                  start: booking.dateTime,
                  end: booking.scheduledEnd,
                  type: booking.timeType,
                  l10n: l10n,
                  langCode: langCode,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onReschedule,
                      icon: const Icon(Icons.schedule_outlined, size: 18),
                      label: Text(l10n.rescheduleBookingAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(l10n.cancelOrderAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reschedules an expired booking: for editable statuses (pending/accepted)
/// we update the existing booking's time (professional "reschedule"); for
/// en-route/in-progress we rebook a fresh one. Prefills service/car/address
/// so the customer only picks a new time.
void _startReschedule(
  BuildContext context,
  WidgetRef ref,
  KlearBooking booking,
) {
  final canEditExisting = booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.accepted;
  if (canEditExisting) {
    final cars = ref.read(carsProvider).valueOrNull ?? const [];
    final car = cars.where((c) => c.id == booking.carId).firstOrNull;
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
  } else {
    // Fallback: create a fresh booking with the same details.
    ref.read(bookingDraftProvider.notifier).startNew();
    ref.read(bookingDraftProvider.notifier).setService(booking.service);
    ref.read(bookingDraftProvider.notifier).setAddress(booking.address);
    ref.read(bookingDraftProvider.notifier).setLatLng(booking.lat, booking.lng);
    ref.read(bookingDraftProvider.notifier).setNotes(booking.notes);
  }
  context.go(KlearRoutes.bookSelectService);
}

/// Confirms and cancels an expired booking; falls back to an error snack bar.
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
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cancelFailed)),
    );
  }
}