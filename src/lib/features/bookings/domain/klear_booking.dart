import '../../cars/domain/klear_car.dart';
import '../../services/domain/klear_service.dart';
import '../../settings/domain/app_settings.dart';

/// Booking status enum mirrors the database `booking_status` type.
enum BookingStatus {
  /// Reservation created, no captain assigned yet.
  pending,

  /// A captain accepted/claimed the job (assigned).
  accepted,

  /// The captain is on their way to the wash point.
  onTheWay,

  /// The wash is in progress.
  inProgress,

  completed,
  cancelled,
}

/// How flexible the scheduled time is. Mirrors the database `time_type`
/// column on the `bookings` table.
enum TimeWindowType {
  /// "Anytime 8am-6pm" — the whole working day is open.
  allDay,

  /// A specific 4-hour window (e.g. 8am-12pm, 10am-2pm, 2pm-6pm).
  window,

  /// "Anytime today" — urgent, carries a +25% surcharge.
  urgent;

  /// Value stored in the `bookings.time_type` column (snake_case, matches the
  /// DB check constraint `('all_day','window','urgent')`).
  String get dbValue => switch (this) {
        TimeWindowType.allDay => 'all_day',
        TimeWindowType.window => 'window',
        TimeWindowType.urgent => 'urgent',
      };
}

/// Clean domain model for a user's booking.
class KlearBooking {
  const KlearBooking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.service,
    required this.address,
    required this.dateTime,
    required this.status,
    required this.createdAt,
    this.carId,
    this.notes,
    this.totalPrice,
    this.lat,
    this.lng,
    this.providerId,
    this.timeType = TimeWindowType.window,
    this.scheduledEnd,
  });

  final String id;
  final String userId;
  final String serviceId;
  final KlearService service;
  final String address;
  final DateTime dateTime;
  final BookingStatus status;
  final DateTime createdAt;
  final String? carId;
  final String? notes;
  final double? totalPrice;

  /// Precise wash-point coordinates (from the map picker), when available.
  final double? lat;
  final double? lng;

  /// The captain (provider) assigned to this booking, when claimed.
  final String? providerId;

  /// The flexibility category of the scheduled time.
  final TimeWindowType timeType;

  /// End of the time window ([dateTime] is the start). Null for legacy
  /// point-in-time bookings (window == start).
  final DateTime? scheduledEnd;

  /// End of the window, defaulting to the start for legacy rows.
  DateTime get windowEnd => scheduledEnd ?? dateTime;

  /// Whether this booking carries the urgent surcharge.
  bool get isUrgent => timeType == TimeWindowType.urgent;

  /// Whether the customer can live-track the captain right now.
  /// Requires an assigned captain AND an active en-route/working state.
  /// The captain must also have wash-point coordinates to show the target.
  bool get canTrack =>
      (status == BookingStatus.onTheWay ||
          status == BookingStatus.inProgress) &&
      providerId != null &&
      lat != null &&
      lng != null;

  /// Returns the localized status label.
  String statusLabel(String langCode) {
    switch (status) {
      case BookingStatus.pending:
        return langCode == 'ar' ? 'قيد الانتظار' : 'Pending';
      case BookingStatus.accepted:
        return langCode == 'ar' ? 'تم قبول الحجز' : 'Accepted';
      case BookingStatus.onTheWay:
        return langCode == 'ar' ? 'الكابتن في الطريق' : 'On the way';
      case BookingStatus.inProgress:
        return langCode == 'ar' ? 'جاري التنفيذ' : 'In Progress';
      case BookingStatus.completed:
        return langCode == 'ar' ? 'مكتمل' : 'Completed';
      case BookingStatus.cancelled:
        return langCode == 'ar' ? 'ملغى' : 'Cancelled';
    }
  }

  /// Parses a row from the `bookings` table.
  factory KlearBooking.fromMap(Map<String, dynamic> map, KlearService service) {
    return KlearBooking(
      id: map['id']?.toString() ?? '',
      userId: map['customer_id']?.toString() ?? map['user_id']?.toString() ?? '',
      serviceId: map['service_id']?.toString() ?? '',
      service: service,
      address: (map['address'] as String?) ?? '',
      dateTime: DateTime.tryParse(map['scheduled_at']?.toString() ?? '') ?? DateTime.now(),
      status: _statusFromString(map['status']?.toString()),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      carId: map['car_id']?.toString(),
      notes: (map['note'] as String?) ?? (map['notes'] as String?),
      totalPrice: (map['total_price'] as num?)?.toDouble(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      providerId: map['provider_id']?.toString(),
      timeType: _timeTypeFromString(map['time_type']?.toString()),
      scheduledEnd: DateTime.tryParse(map['scheduled_end']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': userId,
        'service_id': serviceId,
        'car_id': carId,
        'provider_id': providerId,
        'address': address,
        'lat': lat,
        'lng': lng,
        'scheduled_at': dateTime.toIso8601String(),
        'time_type': timeType.dbValue,
        'scheduled_end': scheduledEnd?.toIso8601String(),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'note': notes,
        'total_price': totalPrice,
      };

  static BookingStatus _statusFromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'accepted':
        return BookingStatus.accepted;
      case 'on_the_way':
        return BookingStatus.onTheWay;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  static TimeWindowType _timeTypeFromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'all_day':
        return TimeWindowType.allDay;
      case 'urgent':
        return TimeWindowType.urgent;
      case 'window':
      default:
        return TimeWindowType.window;
    }
  }
}

