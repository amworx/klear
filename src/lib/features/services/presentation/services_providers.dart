import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services_repository.dart';
import '../domain/klear_service.dart';

/// Provides the [ServicesRepository] (single source of truth).
final serviceRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository();
});

/// Asynchronously exposes the active services catalog to the UI.
final servicesProvider = FutureProvider<List<KlearService>>((ref) {
  return ref.watch(serviceRepositoryProvider).getActiveServices();
});