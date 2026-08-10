import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cars/domain/klear_car.dart';
import '../../services/domain/klear_service.dart';
import '../data/bookings_repository.dart';
import '../domain/klear_booking.dart';

/// Provides the [BookingsRepository] (single source of truth).
final bookingRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});

/// Notifier for the multi-step booking flow.
/// Holds a [BookingDraft] that accumulates user input across screens.
class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  BookingDraftNotifier() : super(const BookingDraft());

  void setService(KlearService? service) {
    state = state.copyWith(service: service);
  }

  void setCar(KlearCar? car) {
    state = state.copyWith(car: car);
  }

  void setAddress(String? address) {
    state = state.copyWith(address: address);
  }

  void setDateTime(DateTime? dateTime) {
    state = state.copyWith(dateTime: dateTime);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void clear() {
    state = const BookingDraft();
  }
}

/// Provider for the booking draft state (multi-step form).
final bookingDraftProvider =
    StateNotifierProvider<BookingDraftNotifier, BookingDraft>(
  (ref) => BookingDraftNotifier(),
);