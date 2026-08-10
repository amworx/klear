/// Car size drives the cost estimation factor. Mirrors the database
/// `cars.size` check constraint.
enum KlearCarSize {
  small,
  medium,
  large;

  /// Value stored in the `cars.size` column.
  String get dbValue => name;

  /// Price multiplier applied to the service base price when estimating
  /// the booking cost (small cars wash faster than large ones).
  double get priceFactor {
    switch (this) {
      case KlearCarSize.small:
        return 1.0;
      case KlearCarSize.medium:
        return 1.25;
      case KlearCarSize.large:
        return 1.5;
    }
  }

  static KlearCarSize fromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'small':
        return KlearCarSize.small;
      case 'large':
        return KlearCarSize.large;
      default:
        return KlearCarSize.medium;
    }
  }
}

/// Clean domain model for a user's registered car.
///
/// The washing team uses [make], [model] and [plateNumber] to identify the
/// vehicle when the owner is not present; [size] drives price estimation.
class KlearCar {
  const KlearCar({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.size,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String make;
  final String model;
  final String plateNumber;
  final KlearCarSize size;
  final DateTime? createdAt;

  /// Short display label e.g. "Toyota Corolla".
  String get displayName => '$make $model'.trim();

  /// Parses a row from the `cars` table.
  factory KlearCar.fromMap(Map<String, dynamic> map) => KlearCar(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        make: (map['make'] as String?) ?? '',
        model: (map['model'] as String?) ?? '',
        plateNumber: (map['plate_number'] as String?) ?? '',
        size: KlearCarSize.fromDb(map['size']?.toString()),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'make': make,
        'model': model,
        'plate_number': plateNumber,
        'size': size.dbValue,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Map without the server-generated fields (for insert/update).
  /// `user_id` is included so the RLS insert policy (`auth.uid() = user_id`)
  /// passes; Supabase ignores it on update.
  Map<String, dynamic> toPayload() => {
        'user_id': userId,
        'make': make,
        'model': model,
        'plate_number': plateNumber,
        'size': size.dbValue,
      };
}