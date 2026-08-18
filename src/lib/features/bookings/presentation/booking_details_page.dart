import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/app_router.dart';
import '../../../core/geocoding/nominatim_service.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../addresses/presentation/map_picker_page.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/klear_booking.dart';
import 'booking_providers.dart';
import 'booking_time_labels.dart';
import 'widgets/booking_step_scaffold.dart';

/// Step 2: car + address + schedule on one screen.
class BookingDetailsPage extends ConsumerStatefulWidget {
  const BookingDetailsPage({super.key});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

/// The flexibility categories the user can pick for their wash time.
enum _TimeChoice {
  /// "Anytime 8am-6pm" — whole working day open.
  allDay,

  /// "8am-12pm"
  windowMorning,

  /// "10am-2pm"
  windowMidday,

  /// "2pm-6pm"
  windowAfternoon,

  /// "Anytime today (+25%)"
  urgent,
}

/// A concrete start/end/type triple produced by a day + [_TimeChoice].
class _TimeWindow {
  const _TimeWindow({
    required this.start,
    required this.end,
    required this.type,
  });

  final DateTime start;
  final DateTime end;
  final TimeWindowType type;
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// The day the wash window falls on (date-only; the time comes from the
  /// chosen flexibility category). Defaults to today.
  DateTime? _selectedDay;

