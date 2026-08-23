import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/klear_service.dart';

/// Option-A hero card: the featured service rendered as a full-width
/// cyan→teal gradient banner with translucent badge, big discounted price,
/// struck-through original, rotated discount burst sticker, and a white
/// "Book now" CTA. Mirrors docs/design/services_layout_mockup.html.
class FeaturedServiceHero extends StatelessWidget {
  const FeaturedServiceHero({super.key, required this.service, this.onBook});

  final KlearService service;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Localized badge label for whatever key the featured service carries.
    final String? badgeLabel = switch (service.badgeKey) {
      'popular' => l10n.badgePopular,
      'new' => l10n.badgeNew,
      'best_value' => l10n.badgeBestValue,
      _ => null,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.45, 1],
          colors: [Color(0xFF0C637B), Color(0xFF0E7490), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7490).withValues(alpha: .35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative ambient circles.
            Positioned(
              top: -70,
              left: -60,
              child: _circle(190, Colors.white.withValues(alpha: .09)),
            ),
            Positioned(
              bottom: -50,
              right: -30,
              child: _circle(120, Colors.white.withValues(alpha: .07)),
            ),
            // Discount burst sticker at the inline-end corner.
            if (service.hasDiscount)
              PositionedDirectional(
                top: 12,
                end: 14,
                child: Transform.rotate(
                  angle: -10 * math.pi / 180,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CustomPaint(
                      painter: _BurstPainter(
                        fill: const Color(0xFFFACC15),
                        shadow: Colors.black.withValues(alpha: .2),
                      ),
                      child: Center(
                        child: Text(
                          '-${service.discountPercent}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF7A4D00),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badgeLabel != null) ...[
                    // Translucent badge pill.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    service.nameFor(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.descFor(
                          Localizations.localeOf(context).languageCode,
                        ) ??
                        '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD9F3F8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  service.finalPrice.toStringAsFixed(0),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  service.currency,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                children: [
                                  if (service.hasDiscount)
                                    WidgetSpan(
                                      alignment:
                                          PlaceholderAlignment.middle,
                                      child: Text(
                                        '${service.basePrice.toStringAsFixed(0)} ${service.currency}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: Colors.white70,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  if (service.durationMin != null)
                                    TextSpan(
                                      text:
                                          '  ·  ${l10n.approxMinutes('${service.durationMin}')}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFFD9F3F8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: onBook,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0C637B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(l10n.bookNow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// 12-point star-burst behind the discount percentage, matching the
/// CSS clip-path polygon in the approved mockup.
class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.fill, required this.shadow});

  final Color fill;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * 0.82;
    final path = Path();
    const points = 12;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = i * math.pi / points;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawShadow(path, shadow, 4, false);
    canvas.drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.shadow != shadow;
}

