import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/geocoding/nominatim_service.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../addresses/presentation/map_picker_page.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import '../../orders/presentation/orders_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/klear_booking.dart';
import '../domain/day_availability.dart';
import 'availability_providers.dart';
import 'booking_providers.dart';
import 'booking_time_labels.dart';
import 'widgets/availability_calendar_strip.dart';
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
    // Refresh availability counts every time the flow is entered so the
    // calendar reflects bookings created elsewhere (e.g. another device).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(availabilityRangeProvider);
    });
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

  /// The availability slot matching a flexibility choice, if any.
  WindowSlot? _slotFor(DayAvailability? day, _TimeChoice choice) {
    final key = switch (choice) {
      _TimeChoice.windowMorning => 'morning',
      _TimeChoice.windowMidday => 'midday',
      _TimeChoice.windowAfternoon => 'afternoon',
      _ => '',
    };
    return day?.slot(key);
  }

  /// Maps a slot key from the availability RPC back to its choice.
  _TimeChoice? _choiceForKey(String key) => switch (key) {
        'morning' => _TimeChoice.windowMorning,
        'midday' => _TimeChoice.windowMidday,
        'afternoon' => _TimeChoice.windowAfternoon,
        _ => null,
      };

  /// Maps a historical window start hour (T3 preferred window) back to the
  /// matching flexibility choice. Slot starts are 08:00 / 10:00 / 14:00.
  _TimeChoice? _choiceForStartHour(int hour) {
    if (hour <= 9) return _TimeChoice.windowMorning;
    if (hour <= 12) return _TimeChoice.windowMidday;
    return _TimeChoice.windowAfternoon;
  }

  /// Whether the current schedule selection is bookable (window not full,
  /// all-day day not saturated). Recomputed on every build by
  /// [_scheduleSection]; gates the Continue CTA.
  bool _scheduleValid = false;

  /// T3 smart default: applied at most once per page visit, only while the
  /// user hasn't picked a time themselves.
  bool _smartDefaultApplied = false;

  DateTime get _todayDate {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The rebuilt schedule section: calendar strip with load dots, legend,
  /// per-window availability cards, plus the all-day / urgent fallbacks.
  List<Widget> _scheduleSection(
    BuildContext context,
    AppLocalizations l10n,
    String langCode,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final availAsync = ref.watch(
      availabilityRangeProvider((from: _todayDate, days: 14)),
    );
    final availList = availAsync.valueOrNull ?? const <DayAvailability>[];
    final byDay = {for (final d in availList) d.day: d};
    final selectedAvail = byDay[_dateOnly(_selectedDay ?? _todayDate)];
    final allFull = selectedAvail?.allFull ?? false;

    // T3 smart default: preselect the user's habitual window once, only
    // while they haven't picked anything and it still has capacity.
    if (!_smartDefaultApplied &&
        _selectedChoice == null &&
        selectedAvail != null) {
      _smartDefaultApplied = true;
      final pref = ref.read(bookingInsightsProvider)?.preferredWindow;
      final choice = switch (pref) {
        (TimeWindowType.allDay, _) => _TimeChoice.allDay,
        (TimeWindowType.window, final h?) => _choiceForStartHour(h),
        _ => null,
      };
      if (choice != null) {
        final bookable = switch (choice) {
          _TimeChoice.allDay => !allFull,
          _TimeChoice.urgent => false,
          _ =>
            _slotFor(selectedAvail, choice)?.status != SlotStatus.full &&
                _slotFor(selectedAvail, choice) != null,
        };
        if (bookable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // Never override a manual pick made in the same frame window.
            if (_selectedChoice == null) {
              setState(() => _selectedChoice = choice);
            }
          });
        }
      }
    }

    // Drop a selection that became unbookable (e.g. window filled up or the
    // user switched to a fully-booked day). Deferred so we never setState
    // during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final invalid = switch (_selectedChoice) {
        null => false,
        _TimeChoice.allDay => selectedAvail != null && allFull,
        _TimeChoice.urgent => false,
        _ =>
            _slotFor(selectedAvail, _selectedChoice!)?.status ==
                SlotStatus.full,
      };
      if (invalid) setState(() => _selectedChoice = null);
    });

    // CTA gate — mirrors what is rendered below.
    _scheduleValid = switch (_selectedChoice) {
      null => false,
      _TimeChoice.urgent => true,
      _TimeChoice.allDay => !allFull,
      _ =>
            (_slotFor(selectedAvail, _selectedChoice!)?.status ??
                SlotStatus.full) !=
            SlotStatus.full,
    };

    return [
      _SectionHeader(
        icon: Icons.event_available_outlined,
        title: l10n.selectDateTime,
      ),
      const SizedBox(height: 12),
      AvailabilityCalendarStrip(
        selectedDay: _dateOnly(_selectedDay ?? _todayDate),
        availabilityByDay: byDay,
        onSelect: (day) => setState(() {
          _selectedDay = day;
          // Urgent only applies to today; reset when leaving it.
          if (!_canChooseUrgent(day) && _selectedChoice == _TimeChoice.urgent) {
            _selectedChoice = null;
          }
        }),
      ),
      const SizedBox(height: 8),
      // Legend for the strip's load dots.
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(const Color(0xFF16A34A), l10n.availLegendFree),
          const SizedBox(width: 14),
          _legendDot(const Color(0xFFD97706), l10n.availLegendLimited),
          const SizedBox(width: 14),
          _legendDot(scheme.error, l10n.availLegendFull),
        ],
      ),
      const SizedBox(height: 12),
      availAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () =>
                ref.invalidate(availabilityRangeProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.errorLoadingServices),
          ),
        ),
        data: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedAvail != null) ...[
              // Capacity context line (same for every window of the day).
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.availTeamsLine(selectedAvail.capacity),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(height: 10),
              for (final slot in selectedAvail.slots) ...[
                _WindowCard(
                  slot: slot,
                  label: switch (_choiceForKey(slot.key)) {
                    _TimeChoice.windowMorning => l10n.timeWindowMorning,
                    _TimeChoice.windowMidday => l10n.timeWindowMidday,
                    _TimeChoice.windowAfternoon => l10n.timeWindowAfternoon,
                    _ => slot.key,
                  },
                  statusText: switch (slot.status) {
                    SlotStatus.free => l10n.availSlotFree,
                    SlotStatus.limited => l10n.availSlotOneLeft,
                    SlotStatus.full => l10n.availLegendFull,
                  },
                  selected: _selectedChoice == _choiceForKey(slot.key),
                  onTap: slot.status == SlotStatus.full
                      ? null
                      : () => _selectChoice(_choiceForKey(slot.key)!),
                ),
                const SizedBox(height: 8),
              ],
              if (allFull)
                Text(
                  l10n.availAllFullNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      // All-day remains available unless the whole day is saturated.
      _TimeOptionCard(
        icon: Icons.wb_sunny_outlined,
        title: l10n.timeAllDayTitle,
        value: l10n.timeAllDayLabel,
        selected: _selectedChoice == _TimeChoice.allDay,
        enabled: !allFull,
        onTap: () => _selectChoice(_TimeChoice.allDay),
      ),
      const SizedBox(height: 8),
      // Urgent (today only) ignores windows entirely.
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
    ];
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final carsAsync = ref.watch(carsProvider);
    final draft = ref.watch(bookingDraftProvider);
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
            ..._scheduleSection(context, l10n, langCode),
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
            onPressed: (_canContinue && _scheduleValid) ? _goNext : null,
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
    final factor = settings.carFactor(draft.car!);
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
              '${draft.service?.finalPrice.toStringAsFixed(0) ?? '0'} '
              '${draft.service?.currency ?? 'SYP'}',
            ),
            if (draft.service?.hasDiscount ?? false)
              _row(
                context,
                l10n.discountLabel,
                '-${draft.service!.savingsAmount.toStringAsFixed(0)} '
                '${draft.service!.currency}',
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

/// Availability card for one fixed business window (e.g. 8am–12pm):
/// time block · status pill + capacity bar · radio. Full windows are
/// disabled and dimmed — the user can't select what doesn't exist.
class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.slot,
    required this.label,
    required this.statusText,
    required this.selected,
    required this.onTap,
  });

  final WindowSlot slot;
  final String label;
  final String statusText;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = slot.status == SlotStatus.full;
    final pillColor = switch (slot.status) {
      SlotStatus.free => const Color(0xFFDCFCE7),
      SlotStatus.limited => const Color(0xFFFEF3C7),
      SlotStatus.full => scheme.errorContainer,
    };
    final pillTextColor = switch (slot.status) {
      SlotStatus.free => const Color(0xFF15803D),
      SlotStatus.limited => const Color(0xFFB45309),
      SlotStatus.full => scheme.onErrorContainer,
    };
    final fill = slot.capacity <= 0
        ? 1.0
        : (slot.booked / slot.capacity).clamp(0.0, 1.0);
    final barColor = switch (slot.status) {
      SlotStatus.free => const Color(0xFF16A34A),
      SlotStatus.limited => const Color(0xFFD97706),
      SlotStatus.full => scheme.error,
    };

    return Opacity(
      opacity: full ? 0.55 : 1.0,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Time block.
                SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status + capacity bar.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: pillTextColor),
                            const SizedBox(width: 5),
                            Text(
                              statusText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: pillTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: full ? 1.0 : (fill == 0 ? null : fill),
                          minHeight: 4,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Radio.
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? scheme.primary
                          : scheme.outlineVariant,
                      width: 2,
                    ),
                    color: selected
                        ? scheme.primary
                        : Colors.transparent,
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 13, color: scheme.onPrimary)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
