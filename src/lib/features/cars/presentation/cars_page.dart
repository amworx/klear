import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/car_attribute_catalog.dart';
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

    // Visible non-system catalog attributes, used to render a car's dynamic
    // attribute values as chips (raw values shown for select lookups without
    // a translation is avoided — labels resolve from the catalog).
    final allCatalog =
        ref.watch(carAttributesCatalogProvider).value ?? const <CarAttribute>[];
    final catalog = allCatalog
        .where((a) =>
            !const {'make', 'model', 'plate_number', 'size'}.contains(a.key))
        .toList();
    final attrByKey = {for (final a in allCatalog) a.key: a};
    bool isVisible(String k) => attrByKey[k]?.isVisible ?? true;

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
                                if (isVisible('make') ||
                                    isVisible('model'))
                                  Text(
                                    car.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                if (isVisible('make') ||
                                    isVisible('model'))
                                  const SizedBox(height: 4),
                                // Wrap (not Row): the default-car chip adds
                                // an extra intrinsic-width child on top of
                                // the size chip + plate badge, which used to
                                // overflow narrow rows by a few pixels. A
                                // Wrap flows excess chips onto a new line.
                                // All chips respect is_visible from the admin catalog.
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (isVisible('size'))
                                      _SizeChip(
                                        label: _sizeLabel(
                                            car.size, langCode, l10n),
                                        tooltip: _sizeTooltip(
                                            allCatalog, langCode, l10n, car),
                                      ),
                                    // Dynamic (admin-defined) attribute values.
                                    for (final attr in catalog)
                                      if (car.attributes[attr.key]
                                                  ?.trim()
                                                  .isNotEmpty ??
                                              false)
                                        _AttrChip(
                                          label:
                                              '${attr.label(langCode)}: ${attr.labelForValue(car.attributes[attr.key]!, langCode)}',
                                          tooltip: _attrTooltip(
                                            attr,
                                            car.attributes[attr.key]!,
                                            langCode,
                                            l10n,
                                          ),
                                        ),
                                    if (car.isDefault)
                                      _DefaultChip(label: l10n.defaultCar),
                                    if (isVisible('plate_number'))
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
                            tooltip: l10n.setDefaultCar,
                            onPressed: car.isDefault
                                ? null
                                : () => setDefaultCar(ref, car.userId, car.id),
                            icon: Icon(
                              car.isDefault
                                  ? Icons.star
                                  : Icons.star_border,
                              color: car.isDefault
                                  ? Colors.amber
                                  : scheme.onSurfaceVariant,
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

  /// Extra context for a car's dynamic attribute chip. Repeats the label/value
  /// (useful on long/truncated chips) and, for price-affecting attributes,
  /// notes the price impact (with the option factor when one is known).
  /// When the admin has set a per-attribute tooltip (tooltip_ar/en), that
  /// custom text is shown first (it explains the attribute to the customer);
  /// the generated label/value and price factor are appended for context.
  String _attrTooltip(
    CarAttribute attr,
    String value,
    String langCode,
    AppLocalizations l10n,
  ) {
    final custom = attr.tooltip(langCode);
    final base = custom != null && custom.isNotEmpty
        ? custom
        : '${attr.label(langCode)}: ${attr.labelForValue(value, langCode)}';
    // If the admin wrote a custom tooltip for a price-affecting attribute,
    // keep it but surface the pricing impact alongside it.
    final prefix = custom != null && custom.isNotEmpty ? base : base;
    if (!attr.affectsPrice) return prefix;
    final factor = attr.factorForValue(value);
    if (factor == null) return '$prefix · ${l10n.attrAffectsPrice}';
    return '$prefix · ${l10n.attrAffectsPrice} ×${_formatFactor(factor)}';
  }

  String _sizeTooltip(
    List<CarAttribute> allCatalog,
    String langCode,
    AppLocalizations l10n,
    KlearCar car,
  ) {
    for (final a in allCatalog) {
      if (a.key == 'size') {
        final custom = a.tooltip(langCode);
        if (custom != null && custom.isNotEmpty) {
          return '$custom · ${l10n.sizeAdjustment} ×${_formatFactor(car.size.priceFactor)}';
        }
        break;
      }
    }
    return '${l10n.sizeAdjustment} ×${_formatFactor(car.size.priceFactor)}';
  }

  String _formatFactor(double factor) {
    return factor == factor.roundToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);
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
  const _SizeChip({required this.label, this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Container(
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
    final t = tooltip;
    if (t == null || t.isEmpty) return chip;
    return Tooltip(message: t, child: chip);
  }
}

class _DefaultChip extends StatelessWidget {
  const _DefaultChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: Colors.amber.shade800),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip({required this.label, this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
    final t = tooltip;
    if (t == null || t.isEmpty) return chip;
    return Tooltip(message: t, child: chip);
  }
}