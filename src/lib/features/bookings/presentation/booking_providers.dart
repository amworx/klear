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

  void setLatLng(double? lat, double? lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void setDateTime(DateTime? dateTime) {
    state = state.copyWith(dateTime: dateTime);
  }

  /// Sets the full time window: start, flexibility type and optional end.
  void setTimeWindow({
    required DateTime dateTime,
    required TimeWindowType timeType,
    DateTime? scheduledEnd,
  }) {
    state = state.copyWith(
      dateTime: dateTime,
      timeType: timeType,
      scheduledEnd: scheduledEnd,
    );
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void setPaymentMethod(BookingPaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Starts editing an existing booking: prefills the draft from the stored
  /// booking (including precise coordinates) and marks it as an edit so the
  /// confirm step updates the row instead of inserting a new one.
  void startEdit({
    required String bookingId,
    required KlearService service,
    required KlearCar? car,
    required String address,
    required DateTime dateTime,
    TimeWindowType timeType = TimeWindowType.window,
    DateTime? scheduledEnd,
    double? lat,
    double? lng,
    String? notes,
  }) {
    state = BookingDraft(
      service: service,
      car: car,
      address: address,
      lat: lat,
      lng: lng,
      dateTime: dateTime,
      timeType: timeType,
      scheduledEnd: scheduledEnd,
      notes: notes,
      paymentMethod: BookingPaymentMethod.payOnArrival,
      editingBookingId: bookingId,
    );
  }

  /// Starts a brand-new booking: clears any leftover edit session.
  void startNew() {
    state = const BookingDraft();
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