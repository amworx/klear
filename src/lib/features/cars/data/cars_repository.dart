import '../domain/klear_car.dart';
import 'cars_remote_datasource.dart';

/// Repository = single source of truth for the cars feature.
/// Decouples UI/Logic from the network datasource (three-layer rule:
/// UI never talks to the network).
class CarsRepository {
  CarsRepository({CarsRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? const CarsRemoteDataSource();

  final CarsRemoteDataSource _dataSource;

  Future<List<KlearCar>> getMyCars(String userId) => _dataSource.fetchMyCars(userId);

  Future<KlearCar> addCar(KlearCar car) => _dataSource.insertCar(car);

  Future<KlearCar> updateCar(KlearCar car) => _dataSource.updateCar(car);

  Future<void> removeCar(String carId) => _dataSource.deleteCar(carId);

  Future<void> setDefaultCar(String userId, String carId) =>
      _dataSource.setDefaultCar(userId, carId);
}