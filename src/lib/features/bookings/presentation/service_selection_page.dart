import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../services/presentation/services_providers.dart';
import 'booking_providers.dart';
import 'widgets/booking_step_scaffold.dart';

/// Step 1: user picks a service from the catalog.
class ServiceSelectionPage extends ConsumerWidget {
  const ServiceSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final draft = ref.watch(bookingDraftProvider);
    final scheme = Theme.of(context).colorScheme;

    return BookingStepScaffold(
      currentStep: 1,
      title: l10n.selectService,
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(l10n.errorLoadingServices)),
        data: (services) {
          if (services.isEmpty) {
            return Center(child: Text(l10n.noServices));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final langCode = Localizations.localeOf(context).languageCode;
              final isSelected = draft.service?.id == service.id;
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
                          Icons.local_car_wash,
                          color: isSelected
                              ? scheme.primaryContainer
                              : scheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(service.nameFor(langCode)),
                      subtitle: Text(
                        '${service.basePrice.toStringAsFixed(0)} ${service.currency}'
                        '${service.durationMin != null ? " · ${l10n.approxMinutes('${service.durationMin}')}" : ''}',
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: scheme.primary)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        ref
                            .read(bookingDraftProvider.notifier)
                            .setService(service);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: draft.service != null
                ? () => context.go(KlearRoutes.bookDetails)
                : null,
            child: Text(l10n.continueLabel),
          ),
        ),
      ),
    );
  }
}
