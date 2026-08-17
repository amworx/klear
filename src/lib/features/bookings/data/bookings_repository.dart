import '../../services/domain/klear_service.dart';
import '../domain/klear_booking.dart';
import 'bookings_remote_datasource.dart';

/// Repository = single source of truth for the bookings feature.
class BookingsRepository {
  BookingsRepository({BookingsRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? const BookingsRemoteDataSource();

  final BookingsRemoteDataSource _dataSource;

  Future<KlearBooking> createBooking({
    required Map<String, dynamic> payload,
    required KlearService service,
  }) {
    return _dataSource.createBooking(payload: payload, service: service);
  }

  Future<List<KlearBooking>> getMyBookings({
    required String userId,
    required Map<String, KlearService> servicesById,
  }) {
    return _dataSource.fetchMyBookings(
      userId: userId,
      servicesById: servicesById,
    );
  }

  Future<void> cancelBooking(String bookingId) {
    return _dataSource.cancelBooking(bookingId);
  }

  Future<KlearBooking> updateBooking({
    required String bookingId,
    required Map<String, dynamic> payload,
    required KlearService service,
  }) {
    return _dataSource.updateBooking(
      bookingId: bookingId,
      payload: payload,
      service: service,
    );
  }
}