  /// The flexibility choice (all-day / specific window / urgent).
  _TimeChoice? _selectedChoice;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bookingDraftProvider);
    if (draft.address != null) {
      _addressController.text = draft.address!;
    } else {
      final profileAddress = ref.read(authProvider).profile?.address;
      if (profileAddress != null && profileAddress.isNotEmpty) {
        _addressController.text = profileAddress;
        // Defer the provider write: Riverpod forbids modifying providers
        // during initState (the widget tree is still building). The draft is
        // only updated after the first frame, exactly like the car pre-select.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(bookingDraftProvider.notifier).setAddress(profileAddress);
        });
      }
    }
    // Restore an existing time window (edit flow) into the selector, or
    // default to today.
    if (draft.dateTime != null) {
      _selectedDay = DateTime(
        draft.dateTime!.year,
        draft.dateTime!.month,
        draft.dateTime!.day,
      );
      _selectedChoice = _choiceFromDraft(draft);
    } else {
      final now = DateTime.now();
      _selectedDay = DateTime(now.year, now.month, now.day);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final draft = ref.read(bookingDraftProvider);
    return draft.car != null &&
        _addressController.text.trim().isNotEmpty &&
        _selectedChoice != null;
  }

  void _goNext() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDay == null || _selectedChoice == null) return;
    final draft = ref.read(bookingDraftProvider);
    if (draft.car == null) return;

    final window = _windowFor(_selectedDay!, _selectedChoice!);
    ref.read(bookingDraftProvider.notifier)
      ..setAddress(_addressController.text.trim())
      ..setTimeWindow(
        dateTime: window.start,
        timeType: window.type,
        scheduledEnd: window.end,
      );
    context.go(KlearRoutes.bookConfirm);
  }

  Future<void> _addCar() async {
    await context.push(KlearRoutes.carAdd);
    if (!mounted) return;
    ref.invalidate(carsProvider);
  }

  /// Opens the full-screen map picker and fills the address (plus precise
  /// coordinates) from the picked location.
  Future<void> _chooseOnMap() async {
    final picked =
        await context.push<PickedLocation>(KlearRoutes.mapPicker);
    if (picked == null || !mounted) return;
    setState(() => _addressController.text = picked.address);
    ref.read(bookingDraftProvider.notifier)
      ..setAddress(picked.address)
      ..setLatLng(picked.lat, picked.lng);
  }

  /// Opens the address book in selectable mode and fills the chosen address.
  Future<void> _chooseSavedAddress() async {
    final picked = await context.push<PickedLocation>(
      KlearRoutes.addressBook,
      extra: true,
    );
    if (picked == null || !mounted) return;
    setState(() => _addressController.text = picked.address);
    ref.read(bookingDraftProvider.notifier)
      ..setAddress(picked.address)
      ..setLatLng(picked.lat, picked.lng);
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationServiceDisabled)),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationPermissionDenied)),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final lat = position.latitude;
      final lng = position.longitude;

      // Best effort: turn the coordinates into a human-readable address.
      String address = '$lat, $lng';
      try {
        final reversed = await ref
            .read(nominatimServiceProvider)
            .reverse(lat, lng);
        if (reversed != null && reversed.isNotEmpty) address = reversed;
      } catch (_) {
        // Keep the coordinate fallback.
      }
      if (!mounted) return;
      setState(() => _addressController.text = address);
      ref.read(bookingDraftProvider.notifier)
        ..setAddress(address)
        ..setLatLng(lat, lng);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFailed)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
  }

  Future<void> _pickCustomDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _selectedDay ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDay = picked);
  }

  void _selectChoice(_TimeChoice choice) {
    setState(() => _selectedChoice = choice);
  }

  /// Builds the concrete time window for a day + flexibility choice.
  _TimeWindow _windowFor(DateTime day, _TimeChoice choice) {
    switch (choice) {
      case _TimeChoice.allDay:
        return _TimeWindow(
          start: DateTime(day.year, day.month, day.day, 8, 0),
          end: DateTime(day.year, day.month, day.day, 18, 0),
          type: TimeWindowType.allDay,
        );
      case _TimeChoice.windowMorning:
        return _TimeWindow(
          start: DateTime(day.year, day.month, day.day, 8, 0),
          end: DateTime(day.year, day.month, day.day, 12, 0),
          type: TimeWindowType.window,
        );
      case _TimeChoice.windowMidday:
        return _TimeWindow(
          start: DateTime(day.year, day.month, day.day, 10, 0),
          end: DateTime(day.year, day.month, day.day, 14, 0),
          type: TimeWindowType.window,
        );
      case _TimeChoice.windowAfternoon:
        return _TimeWindow(
          start: DateTime(day.year, day.month, day.day, 14, 0),
          end: DateTime(day.year, day.month, day.day, 18, 0),
          type: TimeWindowType.window,
        );
      case _TimeChoice.urgent:
        final now = DateTime.now();
        return _TimeWindow(
          start: now,
          end: DateTime(day.year, day.month, day.day, 23, 59),
          type: TimeWindowType.urgent,
        );
    }
  }

  /// Rebuilds the selector state from a stored booking (edit flow).
  _TimeChoice? _choiceFromDraft(BookingDraft draft) {
    final start = draft.dateTime;
    if (start == null) return null;
    final end = draft.scheduledEnd;
    final startH = start.hour;
    final endH = end?.hour ?? startH;

    switch (draft.timeType) {
      case TimeWindowType.allDay:
        return _TimeChoice.allDay;
      case TimeWindowType.urgent:
        return _TimeChoice.urgent;
      case TimeWindowType.window:
        if (startH == 8 && endH == 12) return _TimeChoice.windowMorning;
        if (startH == 10 && endH == 14) return _TimeChoice.windowMidday;
        if (startH == 14 && endH == 18) return _TimeChoice.windowAfternoon;
        // Fall back to the closest window for unexpected legacy rows.
        if (startH < 10) return _TimeChoice.windowMorning;
        if (startH < 14) return _TimeChoice.windowMidday;
        return _TimeChoice.windowAfternoon;
    }
  }

  String _dayLabel(DateTime day, AppLocalizations l10n, String langCode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDate = DateTime(day.year, day.month, day.day);
    if (dayDate == today) return l10n.quickSlotToday;
    if (dayDate == today.add(const Duration(days: 1))) {
      return l10n.quickSlotTomorrow;
    }
    return DateFormat(langCode == 'ar' ? 'MM/dd' : 'MMM d').format(day);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Whether the urgent option can be chosen (only valid for today).
  bool _canChooseUrgent(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _isSameDay(day, today);
  }

  List<DateTime> _dayOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [today, today.add(const Duration(days: 1))];
  }

  List<_TimeChoice> get _windowChoices => const [
        _TimeChoice.windowMorning,
        _TimeChoice.windowMidday,
        _TimeChoice.windowAfternoon,
      ];

  String _windowLabel(_TimeChoice choice, AppLocalizations l10n) {
    switch (choice) {
      case _TimeChoice.windowMorning:
        return l10n.timeWindowMorning;
      case _TimeChoice.windowMidday:
        return l10n.timeWindowMidday;
      case _TimeChoice.windowAfternoon:
        return l10n.timeWindowAfternoon;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final carsAsync = ref.watch(carsProvider);
    final draft = ref.watch(bookingDraftProvider);
    final scheme = Theme.of(context).colorScheme;
    final langCode = Localizations.localeOf(context).languageCode;
    final savedAddress = ref.watch(authProvider).profile?.address;
    final hasSavedAddress =
        savedAddress != null && savedAddress.trim().isNotEmpty;

    if (draft.service == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(KlearRoutes.bookSelectService);
      });
      return const SizedBox.shrink();
    }

    return BookingStepScaffold(
      currentStep: 2,
      title: l10n.bookingDetailsTitle,
      priceFooterUrgent: _selectedChoice == _TimeChoice.urgent,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionHeader(
              icon: Icons.directions_car_outlined,
              title: l10n.selectCar,
            ),
            const SizedBox(height: 8),
            carsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Text(l10n.errorLoadingServices),
              data: (cars) {
                // Pre-select the user's default car (or the first one) once
                // so the user doesn't have to re-pick it every time.
                if (draft.car == null && cars.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref
                        .read(bookingDraftProvider.notifier)
                        .setCar(preferredCar(cars));
                  });
                }
                if (cars.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            l10n.noCarsAddPrompt,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _addCar,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addCar),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final car in cars)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: _CarChip(
                            car: car,
                            selected: draft.car?.id == car.id,
                            langCode: langCode,
                            l10n: l10n,
                            onTap: () => ref
                                .read(bookingDraftProvider.notifier)
                                .setCar(car),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _addCar,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addCar),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.location_on_outlined,
              title: l10n.enterAddress,
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _chooseOnMap,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.chooseOnMap),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.addressLabel,
                hintText: l10n.addressHint,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.addressRequired;
                }
                return null;
              },
              onChanged: (value) {
                ref.read(bookingDraftProvider.notifier).setAddress(value);
                setState(() {});
              },
            ),
            if (hasSavedAddress) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _chooseSavedAddress,
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(l10n.useSavedAddress),
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(
                  _locating ? l10n.locationLoading : l10n.useCurrentLocation,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.schedule_outlined,
              title: l10n.selectDateTime,
            ),
            const SizedBox(height: 12),
            // Day selector: Today / Tomorrow / pick another day.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in _dayOptions())
                  ChoiceChip(
                    label: Text(_dayLabel(day, l10n, langCode)),
                    selected: _isSameDay(_selectedDay, day),
                    onSelected: (_) => _selectDay(day),
                  ),
                ActionChip(
                  avatar: Icon(
                    Icons.edit_calendar,
                    size: 18,
                    color: scheme.primary,
                  ),
                  label: Text(l10n.pickAnotherDay),
                  onPressed: _pickCustomDay,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category 1 — all-day window.
            _TimeOptionCard(
              icon: Icons.wb_sunny_outlined,
              title: l10n.timeAllDayTitle,
              value: l10n.timeAllDayLabel,
              selected: _selectedChoice == _TimeChoice.allDay,
              onTap: () => _selectChoice(_TimeChoice.allDay),
            ),
            const SizedBox(height: 8),
            // Category 2 — specific 4-hour windows.
            _TimeOptionCard(
              icon: Icons.timelapse_outlined,
              title: l10n.timeSpecificTitle,
              value: l10n.timeSpecificLabel,
              selected: _selectedChoice != null &&
                  _selectedChoice! != _TimeChoice.allDay &&
                  _selectedChoice! != _TimeChoice.urgent,
              onTap: () => _selectChoice(_TimeChoice.windowMorning),
            ),
            const SizedBox(height: 8),
            if (_selectedChoice != null &&
                _selectedChoice != _TimeChoice.allDay &&
                _selectedChoice != _TimeChoice.urgent)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _windowChoices)
                    ChoiceChip(
                      label: Text(_windowLabel(choice, l10n)),
                      selected: _selectedChoice == choice,
                      onSelected: (_) => _selectChoice(choice),
                    ),
                ],
              ),
            if (_selectedChoice != null &&
                _selectedChoice != _TimeChoice.allDay &&
                _selectedChoice != _TimeChoice.urgent)
              const SizedBox(height: 8),
            // Category 3 — urgent (today only).
            _TimeOptionCard(
              icon: Icons.bolt_outlined,
              title: l10n.timeUrgentTitle,
              value: l10n.timeUrgentLabel,
              selected: _selectedChoice == _TimeChoice.urgent,
              enabled: _canChooseUrgent(_selectedDay ?? DateTime.now()),
              onTap: () => _selectChoice(_TimeChoice.urgent),
            ),
            if (_selectedChoice != null) ...[
              const SizedBox(height: 12),
              Text(
                BookingTimeLabels.fullLabel(
                  start: _windowFor(_selectedDay!, _selectedChoice!).start,
                  end: _windowFor(_selectedDay!, _selectedChoice!).end,
                  type: _windowFor(_selectedDay!, _selectedChoice!).type,
                  l10n: l10n,
                  langCode: langCode,
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                    ),
              ),
            ],
            if (draft.car != null) ...[
              const SizedBox(height: 24),
              _BreakdownCard(
                draft: draft,
                isUrgent: _selectedChoice == _TimeChoice.urgent,
                settings: ref.watch(appSettingsProvider),
                l10n: l10n,
                langCode: langCode,
              ),
            ],
          ],
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _canContinue ? _goNext : null,
            child: Text(l10n.continueLabel),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: scheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

