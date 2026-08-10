import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../services/domain/klear_service.dart';

/// Shows the active services catalog from the repository,
/// handling loading / error / empty states gracefully.
///
/// Cards fade in with a soft stagger; loading shows skeleton placeholders.
class ServicesSection extends ConsumerWidget {
  const ServicesSection({super.key, required this.servicesAsync});

  final AsyncValue<List<KlearService>> servicesAsync;

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
        return StaggerList(
          children: [
            Text(
              l10n.servicesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final service in services) _ServiceCard(service: service),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final KlearService service;

  @override
  Widget build(BuildContext context) {
    // Use localization locale so cards switch with app language.
    final localizations = AppLocalizations.of(context);
    final langCode = localizations.localeName.split('_').first;
    final scheme = Theme.of(context).colorScheme;

    final description = service.descFor(langCode);

    return AnimatedPress(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon tile.
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.local_car_wash,
                  color: scheme.onSecondaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Name + optional description + price.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.nameFor(langCode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (service.durationMin != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localizations.approxMinutes(
                              '${service.durationMin}',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price pill.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${service.basePrice.toStringAsFixed(0)} ${service.currency}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
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