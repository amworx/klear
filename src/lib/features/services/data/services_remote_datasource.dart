import '../../../core/network/supabase_service.dart';
import '../domain/klear_service.dart';

/// Remote datasource for services backed by Supabase.
class ServicesRemoteDataSource {
  const ServicesRemoteDataSource();

  Future<List<KlearService>> fetchServices() async {
    if (!SupabaseClientManager.isReady) return const [];

    final response = await SupabaseClientManager.instance.client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('sort');

    return response
        .map((row) => KlearService.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }
}