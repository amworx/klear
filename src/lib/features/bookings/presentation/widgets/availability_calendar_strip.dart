import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/day_availability.dart';

/// Horizontal 14-day booking calendar with per-day load dots.
///
/// Isolation note: this is the ONLY file that touches the
/// `easy_date_timeline` package. If the package ever breaks (it is lightly
/// maintained), swap its internals for a hand-rolled ListView without
/// touching the booking flow — the public API below stays stable.
class AvailabilityCalendarStrip extends StatelessWidget {
  const AvailabilityCalendarStrip({
    super.key,
    required this.selectedDay,
    required this.availabilityByDay,
    required this.onSelect,
    this.days = 14,
  });

  /// Currently selected date (time components ignored).
  final DateTime selectedDay;

  /// Load information per date; days without an entry render a neutral dot.
  final Map<DateTime, DayAvailability> availabilityByDay;

  final ValueChanged<DateTime> onSelect;

  /// How many days ahead the strip shows (including today).
  final int days;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final last = _today.add(Duration(days: days - 1));

    return EasyDateTimeLinePicker.itemBuilder(
      firstDate: _today,
      lastDate: last,
      focusedDate: selectedDay,
      itemExtent: 66,
      timelineOptions: const TimelineOptions(height: 104),
      physics: const BouncingScrollPhysics(),
      locale: Locale(langCode),
      itemBuilder: (context, date, isSelected, isDisabled, isToday, onTap) {
        final key = DateTime(date.year, date.month, date.day);
        final avail = availabilityByDay[key];
        return AnimatedPress(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 66,
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayTitle(date, isToday, l10n, langCode),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    DateFormat('MMM', langCode).format(date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  _LoadDot(status: avail?.loadLevel),
                ],
              ),
            ),
          ),
        );
      },
      onDateChange: (date) =>
          onSelect(DateTime(date.year, date.month, date.day)),
    );
  }

  String _dayTitle(
    DateTime date,
    bool isToday,
    AppLocalizations l10n,
    String langCode,
  ) {
    final today = _today;
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return l10n.availTodayTag;
    if (d == tomorrow) return l10n.availTomorrowTag;
    return DateFormat('EEE', langCode).format(date);
  }
}

/// Colored load indicator under each day number.
class _LoadDot extends StatelessWidget {
  const _LoadDot({this.status});

  final SlotStatus? status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, size) = switch (status) {
      SlotStatus.free => (const Color(0xFF16A34A), 7.0),
      SlotStatus.limited => (const Color(0xFFD97706), 7.0),
      SlotStatus.full => (scheme.error, 7.0),
      null => (scheme.outlineVariant, 5.0), // not loaded yet
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
