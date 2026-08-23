/// Domain model for booking-slot availability.
///
/// Data comes from the `availability_range(from_day, days)` Postgres RPC
/// (see supabase/migrations/20260822_000010_day_availability.sql). The RPC
/// returns one row per day × window with aggregate booked/capacity counts;
/// customers never see other users' bookings.
library;

/// How busy a window/day is.
enum SlotStatus {
  /// At least 2 teams still free.
  free,

  /// Exactly one team left.
  limited,

  /// No capacity left.
  full;

  /// Parses from booked/capacity counts.
  static SlotStatus of({required int booked, required int capacity}) {
    if (capacity <= 0 || booked >= capacity) return SlotStatus.full;
    if (capacity - booked == 1) return SlotStatus.limited;
    return SlotStatus.free;
  }
}

/// Availability for one fixed business-hours window of a specific day.
class WindowSlot {
  const WindowSlot({
    required this.key,
    required this.fromHour,
    required this.toHour,
    required this.booked,
    required this.capacity,
  });

  /// Stable identifier mirroring the DB ('morning' | 'midday' | 'afternoon').
  final String key;

  /// Window start hour in local business time (Asia/Damascus).
  final int fromHour;

  /// Window end hour in local business time.
  final int toHour;

  final int booked;

  /// Teams available that day (from klear-admin provider availability).
  final int capacity;

  SlotStatus get status => SlotStatus.of(booked: booked, capacity: capacity);

  /// Remaining teams, clamped at 0.
  int get remaining =>
      capacity - booked > 0 ? capacity - booked : 0;

  factory WindowSlot.fromMap(Map<String, dynamic> map) => WindowSlot(
        key: (map['window_key'] as String?) ?? '',
        fromHour: _hours[map['window_key']]?.fromHour ?? 8,
        toHour: _hours[map['window_key']]?.toHour ?? 12,
        booked: (map['booked'] as num?)?.toInt() ?? 0,
        capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      );

  static const _hours = <String, ({int fromHour, int toHour})>{
    'morning': (fromHour: 8, toHour: 12),
    'midday': (fromHour: 10, toHour: 14),
    'afternoon': (fromHour: 14, toHour: 18),
  };
}

/// Availability of all windows for one calendar day.
class DayAvailability {
  const DayAvailability({required this.day, required this.slots});

  /// Date-only value (time components are zero).
  final DateTime day;

  /// One entry per business window, ordered by start hour.
  final List<WindowSlot> slots;

  WindowSlot? slot(String key) {
    for (final s in slots) {
      if (s.key == key) return s;
    }
    return null;
  }

  /// Whether every window of the day is fully booked (or capacity is zero).
  bool get allFull => slots.isNotEmpty && slots.every((s) => s.status == SlotStatus.full);

  /// Overall load level used for the calendar-strip dot:
  /// red when nothing bookable, amber when any window is tight, else green.
  SlotStatus get loadLevel {
    if (allFull) return SlotStatus.full;
    if (slots.any((s) => s.status != SlotStatus.free)) return SlotStatus.limited;
    return SlotStatus.free;
  }

  /// Capacity shown in the "N teams available" line (same for every slot of
  /// the day); falls back to the first slot's value.
  int get capacity => slots.isEmpty ? 0 : slots.first.capacity;

  /// Builds one [DayAvailability] per distinct day from raw RPC rows.
  static List<DayAvailability> listFromRows(List<dynamic> rows) {
    final byDay = <DateTime, List<WindowSlot>>{};
    final order = <DateTime>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final day =
          DateTime.tryParse(map['day']?.toString() ?? '') ?? DateTime.now();
      final key = DateTime(day.year, day.month, day.day);
      if (!byDay.containsKey(key)) {
        byDay[key] = [];
        order.add(key);
      }
      byDay[key]!.add(WindowSlot.fromMap(map));
    }
    return [
      for (final d in order)
        DayAvailability(day: d, slots: byDay[d]!..sort((a, b) => a.fromHour.compareTo(b.fromHour))),
    ];
  }
}
