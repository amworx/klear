/// Clean domain model for a car-wash service.
class KlearService {
  const KlearService({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descAr,
    this.descEn,
    required this.basePrice,
    required this.currency,
    this.durationMin,
  });

  /// Fallback used when a booking references a service that is no longer
  /// in the catalog.
  static const unknown = KlearService(
    id: '',
    nameAr: 'غير معروف',
    nameEn: 'Unknown',
    basePrice: 0,
    currency: 'SYP',
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final String? descAr;
  final String? descEn;
  final double basePrice;
  final String currency;

  /// Estimated duration of the wash in minutes (Captainz-style display).
  final int? durationMin;

  /// Returns the localized name. Callers pass the current language code.
  String nameFor(String langCode) =>
      langCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  String? descFor(String langCode) {
    if (langCode == 'ar') return descAr;
    return descEn;
  }

  /// Parses a row from the `services` table.
  factory KlearService.fromMap(Map<String, dynamic> map) => KlearService(
        id: map['id']?.toString() ?? '',
        nameAr: (map['name_ar'] as String?) ?? '',
        nameEn: (map['name_en'] as String?) ?? '',
        descAr: map['desc_ar'] as String?,
        descEn: map['desc_en'] as String?,
        basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
        currency: (map['currency'] as String?) ?? 'SYP',
        durationMin: map['duration_min'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'desc_ar': descAr,
        'desc_en': descEn,
        'base_price': basePrice,
        'currency': currency,
        'duration_min': durationMin,
      };
}