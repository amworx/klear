/// Car size drives the cost estimation factor. Mirrors the database
/// `cars.size` check constraint.
enum KlearCarSize {
  small,
  medium,
  large;

  /// Value stored in the `cars.size` column.
  String get dbValue => name;

  /// Default price multiplier applied to the service base price when
  /// estimating the booking cost (small cars wash faster than large ones).
  ///
  /// This is the fallback used when no live app settings are available
  /// (offline/tests). The authoritative, admin-editable factors live in the
  /// `app_settings` table and are resolved via AppSettings.priceFactorFor.
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
    this.isDefault = false,
    this.createdAt,
    this.attributes = const {},
    this.extraPriceFactor = 1.0,
  });

  final String id;
  final String userId;
  final String make;
  final String model;
  final String plateNumber;
  final KlearCarSize size;

  /// Whether this car is the user's default (pre-selected when booking).
  /// At most one car per user can be default (DB partial unique index).
  final bool isDefault;
  final DateTime? createdAt;

  /// Dynamic attribute values keyed by attribute key (e.g. {'color': 'red'}).
  /// Stored in the `car_attribute_values` table (NOT in `cars`), so these are
  /// attached by the data layer when the car is loaded. Does not include the
  /// built-in [size], which stays a first-class field.
  final Map<String, String> attributes;

  /// Product of the price factors of every price-affecting attribute OTHER
  /// than [size] (whose factor is always resolved from `app_settings`). The
  /// catalog maps each attribute's selected option value to its factor;
  /// computed at load time. Default 1.0 so cars without extra attributes
  /// price exactly as before.
  final double extraPriceFactor;

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
        isDefault: map['is_default'] == true,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'make': make,
        'model': model,
        'plate_number': plateNumber,
        'size': size.dbValue,
        'is_default': isDefault,
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
        'is_default': isDefault,
      };

  /// Copy with a new [isDefault] value (used by the set-default action).
  KlearCar withDefault(bool value) => KlearCar(
        id: id,
        userId: userId,
        make: make,
        model: model,
        plateNumber: plateNumber,
        size: size,
        isDefault: value,
        createdAt: createdAt,
        attributes: attributes,
        extraPriceFactor: extraPriceFactor,
      );

  /// Copy with attached dynamic attribute values (from `car_attribute_values`).
  KlearCar withAttributeValues(Map<String, String> values) => KlearCar(
        id: id,
        userId: userId,
        make: make,
        model: model,
        plateNumber: plateNumber,
        size: size,
        isDefault: isDefault,
        createdAt: createdAt,
        attributes: values,
        extraPriceFactor: extraPriceFactor,
      );

  /// Copy with a recomputed extra price factor (product of non-size
  /// price-affecting attribute factors).
  KlearCar withExtraPriceFactor(double factor) => KlearCar(
        id: id,
        userId: userId,
        make: make,
        model: model,
        plateNumber: plateNumber,
        size: size,
        isDefault: isDefault,
        createdAt: createdAt,
        attributes: attributes,
        extraPriceFactor: factor,
      );
}

/// Picks the car the booking flow should pre-select: the user's default car
/// when one exists, otherwise the first car in the list (null when empty).
KlearCar? preferredCar(List<KlearCar> cars) {
  if (cars.isEmpty) return null;
  for (final car in cars) {
    if (car.isDefault) return car;
  }
  return cars.first;
}