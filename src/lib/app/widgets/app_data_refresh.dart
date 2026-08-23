import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/presentation/orders_providers.dart';
import '../../features/services/presentation/services_providers.dart';
import '../../features/settings/presentation/settings_provider.dart';

/// Pull-to-refresh data reload for the main screens.
///
/// Re-fetches everything the dashboard surfaces from the admin side:
/// the services catalog (badges / discounts / prices), the user's bookings
/// (status changes) and app settings (hours, surcharge). Availability
/// capacity is intentionally not included — the booking flow re-validates it
/// on every entry.
Future<void> refreshAppData(WidgetRef ref) async {
  ref.invalidate(servicesProvider);
  ref.invalidate(myBookingsProvider);
  // Settings reload never throws (falls back to current state on failure).
  await ref.read(appSettingsProvider.notifier).reload();
  try {
    await Future.wait([
      ref.read(servicesProvider.future),
      ref.read(myBookingsProvider.future),
    ]);
  } catch (_) {
    // Provider errors surface through their AsyncError states in the UI;
    // the RefreshIndicator just needs the future to settle.
  }
}
