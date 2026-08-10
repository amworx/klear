import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/klear_car.dart';
import 'cars_providers.dart';

/// My Cars — the user's registered vehicles.
/// The washing team uses make/model/plate to identify the car when the
/// owner is not present; size drives the price estimate.
class CarsPage extends ConsumerWidget {
  const CarsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final carsAsync = ref.watch(carsProvider);
    final scheme = Theme.of(context).colorScheme;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myCars)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(KlearRoutes.carAdd),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCar),
      ),
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
                      l10n.carsEmptySubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Entrance(
                delay: Duration(milliseconds: 60 * index),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push(
                      KlearRoutes.carEdit,
                      extra: car,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.displayName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _SizeChip(
                                      label: _sizeLabel(
                                          car.size, langCode, l10n),
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
                                      // Plate numbers are LTR digits/letters.
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
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.deleteCar,
                            onPressed: () => _confirmDelete(
                              context,
                              l10n,
                              ref,
                              car,
                            ),
                            icon: Icon(
                              Icons.delete_outline,
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
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

  Future<void> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    KlearCar car,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCarConfirmTitle),
        content: Text(l10n.deleteCarConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelBooking),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteCar),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await deleteCar(ref, car.id);
    }
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onTertiaryContainer,
            ),
      ),
    );
  }
}