/// Selectable card for one flexibility category (all-day / specific / urgent).
class _TimeOptionCard extends StatelessWidget {
  const _TimeOptionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled
          ? (selected ? scheme.primaryContainer : scheme.surfaceContainerLow)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? (selected ? scheme.primary : scheme.outlineVariant)
                  : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled
                    ? (selected ? scheme.primary : scheme.onSurfaceVariant)
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: enabled
                                ? null
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? scheme.primary : scheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent cost breakdown shown live on the details step: base price,
/// size adjustment (× factor) and the estimated total. `isUrgent` is the
/// live selection (may differ from the committed draft while picking).
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.draft,
    required this.isUrgent,
    required this.settings,
    required this.l10n,
    required this.langCode,
  });

  final BookingDraft draft;
  final bool isUrgent;
  final AppSettings settings;
  final AppLocalizations l10n;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final size = draft.car!.size;
    final sizeLabel = switch (size) {
      KlearCarSize.small => l10n.sizeSmall,
      KlearCarSize.medium => l10n.sizeMedium,
      KlearCarSize.large => l10n.sizeLarge,
    };
    final factor = settings.priceFactorFor(size);
    final factorLabel = factor == factor.roundToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);
    final surcharge = isUrgent ? settings.urgentSurchargePercent : 0.0;
    final total = draft.estimatedTotal(settings) * (1 + surcharge);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.priceEstimate,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(
              context,
              l10n.priceBase,
              '${draft.service?.basePrice.toStringAsFixed(0) ?? '0'} '
              '${draft.service?.currency ?? 'SYP'}',
            ),
            _row(
              context,
              l10n.sizeAdjustment,
              '$sizeLabel · ×$factorLabel',
            ),
            if (isUrgent) ...[
              _row(
                context,
                l10n.urgentSurcharge,
                '+${(settings.urgentSurchargePercent * 100).toStringAsFixed(0)}%',
              ),
            ],
            const Divider(height: 24),
            _row(
              context,
              l10n.totalEstimate,
              '${total.toStringAsFixed(0)} '
              '${draft.service?.currency ?? 'SYP'}',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasized = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: emphasized
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    )
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _CarChip extends StatelessWidget {
  const _CarChip({
    required this.car,
    required this.selected,
    required this.langCode,
    required this.l10n,
    required this.onTap,
  });

  final KlearCar car;
  final bool selected;
  final String langCode;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedPress(
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  car.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    car.plateNumber,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
