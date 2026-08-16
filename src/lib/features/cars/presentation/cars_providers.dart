import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../data/cars_repository.dart';
import '../domain/klear_car.dart';

/// Provides the [CarsRepository] (single source of truth).
final carsRepositoryProvider = Provider<CarsRepository>((ref) {
  return CarsRepository();
});

/// The currently signed-in user id (null when signed out).
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider.select((auth) => auth.user?.id));
});

/// Asynchronously exposes the current user's cars to the UI.
/// Re-fetches when the user changes or after a mutation (invalidate).
final carsProvider = FutureProvider<List<KlearCar>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(carsRepositoryProvider).getMyCars(userId);
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