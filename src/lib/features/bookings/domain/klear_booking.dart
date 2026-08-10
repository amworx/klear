import '../../cars/domain/klear_car.dart';
import '../../services/domain/klear_service.dart';

/// Booking status enum mirrors the database `booking_status` type.
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
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

  /// Returns the localized status label.
  String statusLabel(String langCode) {
    switch (status) {
      case BookingStatus.pending:
        return langCode == 'ar' ? 'قيد الانتظار' : 'Pending';
      case BookingStatus.confirmed:
        return langCode == 'ar' ? 'مؤكد' : 'Confirmed';
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
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': userId,
        'service_id': serviceId,
        'car_id': carId,
        'address': address,
        'scheduled_at': dateTime.toIso8601String(),
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'note': notes,
        'total_price': totalPrice,
      };

  static BookingStatus _statusFromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
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
}

/// Immutable booking draft used during the multi-step booking flow.
/// Holds partial data until the user confirms.
class BookingDraft {
  const BookingDraft({
    this.service,
    this.car,
    this.address,
    this.dateTime,
    this.notes,
  });

  final KlearService? service;
  final KlearCar? car;
  final String? address;
  final DateTime? dateTime;
  final String? notes;

  /// Whether the draft is complete (ready to submit).
  bool get isComplete =>
      service != null &&
      car != null &&
      address != null &&
      address!.isNotEmpty &&
      dateTime != null;

  /// Estimated total price = service base price × car-size factor.
  double get estimatedTotal =>
      (service?.basePrice ?? 0) * (car?.size.priceFactor ?? 1.0);

  /// Estimated duration of the wash (service duration, if known).
  int? get estimatedDurationMin => service?.durationMin;

  BookingDraft copyWith({
    KlearService? service,
    KlearCar? car,
    String? address,
    DateTime? dateTime,
    String? notes,
  }) {
    return BookingDraft(
      service: service ?? this.service,
      car: car ?? this.car,
      address: address ?? this.address,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
    );
  }
}