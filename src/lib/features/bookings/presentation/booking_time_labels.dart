import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/klear_booking.dart';

/// Shared time-window display helpers used by the booking flow, order cards,
/// order details and the home "upcoming wash" card so the flexible time
/// choices render consistently everywhere.
class BookingTimeLabels {
  BookingTimeLabels._();

  /// "Anytime 8am-6pm" / "8am-12pm" / "Urgent · anytime today" etc. for a
  /// booking or draft time window.
  static String windowLabel({
    required DateTime start,
    DateTime? end,
    required TimeWindowType type,
    required AppLocalizations l10n,
    required String langCode,
  }) {
    switch (type) {
      case TimeWindowType.allDay:
        return l10n.timeAllDayLabel;
      case TimeWindowType.urgent:
        return l10n.timeUrgentLabel;
      case TimeWindowType.window:
        final endTime = end ?? start;
        return '${_time(start, langCode)} – ${_time(endTime, langCode)}';
    }
  }

  /// Full label including the day, e.g. "2026/08/18 · 8am-12pm" (used on
  /// order cards and details).
  static String fullLabel({
    required DateTime start,
    DateTime? end,
    required TimeWindowType type,
    required AppLocalizations l10n,
    required String langCode,
  }) {
    final day = DateFormat(
      langCode == 'ar' ? 'yyyy/MM/dd' : 'MMM dd, yyyy',
    ).format(start);
    return '$day · ${windowLabel(
      start: start,
      end: end,
      type: type,
      l10n: l10n,
      langCode: langCode,
    )}';
  }

  static String _time(DateTime t, String langCode) {
    // Match the app's existing formats: 24h for Arabic, 12h for English.
    return DateFormat(
      langCode == 'ar' ? 'HH:mm' : 'h:mm a',
    ).format(t);
  }
}