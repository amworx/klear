/// Thrown when a phone number is already registered to another account.
class KlearPhoneTakenException implements Exception {
  const KlearPhoneTakenException();
}

/// User profile model for Klear.
class KlearUser {
  const KlearUser({
    required this.id,
    this.fullName,
    this.phone,
    this.clientNo,
    this.lat,
    this.lng,
    this.address,
    this.role = 'customer',
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? phone;

  /// Global, human-friendly sequential client number (e.g. CL-1001).
  /// Assigned by the DB on insert; never written back via toMap.
  final String? clientNo;
  final double? lat;
  final double? lng;
  final String? address;
  final String role;
  final DateTime? createdAt;

  bool get isGuest => fullName == null || fullName!.isEmpty;
  bool get hasLocation => lat != null && lng != null;

  /// Returns a display name: fullName if set, otherwise "Guest".
  String get displayName => fullName?.isNotEmpty == true ? fullName! : 'Guest';

  /// Returns a display phone: phone if set, otherwise "Not set".
  String get displayPhone => phone?.isNotEmpty == true ? phone! : 'Not set';

  /// Parses a row from the `profiles` table.
  factory KlearUser.fromMap(Map<String, dynamic> map) => KlearUser(
        id: map['id']?.toString() ?? '',
        fullName: map['full_name'] as String?,
        phone: map['phone'] as String?,
        clientNo: map['client_no'] as String?,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        address: map['address'] as String?,
        role: (map['role'] as String?) ?? 'customer',
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'address': address,
        'role': role,
      };
}
