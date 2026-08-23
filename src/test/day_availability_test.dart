import 'package:flutter_test/flutter_test.dart';
import 'package:klear/features/bookings/domain/day_availability.dart';

void main() {
  group('WindowSlot.status', () {
    test('capacity 0 means full (unconfigured day-off safety)', () {
      expect(
        SlotStatus.of(booked: 0, capacity: 0),
        SlotStatus.full,
      );
    });

    test('booked >= capacity is full', () {
      expect(SlotStatus.of(booked: 2, capacity: 2), SlotStatus.full);
      expect(SlotStatus.of(booked: 5, capacity: 2), SlotStatus.full);
    });

    test('exactly one remaining is limited', () {
      expect(SlotStatus.of(booked: 1, capacity: 2), SlotStatus.limited);
    });

    test('two or more remaining is free', () {
      expect(SlotStatus.of(booked: 0, capacity: 3), SlotStatus.free);
    });
  });

  group('DayAvailability.listFromRows', () {
    final rows = [
      {'day': '2026-08-22', 'window_key': 'morning', 'booked': 0, 'capacity': 2},
      {'day': '2026-08-22', 'window_key': 'midday', 'booked': 1, 'capacity': 2},
      {'day': '2026-08-22', 'window_key': 'afternoon', 'booked': 2, 'capacity': 2},
      {'day': '2026-08-23', 'window_key': 'morning', 'booked': 0, 'capacity': 2},
      {'day': '2026-08-23', 'window_key': 'midday', 'booked': 0, 'capacity': 2},
      {'day': '2026-08-23', 'window_key': 'afternoon', 'booked': 0, 'capacity': 2},
    ];

    final days = DayAvailability.listFromRows(rows);

    test('groups rows by day preserving order', () {
      expect(days.length, 2);
      expect(days[0].day, DateTime(2026, 8, 22));
      expect(days[1].day, DateTime(2026, 8, 23));
      expect(days[0].slots.length, 3);
    });

    test('slots are ordered by start hour regardless of row order', () {
      final shuffled = [...rows]..shuffle();
      final d = DayAvailability.listFromRows(shuffled).first;
      expect(
        d.slots.map((s) => s.key).toList(),
        ['morning', 'midday', 'afternoon'],
      );
    });

    test('slot statuses derive from counts', () {
      final d = days[0];
      expect(d.slot('morning')!.status, SlotStatus.free);
      expect(d.slot('midday')!.status, SlotStatus.limited);
      expect(d.slot('afternoon')!.status, SlotStatus.full);
    });

    test('loadLevel reflects the busiest signal of the day', () {
      // 22nd: one window still has a spot -> amber (not red).
      expect(days[0].loadLevel, SlotStatus.limited);
      // 23rd: everything free -> green.
      expect(days[1].loadLevel, SlotStatus.free);
    });

    test('allFull only when every window is saturated', () {
      expect(days[0].allFull, isFalse); // midday still has a spot
      expect(days[1].allFull, isFalse);
      final packed = DayAvailability.listFromRows([
        {'day': '2026-08-24', 'window_key': 'morning', 'booked': 3, 'capacity': 2},
        {'day': '2026-08-24', 'window_key': 'midday', 'booked': 1, 'capacity': 1},
        {'day': '2026-08-24', 'window_key': 'afternoon', 'booked': 9, 'capacity': 0},
      ]).first;
      expect(packed.allFull, isTrue);
    });

    test('unknown window keys keep raw values with safe hour fallback', () {
      final weird = DayAvailability.listFromRows([
        {'day': '2026-08-25', 'window_key': 'mystery', 'booked': 0, 'capacity': 4},
      ]).first;
      expect(weird.slots.first.fromHour, 8);
      expect(weird.slots.first.capacity, 4);
    });
  });
}
