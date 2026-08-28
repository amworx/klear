import '../../cars/domain/klear_car.dart';

/// Runtime pricing/operations configuration sourced from the `app_settings`
/// table (single row, admin-editable via the Klear Control Center).
///
/// [defaults] mirrors the original hardcoded constants so the app degrades
/// gracefully — offline, unconfigured, or in tests — and stays deterministic.
class AppSettings {
  const AppSettings({
    required this.sizeSmallFactor,
    required this.sizeMediumFactor,
    required this.sizeLargeFactor,
    required this.urgentSurchargePct,
    required this.serviceHoursStart,
    required this.serviceHoursEnd,
    required this.currency,
  });

  /// Fallback values — keep in sync with the DB seed row.
  static const defaults = AppSettings(
    sizeSmallFactor: 1.0,
    sizeMediumFactor: 1.25,
    sizeLargeFactor: 1.5,
    urgentSurchargePct: 25,
    serviceHoursStart: '08:00',
    serviceHoursEnd: '18:00',
    currency: 'SYP',
  );

  final double sizeSmallFactor;
  final double sizeMediumFactor;
  final double sizeLargeFactor;

  /// Urgent surcharge expressed as a percentage (25 = +25%).
  final double urgentSurchargePct;

  final String serviceHoursStart;
  final String serviceHoursEnd;
  final String currency;

  /// Surcharge as a fraction (0.25 for 25%) — matches the legacy constant.
  double get urgentSurchargePercent => urgentSurchargePct / 100;

  /// Multiplier applied to the base when the booking is urgent (1.25).
  double get urgentMultiplier => 1 + urgentSurchargePercent;

  /// Live price factor for a car size (admin-editable).
  double priceFactorFor(KlearCarSize size) {
    switch (size) {
      case KlearCarSize.small:
        return sizeSmallFactor;
      case KlearCarSize.medium:
        return sizeMediumFactor;
      case KlearCarSize.large:
        return sizeLargeFactor;
    }
  }

  /// Combined price factor for a whole car: size factor × the product of
  /// factors of all other price-affecting attributes (extraPriceFactor).
  /// Used for breakdown display so the shown multiplier matches the total.
  double carFactor(KlearCar car) =>
      priceFactorFor(car.size) * car.extraPriceFactor;

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        sizeSmallFactor: (map['size_small_factor'] as num?)?.toDouble() ??
            defaults.sizeSmallFactor,
        sizeMediumFactor: (map['size_medium_factor'] as num?)?.toDouble() ??
            defaults.sizeMediumFactor,
        sizeLargeFactor: (map['size_large_factor'] as num?)?.toDouble() ??
            defaults.sizeLargeFactor,
        urgentSurchargePct: (map['urgent_surcharge_pct'] as num?)?.toDouble() ??
            defaults.urgentSurchargePct,
        serviceHoursStart: (map['service_hours_start'] as String?) ??
            defaults.serviceHoursStart,
        serviceHoursEnd: (map['service_hours_end'] as String?) ??
            defaults.serviceHoursEnd,
        currency: (map['currency'] as String?) ?? defaults.currency,
      );
}