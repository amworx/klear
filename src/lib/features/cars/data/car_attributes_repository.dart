import '../domain/car_attribute_catalog.dart';
import 'car_attributes_remote_datasource.dart';

/// Repository = single source of truth for the dynamic car-attribute catalog
/// and per-car values (three-layer rule: UI never talks to the network).
class CarAttributesRepository {
  CarAttributesRepository({CarAttributesRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? const CarAttributesRemoteDataSource();

  final CarAttributesRemoteDataSource _dataSource;

  Future<List<CarAttribute>> getVisibleCatalog() =>
      _dataSource.fetchVisibleCatalog();

  Future<Map<String, String>> getCarValues(String carId) =>
      _dataSource.fetchCarValues(carId);

  /// Persists a car's attribute values. The catalog is re-read so attribute
  /// keys resolve to the ids required by `car_attribute_values.attribute_id`.
  Future<void> saveValues(String carId, Map<String, String> values) async {
    final catalog = await getVisibleCatalog();
    final byKey = {for (final a in catalog) a.key: a};
    await _dataSource.saveCarValues(carId, values, byKey);
  }

  /// Extra price factor = product of the factors of every price-affecting
  /// attribute OTHER than `size` (whose factor is always resolved from
  /// `app_settings`) that has a value resolving to a known option factor.
  ///
  /// A car with no extra price-affecting attributes yields 1.0, so existing
  /// pricing is unchanged.
  double computeExtraPriceFactor(
    Map<String, String> values,
    List<CarAttribute> catalog,
  ) {
    var product = 1.0;
    for (final attr in catalog) {
      if (attr.key == 'size') continue;
      if (!attr.affectsPrice) continue;
      final value = values[attr.key];
      if (value == null || value.isEmpty) continue;
      final factor = attr.factorForValue(value);
      if (factor != null) product *= factor;
    }
    return product;
  }
}
