import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../data/car_attributes_repository.dart';
import '../data/cars_repository.dart';
import '../domain/car_attribute_catalog.dart';
import '../domain/klear_car.dart';

/// Provides the [CarsRepository] (single source of truth).
final carsRepositoryProvider = Provider<CarsRepository>((ref) {
  return CarsRepository();
});

/// Provides the [CarAttributesRepository] (catalog + per-car values).
final carAttributesRepositoryProvider = Provider<CarAttributesRepository>((ref) {
  return CarAttributesRepository();
});

/// The currently signed-in user id (null when signed out).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((auth) => auth.user?.id));
});

/// Asynchronously exposes the visible car-attribute catalog (admin-managed).
/// An empty/unfetchable catalog degrades to today's fixed make/model/plate/size
/// form (size stays first-class; other attributes simply don't render).
final carAttributesCatalogProvider = FutureProvider<List<CarAttribute>>((ref) {
  return ref.watch(carAttributesRepositoryProvider).getVisibleCatalog();
});

/// Asynchronously exposes the current user's cars to the UI, each enriched
/// with its dynamic attribute values and the extra price factor computed from
/// the catalog (so pricing reflects all price-affecting attributes).
final carsProvider = FutureProvider<List<KlearCar>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final carsRepo = ref.watch(carsRepositoryProvider);
  final attrRepo = ref.watch(carAttributesRepositoryProvider);
  final catalog = await attrRepo.getVisibleCatalog();
  final cars = await carsRepo.getMyCars(userId);
  final enriched = <KlearCar>[];
  for (final car in cars) {
    final values = await attrRepo.getCarValues(car.id);
    final factor = attrRepo.computeExtraPriceFactor(values, catalog);
    enriched.add(car.withAttributeValues(values).withExtraPriceFactor(factor));
  }
  return enriched;
});

/// Add a car and refresh the list.
Future<KlearCar> addCar(WidgetRef ref, KlearCar car) async {
  final result = await ref.read(carsRepositoryProvider).addCar(car);
  ref.invalidate(carsProvider);
  return result;
}

/// Update a car and refresh the list.
Future<KlearCar> updateCar(WidgetRef ref, KlearCar car) async {
  final result = await ref.read(carsRepositoryProvider).updateCar(car);
  ref.invalidate(carsProvider);
  return result;
}

/// Delete a car and refresh the list.
Future<void> deleteCar(WidgetRef ref, String carId) async {
  await ref.read(carsRepositoryProvider).removeCar(carId);
  ref.invalidate(carsProvider);
}

/// Set a car as the user's default and refresh the list.
Future<void> setDefaultCar(WidgetRef ref, String userId, String carId) async {
  await ref.read(carsRepositoryProvider).setDefaultCar(userId, carId);
  ref.invalidate(carsProvider);
}

/// Persist a car's dynamic attribute values and refresh the (enriched) list.
Future<void> saveCarAttributes(
  WidgetRef ref,
  String carId,
  Map<String, String> values,
) async {
  await ref.read(carAttributesRepositoryProvider).saveValues(carId, values);
  ref.invalidate(carsProvider);
}
