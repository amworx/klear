import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/addresses_repository.dart';
import '../domain/user_address.dart';
import '../../account/presentation/auth_providers.dart';

/// Async list of the current user's saved addresses.
///
/// Invalidate this provider after any mutation so the address book and
/// dependent screens stay in sync.
final userAddressesProvider = FutureProvider.autoDispose<List<UserAddress>>(
  (ref) async {
    final user = ref.watch(authProvider).user;
    if (user == null) return const [];
    final repo = ref.watch(addressesRepositoryProvider);
    return repo.fetchMyAddresses(user.id);
  },
);