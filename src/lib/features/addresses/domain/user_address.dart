/// A saved location in the user's address book.
///
/// Mirrors the `user_addresses` table (RLS-scoped to the owner).
class UserAddress {
  const UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  final String id;
  final String userId;

  /// Short label the user picked, e.g. "Home", "Work", "Gym".
  final String label;

  /// Human-readable address text (reverse-geocoded or user-typed).
  final String address;

  final double lat;
  final double lng;
  final bool isDefault;

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      isDefault: map['is_default'] == true,
    );
  }

  /// Payload for INSERT (server assigns id/created_at).
  Map<String, dynamic> toPayload() {
    return {
      'user_id': userId,
      'label': label,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  UserAddress copyWith({bool? isDefault}) {
    return UserAddress(
      id: id,
      userId: userId,
      label: label,
      address: address,
      lat: lat,
      lng: lng,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}