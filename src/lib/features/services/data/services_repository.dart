import '../domain/klear_service.dart';
import 'services_remote_datasource.dart';

/// Repository = single source of truth for the services feature.
/// Decouples UI/Logic from the network datasource (three-layer rule:
/// UI never talks to the network).
class ServicesRepository {
  ServicesRepository({ServicesRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? const ServicesRemoteDataSource();

  final ServicesRemoteDataSource _dataSource;

  Future<List<KlearService>> getActiveServices() => _dataSource.fetchServices();
}