import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../services/presentation/services_providers.dart';
import 'widgets/services_section.dart';

/// Home / landing screen for Klear.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(servicesProvider);
    final auth = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero: gradient brand mark.
                  const Entrance(child: _BrandMark()),
                  const SizedBox(height: 32),
                  Entrance(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      auth.hasProfile
                          ? '${l10n.homeWelcome}، ${auth.profile!.fullName ?? ''}!'
                          : l10n.homeWelcome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Entrance(
                    delay: const Duration(milliseconds: 160),
                    child: Text(
                      l10n.appTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Primary CTA: navigate to booking flow.
                  Entrance(
                    delay: const Duration(milliseconds: 240),
                    child: FilledButton.icon(
                      onPressed: () => context.go('/book/service'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.btnBookNow),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Services catalog.
                  ServicesSection(servicesAsync: servicesAsync),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.secondary, scheme.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.water_drop, size: 52, color: Colors.white),
      ),
    );
  }
}