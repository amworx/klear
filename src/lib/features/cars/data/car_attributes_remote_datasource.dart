import '../../../core/network/supabase_service.dart';
import '../domain/car_attribute_catalog.dart';

/// Remote datasource for the dynamic car-attribute catalog and per-car values,
/// backed by Supabase (`car_attributes` + `car_attribute_values`).
///
/// All methods degrade gracefully (empty catalog / no-op writes) when the
/// tables are not yet available — e.g. before the migration is applied to the
/// live DB — so the app keeps working with the fixed make/model/plate/size
/// fields and emits no user-visible error.
class CarAttributesRemoteDataSource {
  const CarAttributesRemoteDataSource();

  /// Fetches the visible catalog (admin-editable order; invisible attributes
  /// are excluded from the client so they never surface in forms/display).
  Future<List<CarAttribute>> fetchVisibleCatalog() async {
    if (!SupabaseClientManager.isReady) return const [];
    try {
      final rows = await SupabaseClientManager.instance.client
          .from('car_attributes')
          .select()
          .eq('is_visible', true)
          .order('sort_order', ascending: true);
      return rows
          .map((row) => CarAttribute.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      // Table missing / DB not migrated yet / transient error.
      return const [];
    }
  }

  /// Fetches a car's attribute values keyed by attribute key, via a join on
  /// `car_attribute_values.attribute_id -> car_attributes.id`.
  Future<Map<String, String>> fetchCarValues(String carId) async {
    if (!SupabaseClientManager.isReady) return const {};
    try {
      final rows = await SupabaseClientManager.instance.client
          .from('car_attribute_values')
          .select('value, attribute:car_attributes(key)')
          .eq('car_id', carId);

      final result = <String, String>{};
      for (final row in rows) {
        final attr = row['attribute'];
        String? key;
        if (attr is Map) {
          for (final v in attr.values) {
            key = v?.toString();
            break;
          }
        }
        if (key == null || key.isEmpty) continue;
        result[key] = row['value']?.toString() ?? '';
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  /// Persists a car's attribute values. Non-empty values are upserted on
  /// `(car_id, attribute_id)`; empty values delete any stored value so a
  /// cleared field clears the database too. Best-effort: silently ignored if
  /// the table is unavailable.
  Future<void> saveCarValues(
    String carId,
    Map<String, String> values,
    Map<String, CarAttribute> attributesByKey,
  ) async {
    if (!SupabaseClientManager.isReady) return;
    try {
      final client = SupabaseClientManager.instance.client;
      for (final entry in values.entries) {
        final attribute = attributesByKey[entry.key];
        if (attribute == null) continue;
        final value = entry.value.trim();
        if (value.isEmpty) {
          await client
              .from('car_attribute_values')
              .delete()
              .eq('car_id', carId)
              .eq('attribute_id', attribute.id);
        } else {
          await client.from('car_attribute_values').upsert({
            'car_id': carId,
            'attribute_id': attribute.id,
            'value': value,
          }, onConflict: 'car_id,attribute_id');
        }
      }
    } catch (_) {
      // Best-effort persistence; ignore when the schema isn't available.
    }
  }
}
