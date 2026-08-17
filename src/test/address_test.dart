// Tests for the address book feature: model mapping + repository delegation.
import 'package:flutter_test/flutter_test.dart';

import 'package:klear/features/addresses/data/addresses_remote_datasource.dart';
import 'package:klear/features/addresses/data/addresses_repository.dart';
import 'package:klear/features/addresses/domain/user_address.dart';

const _home = UserAddress(
  id: 'addr-1',
  userId: 'u-1',
  label: 'Home',
  address: 'Damascus, Al-Mazzeh',
  lat: 33.5138,
  lng: 36.2765,
  isDefault: true,
);

void main() {
  test('UserAddress.fromMap parses a full row from the user_addresses table',
      () {
    final parsed = UserAddress.fromMap(const {
      'id': 'addr-1',
      'user_id': 'u-1',
      'label': 'Home',
      'address': 'Damascus, Al-Mazzeh',
      'lat': 33.5138,
      'lng': 36.2765,
      'is_default': true,
    });

    expect(parsed.id, 'addr-1');
    expect(parsed.userId, 'u-1');
    expect(parsed.label, 'Home');
    expect(parsed.address, 'Damascus, Al-Mazzeh');
    expect(parsed.lat, 33.5138);
    expect(parsed.lng, 36.2765);
    expect(parsed.isDefault, isTrue);
  });

  test('UserAddress.fromMap tolerates missing optional fields', () {
    final parsed = UserAddress.fromMap(const {
      'id': 'addr-2',
      'user_id': 'u-2',
      'label': 'Work',
      'address': 'Aleppo',
    });

    expect(parsed.lat, 0);
    expect(parsed.lng, 0);
    expect(parsed.isDefault, isFalse);
  });

  test('toPayload produces the INSERT payload the table expects', () {
    final payload = _home.toPayload();

    expect(payload['user_id'], 'u-1');
    expect(payload['label'], 'Home');
    expect(payload['address'], 'Damascus, Al-Mazzeh');
    expect(payload['lat'], 33.5138);
    expect(payload['lng'], 36.2765);
    expect(payload['is_default'], isTrue);
    // Server-owned fields must NOT be sent.
    expect(payload.containsKey('id'), isFalse);
    expect(payload.containsKey('created_at'), isFalse);
  });

  test('copyWith only replaces the requested field', () {
    final updated = _home.copyWith(isDefault: false);

    expect(updated.id, 'addr-1');
    expect(updated.label, 'Home');
    expect(updated.address, 'Damascus, Al-Mazzeh');
    expect(updated.isDefault, isFalse);
    // Original is immutable.
    expect(_home.isDefault, isTrue);
  });

  test('fetchMyAddresses delegates to the datasource', () async {
    final fake = _FakeAddressesDataSource();
    final repo = AddressesRepository(dataSource: fake);

    final result = await repo.fetchMyAddresses('u-1');

    expect(fake.fetchedUserIds, ['u-1']);
    expect(result, [_home]);
  });

  test('insertAddress delegates to the datasource and returns the row',
      () async {
    final fake = _FakeAddressesDataSource();
    final repo = AddressesRepository(dataSource: fake);

    final saved = await repo.insertAddress(_home);

    expect(fake.inserted, [_home]);
    expect(saved.id, 'addr-1');
  });

  test('deleteAddress and setDefaultAddress delegate to the datasource',
      () async {
    final fake = _FakeAddressesDataSource();
    final repo = AddressesRepository(dataSource: fake);

    await repo.deleteAddress('addr-1');
    expect(fake.deletedIds, ['addr-1']);

    await repo.setDefaultAddress('u-1', 'addr-2');
    expect(fake.defaultCalls, [('u-1', 'addr-2')]);
  });
}

class _FakeAddressesDataSource implements AddressesRemoteDataSource {
  final fetchedUserIds = <String>[];
  final inserted = <UserAddress>[];
  final deletedIds = <String>[];
  final defaultCalls = <(String, String)>[];

  @override
  Future<List<UserAddress>> fetchMyAddresses(String userId) async {
    fetchedUserIds.add(userId);
    return const [_home];
  }

  @override
  Future<UserAddress> insertAddress(UserAddress address) async {
    inserted.add(address);
    return address;
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    deletedIds.add(addressId);
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    defaultCalls.add((userId, addressId));
  }
}