import '../../../core/network/supabase_service.dart';
import '../domain/klear_car.dart';

/// Remote datasource for user cars backed by Supabase.
class CarsRemoteDataSource {
  const CarsRemoteDataSource();

  Future<List<KlearCar>> fetchMyCars(String userId) async {
    if (!SupabaseClientManager.isReady) return const [];

    final response = await SupabaseClientManager.instance.client
        .from('cars')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response
        .map((row) => KlearCar.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<KlearCar> insertCar(KlearCar car) async {
    if (!SupabaseClientManager.isReady) {
      throw StateError('Supabase is not configured');
    }

    final response = await SupabaseClientManager.instance.client
        .from('cars')
        .insert(car.toPayload())
        .select()
        .single();

    return KlearCar.fromMap(Map<String, dynamic>.from(response));
  }

  Future<KlearCar> updateCar(KlearCar car) async {
    if (!SupabaseClientManager.isReady) {
      throw StateError('Supabase is not configured');
    }

    final response = await SupabaseClientManager.instance.client
        .from('cars')
        .update(car.toPayload())
        .eq('id', car.id)
        .select()
        .single();

    return KlearCar.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> deleteCar(String carId) async {
    if (!SupabaseClientManager.isReady) return;

    await SupabaseClientManager.instance.client
        .from('cars')
        .delete()
        .eq('id', carId);
  }
}