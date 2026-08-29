import 'dart:math' as math;

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
    this.serviceCenterLat,
    this.serviceCenterLng,
    this.serviceRadiusKm,
  });

  /// Fallback values — keep in sync with the DB seed row.
  /// Defaults to Afrin (Aleppo) 36.5114,36.8681 radius 15km for phased rollout.
  static const defaults = AppSettings(
    sizeSmallFactor: 1.0,
    sizeMediumFactor: 1.25,
    sizeLargeFactor: 1.5,
    urgentSurchargePct: 25,
    serviceHoursStart: '08:00',
    serviceHoursEnd: '18:00',
    currency: 'SYP',
    serviceCenterLat: 36.5114,
    serviceCenterLng: 36.8681,
    serviceRadiusKm: 15,
  );

  final double sizeSmallFactor;
  final double sizeMediumFactor;
  final double sizeLargeFactor;

  /// Urgent surcharge expressed as a percentage (25 = +25%).
  final double urgentSurchargePct;

  final String serviceHoursStart;
  final String serviceHoursEnd;
  final String currency;

  /// Service area center (Afrin for now). Null = no restriction.
  final double? serviceCenterLat;
  final double? serviceCenterLng;

  /// Service radius in km. Null or <=0 = unrestricted.
  final int? serviceRadiusKm;

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

  /// Whether the service area restriction is active (center + radius set).
  bool get hasServiceArea =>
      serviceCenterLat != null &&
      serviceCenterLng != null &&
      (serviceRadiusKm ?? 0) > 0;

  /// Haversine distance from service center to [lat]/[lng] in km.
  double distanceToCenterKm(double lat, double lng) {
    if (!hasServiceArea) return 0;
    return _haversineKm(serviceCenterLat!, serviceCenterLng!, lat, lng);
  }

  /// Whether [lat]/[lng] is within the configured service radius. Null
  /// coordinates are treated as outside when a service area is active (forces
  /// the user to pick a pin on the map).
  bool isWithinServiceArea(double? lat, double? lng) {
    if (!hasServiceArea) return true;
    if (lat == null || lng == null) return false;
    return distanceToCenterKm(lat, lng) <= (serviceRadiusKm ?? 0);
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double toRad(double d) => d * math.pi / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

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
        serviceCenterLat: (map['service_center_lat'] as num?)?.toDouble() ??
            defaults.serviceCenterLat,
        serviceCenterLng: (map['service_center_lng'] as num?)?.toDouble() ??
            defaults.serviceCenterLng,
        serviceRadiusKm: (map['service_radius_km'] as num?)?.toInt() ??
            defaults.serviceRadiusKm,
      );
}