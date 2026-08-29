/// Catalog of dynamic car attributes (admin-managed via the Klear Control
/// Center). Mirrors the `car_attributes` table.
///
/// Each attribute is either free text or a select wrapped around a list of
/// options; a price-affecting attribute carries an optional per-option
/// `factor` used to scale the booking estimate.
library;

/// Storage/rendering type of an attribute.
enum CarAttrDataType {
  text,
  select;

  static CarAttrDataType fromDb(String? value) =>
      value == 'select' ? CarAttrDataType.select : CarAttrDataType.text;
}

/// One selectable value of a `select` attribute.
class CarAttributeOption {
  const CarAttributeOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
    this.factor,
  });

  /// Stored value (e.g. `red`).
  final String value;
  final String labelAr;
  final String labelEn;

  /// Price multiplier for this option, when its attribute affects price.
  final double? factor;

  factory CarAttributeOption.fromJson(Map<String, dynamic> json) =>
      CarAttributeOption(
        value: json['value']?.toString() ?? '',
        labelAr: json['label_ar']?.toString() ?? '',
        labelEn: json['label_en']?.toString() ?? '',
        factor: (json['factor'] as num?)?.toDouble(),
      );

  /// Localized option label.
  String label(String langCode) =>
      langCode == 'ar' && labelAr.isNotEmpty ? labelAr : (labelEn.isNotEmpty ? labelEn : value);
}

/// A dynamic car attribute definition from the catalog.
class CarAttribute {
  const CarAttribute({
    required this.id,
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.dataType,
    required this.options,
    this.isVisible = true,
    this.isRequired = false,
    this.affectsPrice = false,
    this.isSystem = false,
    this.tooltipAr,
    this.tooltipEn,
  });

  final String id;
  final String key;
  final String labelAr;
  final String labelEn;
  final CarAttrDataType dataType;
  final List<CarAttributeOption> options;
  final bool isVisible;
  final bool isRequired;
  final bool affectsPrice;
  final bool isSystem;
  final String? tooltipAr;
  final String? tooltipEn;

  factory CarAttribute.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = <CarAttributeOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map) {
          options.add(CarAttributeOption.fromJson(Map<String, dynamic>.from(o)));
        }
      }
    }
    return CarAttribute(
      id: map['id']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
      labelAr: map['label_ar']?.toString() ?? '',
      labelEn: map['label_en']?.toString() ?? '',
      dataType: CarAttrDataType.fromDb(map['data_type']?.toString()),
      options: options,
      isVisible: map['is_visible'] != false,
      isRequired: map['is_required'] == true,
      affectsPrice: map['affects_price'] == true,
      isSystem: map['is_system'] == true,
      tooltipAr: (map['tooltip_ar'] as String?)?.trim().isEmpty == true
          ? null
          : map['tooltip_ar']?.toString(),
      tooltipEn: (map['tooltip_en'] as String?)?.trim().isEmpty == true
          ? null
          : map['tooltip_en']?.toString(),
    );
  }

  /// Localized attribute label.
  String label(String langCode) =>
      langCode == 'ar' && labelAr.isNotEmpty ? labelAr : (labelEn.isNotEmpty ? labelEn : key);

  /// Localized tooltip/description when the admin has set one; null otherwise.
  String? tooltip(String langCode) {
    final v = langCode == 'ar' ? tooltipAr : tooltipEn;
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  /// Price factor for a stored value, when this attribute affects price and
  /// the value resolves to a known option with a factor; null otherwise.
  double? factorForValue(String value) {
    if (!affectsPrice) return null;
    for (final option in options) {
      if (option.value == value) return option.factor;
    }
    return null;
  }

  /// Localized label for a stored value (used in read-only display).
  String labelForValue(String value, String langCode) {
    for (final option in options) {
      if (option.value == value) return option.label(langCode);
    }
    return value;
  }
}
