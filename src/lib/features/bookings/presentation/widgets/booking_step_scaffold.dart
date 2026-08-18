import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/settings/domain/app_settings.dart';
import '../../../../features/settings/presentation/settings_provider.dart';
import '../../domain/klear_booking.dart';
import '../booking_providers.dart';

/// Total steps in the simplified booking flow.
const kBookingStepCount = 3;

/// Shared shell for booking screens: back, step progress, optional price footer.
class BookingStepScaffold extends ConsumerWidget {
  const BookingStepScaffold({
    required this.currentStep,
    required this.title,
    required this.body,
    this.bottomBar,
    this.showPriceFooter = true,
    this.priceFooterUrgent = false,
    super.key,
  });

  final int currentStep;
  final String title;
  final Widget body;
  final Widget? bottomBar;
  final bool showPriceFooter;

  /// Live "urgent" selection on the details step — applies the +25% surcharge
  /// to the sticky footer total before the draft is committed.
  final bool priceFooterUrgent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final draft = ref.watch(bookingDraftProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onBack(context, currentStep),
        ),
        title: Text(title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.bookingStepOf('$currentStep', '$kBookingStepCount'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= kBookingStepCount; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsetsDirectional.only(
                            end: i < kBookingStepCount ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: i <= currentStep
                                ? scheme.primary
                                : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: body),
          if (showPriceFooter && draft.service != null)
            BookingPriceFooter(
              draft: draft,
              urgent: priceFooterUrgent,
              settings: settings,
            ),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }

  void _onBack(BuildContext context, int step) {
    switch (step) {
      case 1:
        context.go(KlearRoutes.home);
      case 2:
        context.go(KlearRoutes.bookSelectService);
      case 3:
        context.go(KlearRoutes.bookDetails);
      default:
        context.go(KlearRoutes.home);
    }
  }
}

/// Sticky price summary shown during booking.
class BookingPriceFooter extends StatelessWidget {
  const BookingPriceFooter({
    required this.draft,
    this.urgent = false,
    this.settings,
    super.key,
  });

  final BookingDraft draft;

  /// Live urgent selection — shows the +25% surcharge in the footer total.
  final bool urgent;

  /// Live app settings (admin-configurable pricing). Falls back to defaults
  /// when null (offline/tests).
  final AppSettings? settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final s = settings ?? AppSettings.defaults;
    final hasCar = draft.car != null;
    final surcharge = urgent ? s.urgentSurchargePercent : 0.0;
    final total = (hasCar ? draft.estimatedTotal(s) : draft.service!.basePrice) *
        (1 + surcharge);
    final currency = draft.service!.currency;

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.totalEstimate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '${total.toStringAsFixed(0)} $currency',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (!hasCar)
                      Text(
                        l10n.basePriceNoCar,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              if (draft.service!.durationMin != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.approxMinutes('${draft.service!.durationMin}'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
