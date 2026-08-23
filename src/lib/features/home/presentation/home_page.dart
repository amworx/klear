import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/widgets/app_data_refresh.dart';
import '../../../app/widgets/profile_avatar_button.dart';
import '../../../core/update/update_banner.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../bookings/domain/booking_insights.dart';
import '../../bookings/domain/klear_booking.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../bookings/presentation/booking_time_labels.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import '../../orders/presentation/orders_providers.dart';
import '../../services/presentation/services_providers.dart';
import 'widgets/services_section.dart';

/// Home / landing screen for Klear.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final auth = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final upcoming = ref
        .watch(myBookingsProvider)
        .valueOrNull
        ?.where((b) =>
            b.windowEnd.isAfter(DateTime.now()) &&
            (b.status == BookingStatus.pending ||
                b.status == BookingStatus.confirmed))
        .toList()
        ?..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    // T3 personalization: favorite-service badge + one-tap rebooking.
    final insights = ref.watch(bookingInsightsProvider);
    final cars = ref.watch(carsProvider).valueOrNull ?? const <KlearCar>[];
    // Book again is offered when the last booking's service is still active.
    final rebookDraft = (insights?.lastBooking != null)
        ? BookingInsights.rebookDraft(
            insights!.lastBooking!,
            activeServices: servicesAsync.valueOrNull ?? const [],
            car: cars
                .where((c) => c.id == insights.lastBooking!.carId)
                .firstOrNull,
          )
        : null;

    return Scaffold(
      // Transparent app bar keeps the hero look while giving the profile
      // avatar exactly the same actions-slot geometry as the other tabs —
      // without it the avatar sat inline in the scroll content and visibly
      // jumped when switching screens.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: const [ProfileAvatarButton()],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshAppData(ref),
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero: gradient brand mark.
                    const Entrance(child: _BrandMark()),
                  const SizedBox(height: 32),
                  Entrance(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      auth.hasProfile
                          ? '${l10n.homeWelcome}، ${auth.profile!.fullName ?? ''}!'
                          : l10n.homeWelcome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      l10n.appTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const UpdateBanner(),
                  const SizedBox(height: 8),
                  // Primary CTA: navigate to booking flow.
                  Entrance(
                    delay: const Duration(milliseconds: 240),
                    child: FilledButton.icon(
                      onPressed: () {
                        ref.read(bookingDraftProvider.notifier).startNew();
                        context.go('/book/service');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.btnBookNow),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Upcoming wash — retention card after a booking.
                  if (upcoming != null && upcoming.isNotEmpty) ...[
                    Entrance(
                      delay: const Duration(milliseconds: 300),
                      child: _UpcomingWashCard(booking: upcoming.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // T3: one-tap rebooking of the last order (≤2 taps).
                  if (rebookDraft != null)
                    Entrance(
                      delay: const Duration(milliseconds: 320),
                      child: _BookAgainCard(
                        draft: rebookDraft,
                        serviceLabel: rebookDraft.service!
                            .nameFor(l10n.localeName.split('_').first),
                      ),
                    ),
                  if ((upcoming != null && upcoming.isNotEmpty) ||
                      rebookDraft != null)
                    const SizedBox(height: 24),
                  // Services catalog — tap a card to book directly.
                  ServicesSection(
                    servicesAsync: servicesAsync,
                    mostUsedServiceId: insights?.mostUsedServiceId,
                    onBookService: (service) {
                      ref.read(bookingDraftProvider.notifier).startNew();
                      ref.read(bookingDraftProvider.notifier).setService(service);
                      context.go(KlearRoutes.bookDetails);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.secondary, scheme.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.water_drop, size: 52, color: Colors.white),
      ),
    );
  }
}

/// T3: one-tap "book again" — prefills the whole draft from the last
/// booking and jumps straight to the confirm step.
class _BookAgainCard extends ConsumerWidget {
  const _BookAgainCard({required this.draft, required this.serviceLabel});

  final BookingDraft draft;
  final String serviceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: () {
          ref.read(bookingDraftProvider.notifier).startNew();
          ref.read(bookingDraftProvider.notifier).setService(draft.service);
          ref.read(bookingDraftProvider.notifier).setCar(draft.car);
          ref.read(bookingDraftProvider.notifier).setAddress(draft.address);
          ref.read(bookingDraftProvider.notifier)
              .setLatLng(draft.lat, draft.lng);
          if (draft.dateTime != null) {
            ref.read(bookingDraftProvider.notifier).setTimeWindow(
                  dateTime: draft.dateTime!,
                  timeType: draft.timeType,
                  scheduledEnd: draft.scheduledEnd,
                );
          }
          context.go(KlearRoutes.bookConfirm);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.onSecondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.replay_rounded,
                  color: scheme.secondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bookAgain,
                      style:
                          Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      serviceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the nearest upcoming booking so the user knows their wash is on
/// the way; tapping opens the booking details.
class _UpcomingWashCard extends StatelessWidget {
  const _UpcomingWashCard({required this.booking});

  final KlearBooking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final langCode = Localizations.localeOf(context).languageCode;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: () => context.go(
          KlearRoutes.ordersDetail.replaceFirst(':id', booking.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.onPrimaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.local_car_wash,
                  color: scheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.upcomingWash,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.service.nameFor(langCode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      BookingTimeLabels.fullLabel(
                        start: booking.dateTime,
                        end: booking.scheduledEnd,
                        type: booking.timeType,
                        l10n: l10n,
                        langCode: langCode,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.viewDetails,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}