/// How the customer will pay for the wash.
enum BookingPaymentMethod {
  /// Cash to the captain when the wash is done (MVP default).
  payOnArrival,
  /// Reserved for a future online payment gateway.
  online,
}

/// Immutable booking draft used during the multi-step booking flow.
/// Holds partial data until the user confirms.
class BookingDraft {
  const BookingDraft({
    this.service,
    this.car,
    this.address,
    this.lat,
    this.lng,
    this.dateTime,
    this.timeType = TimeWindowType.window,
    this.scheduledEnd,
    this.notes,
    this.paymentMethod = BookingPaymentMethod.payOnArrival,
    this.editingBookingId,
  });

  final KlearService? service;
  final KlearCar? car;
  final String? address;

  /// Optional precise coordinates picked on the map (bookings table has
  /// lat/lng columns so the worker can locate the wash point exactly).
  final double? lat;
  final double? lng;

  /// Start of the time window (the moment the user picked).
  final DateTime? dateTime;

  /// Flexibility category of the scheduled time.
  final TimeWindowType timeType;

  /// End of the time window (null for legacy point-in-time drafts).
  final DateTime? scheduledEnd;

  final String? notes;
  final BookingPaymentMethod paymentMethod;

  /// When set, submitting this draft updates the existing booking instead of
  /// creating a new one. Used by the "Edit booking" flow on order details.
  final String? editingBookingId;

  /// Whether this draft is an edit of an existing booking.
  bool get isEditing => editingBookingId != null;

  /// Whether this booking carries the urgent surcharge.
  bool get isUrgent => timeType == TimeWindowType.urgent;

  /// Whether the draft is complete (ready to submit).
  /// [paymentMethod] always has a default value, so completion depends on the
  /// booking essentials: service, car, address and date/time.
  bool get isComplete =>
      service != null &&
      car != null &&
      address != null &&
      address!.isNotEmpty &&
      dateTime != null;

  /// Estimated base price = service discounted price × car-size factor
  /// (admin-configurable via [AppSettings]). Uses [KlearService.finalPrice]
  /// so catalog discounts are REAL — the customer pays less. Does NOT
  /// include the urgent surcharge, so live UI can apply the +25% without
  /// double-counting when editing an already-urgent booking. Falls back to
  /// [AppSettings.defaults] when no settings are supplied (tests / offline).
  double estimatedTotal([AppSettings? settings]) {
    final s = settings ?? AppSettings.defaults;
    // Car-size factor (admin-configurable) × extra price factor (product of
    // all other price-affecting attributes, e.g. vehicle class/color add-ons).
    final sizeFactor = s.priceFactorFor(car?.size ?? KlearCarSize.medium);
    final extra = car?.extraPriceFactor ?? 1.0;
    final base = (service?.finalPrice ?? 0) * sizeFactor * extra;
    return base;
  }

  /// Final estimate including the urgent surcharge when applicable.
  /// This is the value shown on the confirm step and persisted as total_price.
  double estimatedTotalWithSurcharge([AppSettings? settings]) {
    final s = settings ?? AppSettings.defaults;
    return estimatedTotal(s) * (isUrgent ? s.urgentMultiplier : 1);
  }

  /// Estimated duration of the wash (service duration, if known).
  int? get estimatedDurationMin => service?.durationMin;

  BookingDraft copyWith({
    KlearService? service,
    KlearCar? car,
    String? address,
    double? lat,
    double? lng,
    DateTime? dateTime,
    TimeWindowType? timeType,
    DateTime? scheduledEnd,
    String? notes,
    BookingPaymentMethod? paymentMethod,
    String? editingBookingId,
  }) {
    return BookingDraft(
      service: service ?? this.service,
      car: car ?? this.car,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      dateTime: dateTime ?? this.dateTime,
      timeType: timeType ?? this.timeType,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      editingBookingId: editingBookingId ?? this.editingBookingId,
    );
  }
}