import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../../home/presentation/widgets/services_section.dart';
import '../../services/presentation/services_providers.dart';

/// Browse-the-catalog page (third tab). Surfaces the same services data as
/// the Home tab but in a dedicated browsing surface so users can see all
/// services without scrolling past hero content.
class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navServices)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.servicesTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ServicesSection(
                servicesAsync: servicesAsync,
                onBookService: (service) {
                  ref.read(bookingDraftProvider.notifier).setService(service);
                  context.go(KlearRoutes.bookDetails);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
