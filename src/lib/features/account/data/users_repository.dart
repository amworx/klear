import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_service.dart';
import '../domain/klear_user.dart';

/// Repository for user profiles (single source of truth).
class UsersRepository {
  UsersRepository();

  /// Fetch the current user's profile.
  Future<KlearUser?> getProfile(String userId) async {
    if (!SupabaseClientManager.isReady) return null;

    final response = await SupabaseClientManager.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return KlearUser.fromMap(Map<String, dynamic>.from(response));
  }

  /// Create or update the user's profile.
  Future<KlearUser> upsertProfile(KlearUser profile) async {
    if (!SupabaseClientManager.isReady) {
      throw StateError('Supabase is not configured');
    }

    final response = await SupabaseClientManager.instance.client
        .from('profiles')
        .upsert(profile.toMap())
        .select()
        .single();

    return KlearUser.fromMap(Map<String, dynamic>.from(response));
  }
}

/// Provider for the users repository.
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});
