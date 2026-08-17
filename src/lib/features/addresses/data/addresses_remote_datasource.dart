import '../../../core/network/supabase_service.dart';
import '../domain/user_address.dart';

/// Remote datasource for the user's address book backed by Supabase.
class AddressesRemoteDataSource {
  const AddressesRemoteDataSource();

  Future<List<UserAddress>> fetchMyAddresses(String userId) async {
    if (!SupabaseClientManager.isReady) return const [];

    final response = await SupabaseClientManager.instance.client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return response
        .map((row) => UserAddress.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<UserAddress> insertAddress(UserAddress address) async {
    if (!SupabaseClientManager.isReady) {
      throw StateError('Supabase is not configured');
    }

    final response = await SupabaseClientManager.instance.client
        .from('user_addresses')
        .insert(address.toPayload())
        .select()
        .single();

    return UserAddress.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> deleteAddress(String addressId) async {
    if (!SupabaseClientManager.isReady) return;

    await SupabaseClientManager.instance.client
        .from('user_addresses')
        .delete()
        .eq('id', addressId);
  }

  /// Makes [addressId] the user's single default address (clears any previous
  /// one first — the partial unique index enforces one default per user).
  Future<void> setDefaultAddress(String userId, String addressId) async {
    if (!SupabaseClientManager.isReady) return;

    final client = SupabaseClientManager.instance.client;
    await client
        .from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', userId);
    await client
        .from('user_addresses')
        .update({'is_default': true})
        .eq('id', addressId)
        .eq('user_id', userId);
  }
}