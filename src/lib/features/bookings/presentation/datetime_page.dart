import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../app/app_router.dart';
import '../presentation/booking_providers.dart';

/// Step 3: user picks date and time for the wash.
class DateTimePage extends ConsumerStatefulWidget {
  const DateTimePage({super.key});

  @override
  ConsumerState<DateTimePage> createState() => _DateTimePageState();
}

class _DateTimePageState extends ConsumerState<DateTimePage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bookingDraftProvider);
    if (draft.dateTime != null) {
      _selectedDate = draft.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(draft.dateTime!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final initial = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _updateDraft();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final initial = _selectedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _updateDraft();
    }
  }

  void _updateDraft() {
    if (_selectedDate != null && _selectedTime != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      ref.read(bookingDraftProvider.notifier).setDateTime(dateTime);
    }
  }

  void _goNext() {
    if (_selectedDate != null && _selectedTime != null) {
      _updateDraft();
      context.push(KlearRoutes.bookConfirm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final dateFormat = langCode == 'ar' ? 'yyyy/MM/dd' : 'MMM dd, yyyy';
    final timeFormat = langCode == 'ar' ? 'HH:mm' : 'h:mm a';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selectDateTime)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.selectDate),
              subtitle: _selectedDate != null
                  ? Text(DateFormat(dateFormat).format(_selectedDate!))
                  : Text(
                      l10n.notSelected,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectDate(context),
            ),
            const Divider(height: 1),
            // Time picker
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l10n.selectTime),
              subtitle: _selectedTime != null
                  ? Text(
                      DateFormat(timeFormat).format(
                        DateTime(
                          2024,
                          1,
                          1,
                          _selectedTime!.hour,
                          _selectedTime!.minute,
                        ),
                      ),
                    )
                  : Text(
                      l10n.notSelected,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selectedDate != null && _selectedTime != null
                ? _goNext
                : null,
            child: Text(l10n.continueLabel),
          ),
        ),
      ),
    );
  }
}
