import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import '../presentation/booking_providers.dart';

/// Step 2: user picks which car to wash.
class CarSelectionPage extends ConsumerWidget {
  const CarSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final carsAsync = ref.watch(carsProvider);
    final draft = ref.watch(bookingDraftProvider);
    final scheme = Theme.of(context).colorScheme;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectCar)),
      body: carsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorLoadingServices)),
        data: (cars) {
          if (cars.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 72,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.carsEmptyTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noCarsAddPrompt,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push(KlearRoutes.carAdd),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addCar),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              final isSelected = draft.car?.id == car.id;
              return Entrance(
                delay: Duration(milliseconds: 60 * index),
                child: AnimatedPress(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isSelected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isSelected
                          ? BorderSide(color: scheme.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.onPrimaryContainer
                              : scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: isSelected
                              ? scheme.primaryContainer
                              : scheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(car.displayName),
                      subtitle: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _sizeLabel(car.size, langCode, l10n),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Plate numbers are always LTR digits/letters.
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                car.plateNumber,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: scheme.primary)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        ref.read(bookingDraftProvider.notifier).setCar(car);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: draft.car != null
                ? () => context.go(KlearRoutes.bookLocation)
                : null,
            child: Text(l10n.continueLabel),
          ),
        ),
      ),
    );
  }

  String _sizeLabel(KlearCarSize size, String langCode, AppLocalizations l10n) {
    switch (size) {
      case KlearCarSize.small:
        return l10n.sizeSmall;
      case KlearCarSize.medium:
        return l10n.sizeMedium;
      case KlearCarSize.large:
        return l10n.sizeLarge;
    }
  }
}