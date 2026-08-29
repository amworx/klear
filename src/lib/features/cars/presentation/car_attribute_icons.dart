import 'package:flutter/material.dart';

import '../domain/car_attribute_catalog.dart';

/// Picks a descriptive Material icon for a (possibly admin-created) car
/// attribute by matching its stable `key` and localized labels against a set
/// of well-known naming keywords (English + Arabic).
///
/// This lets the UI "recognise" a new custom attribute — e.g. an admin adds
/// `fuel` / `الوقود` and the form renders a fuel-pump icon instead of the
/// generic text/list icon. Unknown attributes fall back to a per-type default.
IconData iconForCarAttribute(CarAttribute attr, String langCode) {
  final haystack = _normalize([
    attr.key,
    attr.labelAr,
    attr.labelEn,
  ]);

  // Ordered most-specific first so a match wins over a generic one.
  final table = <(List<String>, IconData)>[
    // Fuel / energy type.
    (
      ['fuel', 'petrol', 'gas', 'diesel', 'electric', 'hybrid', 'بنزين', 'وقود', 'ديزل', 'كهرباء', 'محروقات'],
      Icons.local_gas_station_outlined,
    ),
    // Transmission / gearbox.
    (
      ['gear', 'transmission', 'gearbox', 'shift', 'auto', 'manual', 'ناقل', 'قير', 'جير', 'اوتماتيك', 'أوتوماتيك', 'ناقل حركة'],
      Icons.settings_input_component_outlined,
    ),
    // Year / model year / age.
    (
      ['year', 'model_year', 'age', 'سنة', 'عام', 'موديل', 'سنة الصنع', 'السنة'],
      Icons.event_outlined,
    ),
    // Odometer / mileage.
    (
      ['mileage', 'odometer', 'km', 'kilometer', 'kilometre', 'distance', 'عداد', 'مسافة', 'كيلومتر', 'كيلو'],
      Icons.speed_outlined,
    ),
    // Seats / capacity.
    (
      ['seat', 'seats', 'capacity', 'passenger', 'ركاب', 'مقاعد', 'مقعد', 'سعة'],
      Icons.event_seat_outlined,
    ),
    // Engine / motor / capacity (cc).
    (
      ['engine', 'motor', 'cc', 'cilinder', 'cylinder', 'محرك', 'موتور', 'سعة المحرك', 'حصان'],
      Icons.settings_outlined,
    ),
    // Wheels / rims / tires.
    (
      ['wheel', 'wheels', 'rim', 'rims', 'tire', 'tyre', 'tires', 'جنوط', 'عجلات', 'عجلة', 'اطارات', 'إطارات', 'كفرات'],
      Icons.hub_outlined,
    ),
    // Doors.
    (
      ['door', 'doors', 'باب', 'أبواب', 'ابواب'],
      Icons.door_sliding_outlined,
    ),
    // Color (most likely a custom select, like the "اللون" seed).
    (
      ['color', 'colour', 'paint', 'لون', 'اللون', 'طلاء'],
      Icons.palette_outlined,
    ),
    // Body style / type / shape.
    (
      ['body', 'body_type', 'style', 'type', 'shape', 'هيكل', 'شكل', 'نوع الهيكل', 'كاروزيري', 'فئة'],
      Icons.directions_car_outlined,
    ),
    // Interior / cabin / materials.
    (
      ['interior', 'cabin', 'upholstery', 'leather', 'fabric', 'مقصورة', 'داخلي', 'داخلية', 'كسوة', 'جلد', 'قماش'],
      Icons.chair_outlined,
    ),
    // Climate / air conditioning.
    (
      ['air', 'ac', 'climate', 'conditioning', 'تكييف', 'مكيف', 'تبريد', 'هواء'],
      Icons.ac_unit,
    ),
    // Roof / sunroof / panoramic.
    (
      ['roof', 'sunroof', 'panoramic', 'سقف', 'زجاجي', 'بفتحة'],
      Icons.wb_sunny_outlined,
    ),
    // Plate / licence / number.
    (
      ['plate', 'licence', 'license', 'number', 'لوحة', 'رقم لوحة', 'اللوحة'],
      Icons.confirmation_number_outlined,
    ),
    // Extras / packages / trim.
    (
      ['package', 'extra', 'trim', 'accessor', 'كماليات', 'اضافات', 'إضافات', 'باقة', 'فئة'],
      Icons.card_giftcard_outlined,
    ),
  ];

  for (final (keywords, icon) in table) {
    for (final kw in keywords) {
      if (haystack.contains(_normalize([kw]))) return icon;
    }
  }

  // Fallback by type.
  return attr.dataType == CarAttrDataType.select
      ? Icons.list_alt_outlined
      : Icons.edit_outlined;
}

/// Normalizes a list of strings for keyword matching: lowercase, and drops
/// spaces / diacritics so "Model Year", "model_year" and "السنة" all match.
String _normalize(List<String> parts) {
  final joined = parts.join(' ').toLowerCase();
  // Remove Arabic tashkeel (diacritics) and common punctuation.
  return joined
      .replaceAll(RegExp('[\\u064B-\\u065F]'), '')
      .replaceAll(RegExp('[^a-z0-9\u0600-\u06FF]'), '');
}
