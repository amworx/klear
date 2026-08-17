import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_address.dart';
import 'addresses_remote_datasource.dart';

/// Repository for the user's address book.
class AddressesRepository {
  AddressesRepository({AddressesRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? const AddressesRemoteDataSource();

  final AddressesRemoteDataSource _dataSource;

  Future<List<UserAddress>> fetchMyAddresses(String userId) =>
      _dataSource.fetchMyAddresses(userId);

  Future<UserAddress> insertAddress(UserAddress address) =>
      _dataSource.insertAddress(address);

  Future<void> deleteAddress(String addressId) =>
      _dataSource.deleteAddress(addressId);

  Future<void> setDefaultAddress(String userId, String addressId) =>
      _dataSource.setDefaultAddress(userId, addressId);
}

/// Provider for the addresses repository.
final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return AddressesRepository();
});