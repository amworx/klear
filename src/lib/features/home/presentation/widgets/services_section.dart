import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../services/domain/klear_service.dart';
import '../../../services/presentation/widgets/featured_service_hero.dart';
import '../../../services/presentation/widgets/service_merch.dart';

/// Shows the active services catalog from the repository,
/// handling loading / error / empty states gracefully.
///
/// Layout (approved Option A): the featured service renders as a full-width
/// gradient HERO card; every other service sits in a horizontal snap RAIL
/// of compact cards below it. Tapping either starts booking that service.
class ServicesSection extends ConsumerWidget {
  const ServicesSection({
    super.key,
    required this.servicesAsync,
    this.onBookService,
    this.mostUsedServiceId,
  });

  final AsyncValue<List<KlearService>> servicesAsync;
  final void Function(KlearService service)? onBookService;

  /// When set (booking-insights argmax), the matching rail card shows an
  /// automatic "most ordered" badge — but only when no admin badge exists
  /// (admin badges always win).
  final String? mostUsedServiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return servicesAsync.when(
      loading: () => const _SkeletonList(),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.errorLoadingServices,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
      data: (services) {
        if (services.isEmpty) {
          return Center(
            child: Text(
              l10n.noServices,
              textAlign: TextAlign.center,
            ),
          );
        }
        // Hero = first 'popular'-badged service (else the first one);
        // everything else joins the rail.
        final featured = KlearService.featuredOf(services);
        final rest =
            services.where((s) => s.id != featured.id).toList();

        return StaggerList(
          children: [
            Text(
              l10n.servicesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FeaturedServiceHero(
              service: featured,
              onBook: onBookService == null
                  ? null
                  : () => onBookService!(featured),
            ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.allServices,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              _MiniRail(
                services: rest,
                onBook: onBookService == null
                    ? null
                    : (s) => onBookService!(s),
                mostUsedServiceId: mostUsedServiceId,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Horizontal rail of compact service cards (everything but the hero).
class _MiniRail extends StatelessWidget {
  const _MiniRail({required this.services, this.onBook, this.mostUsedServiceId});

  final List<KlearService> services;
  final void Function(KlearService service)? onBook;
  final String? mostUsedServiceId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Tall enough for the worst-case stack: badge + icon + name +
      // duration + discounted price row + struck original (verified by
      // services_mini_overflow_test.dart).
      height: 186,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _MiniCard(
          service: services[i],
          onBook: onBook,
          isMostUsed: services[i].id == mostUsedServiceId,
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.service, this.onBook, this.isMostUsed = false});

  final KlearService service;
  final void Function(KlearService service)? onBook;

  /// Shows the auto "most ordered" badge when no admin badge is set.
  final bool isMostUsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = l10n.localeName.split('_').first;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 172,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onBook == null ? null : () => onBook!(service),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(13),
            // Fixed-size tiles: clamp user font scaling so the known
            // worst-case stack (badge+duration+discount) always fits.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.0,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single badge slot ABOVE the icon (stacked layout — a
                // side-by-side row overflows: measured 'أفضل قيمة' badge
                // is ~131px wide vs 146px inner card width).
                // Admin badge wins; auto "most ordered" only when absent.
                if (service.badgeKey != null)
                  ServiceBadge(service: service)
                else if (isMostUsed)
                  ServiceBadge.auto(
                    customIcon: Icons.history_rounded,
                    customLabel: l10n.mostOrdered,
                  )
                else
                  const SizedBox.shrink(),
                SizedBox(height:
                    service.badgeKey != null || isMostUsed ? 9 : 0),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.local_car_wash,
                    color: scheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  service.nameFor(langCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (service.durationMin != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.approxMinutes('${service.durationMin}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '${service.finalPrice.toStringAsFixed(0)} ${service.currency}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: service.hasDiscount
                                  ? const Color(0xFF15803D)
                                  : scheme.onSurface,
                            ),
                      ),
                    ),
                    if (service.hasDiscount) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '-${service.discountPercent}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: scheme.onErrorContainer,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (service.hasDiscount)
                  Text(
                    '${service.basePrice.toStringAsFixed(0)} ${service.currency}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static skeleton placeholders shown while services load.
///
/// No infinite shimmer — finishes instantly so tests/accessibility stay
/// stable while still communicating "content is coming".
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = scheme.surfaceContainerHighest;

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: placeholder,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar(140, 22),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: placeholder,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(180, 16),
                        const SizedBox(height: 8),
                        bar(110, 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  bar(76, 32),
                ],
              ),
            ),
          ),
      ],
    );
  }
}