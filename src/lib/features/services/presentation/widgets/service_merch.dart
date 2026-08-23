import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/klear_service.dart';

/// Merchandising chip for a service: localized badge pill ('popular' /
/// 'new' / 'best_value'), or a fully custom auto-generated label (e.g.
/// "most ordered" from booking insights). Renders nothing when a
/// service-backed badge has no known badge key.
class ServiceBadge extends StatelessWidget {
  /// Badge derived from the service's admin-set [KlearService.badgeKey].
  const ServiceBadge({super.key, required this.service})
      : customIcon = null,
        customLabel = null;

  /// Auto badge with explicit content — used for personalization marks
  /// that are not admin-configured.
  const ServiceBadge.auto({
    super.key,
    required this.customIcon,
    required this.customLabel,
  }) : service = null;

  final KlearService? service;
  final IconData? customIcon;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final (IconData?, String?)? merch = customLabel != null
        ? (customIcon, customLabel)
        : switch (service?.badgeKey) {
            'popular' => (Icons.local_fire_department_rounded, l10n.badgePopular),
            'new' => (Icons.fiber_new_rounded, l10n.badgeNew),
            'best_value' => (Icons.verified_rounded, l10n.badgeBestValue),
            _ => null,
          };
    if (merch == null) return const SizedBox.shrink();
    final (icon, label) = merch;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Price display for a service card: shows the discounted price the
/// customer actually pays plus the struck-through original when a real
/// discount is active; otherwise a simple price pill.
class ServicePriceTag extends StatelessWidget {
  const ServicePriceTag({super.key, required this.service});

  final KlearService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priceStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        );

    if (!service.hasDiscount) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${service.basePrice.toStringAsFixed(0)} ${service.currency}',
          style: priceStyle?.copyWith(color: scheme.onPrimaryContainer),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Discounted price the customer pays.
        Text(
          '${service.finalPrice.toStringAsFixed(0)} ${service.currency}',
          style: priceStyle?.copyWith(color: const Color(0xFF15803D)),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "-15%" mini pill.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '-${service.discountPercent}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 5),
            // Original price, struck through.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${service.basePrice.toStringAsFixed(0)} ${service.currency}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
