import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../../cars/domain/klear_car.dart';
import '../../cars/presentation/cars_providers.dart';
import 'booking_providers.dart';
import 'widgets/booking_step_scaffold.dart';

/// Step 2: car + address + schedule on one screen.
class BookingDetailsPage extends ConsumerStatefulWidget {
  const BookingDetailsPage({super.key});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;

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
        ref.read(bookingDraftProvider.notifier).setAddress(profileAddress);
      }
    }
    _selectedDateTime = draft.dateTime;
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
        _selectedDateTime != null;
  }

  void _goNext() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDateTime == null) return;
    final draft = ref.read(bookingDraftProvider);
    if (draft.car == null) return;

    ref.read(bookingDraftProvider.notifier)
      ..setAddress(_addressController.text.trim())
      ..setDateTime(_selectedDateTime);
    context.go(KlearRoutes.bookConfirm);
  }

  Future<void> _addCar() async {
    await context.push(KlearRoutes.carAdd);
    if (!mounted) return;
    ref.invalidate(carsProvider);
  }

  void _useSavedAddress() {
    final address = ref.read(authProvider).profile?.address;
    if (address == null || address.isEmpty) return;
    setState(() => _addressController.text = address);
    ref.read(bookingDraftProvider.notifier).setAddress(address);
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
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
      final coords =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      setState(() => _addressController.text = coords);
      ref.read(bookingDraftProvider.notifier).setAddress(coords);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationPermissionDenied)),
      );
    }
  }

  void _selectQuickSlot(DateTime slot) {
    setState(() => _selectedDateTime = slot);
    ref.read(bookingDraftProvider.notifier).setDateTime(slot);
  }

  Future<void> _pickCustomDateTime() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;

    final initialTime = _selectedDateTime != null
        ? TimeOfDay.fromDateTime(_selectedDateTime!)
        : TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    _selectQuickSlot(combined);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dateTimeSaved)),
    );
  }

  List<DateTime> _quickSlots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return [
      DateTime(today.year, today.month, today.day, 10, 0),
      DateTime(today.year, today.month, today.day, 14, 0),
      DateTime(today.year, today.month, today.day, 18, 0),
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0),
    ].where((slot) => slot.isAfter(now)).toList();
  }

  String _slotLabel(DateTime slot, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDay = DateTime(slot.year, slot.month, slot.day);
    final dayLabel = slotDay == today
        ? l10n.quickSlotToday
        : slotDay == today.add(const Duration(days: 1))
            ? l10n.quickSlotTomorrow
            : DateFormat('MM/dd').format(slot);
    final hour = slot.hour;
    final period = hour < 12
        ? l10n.quickSlotMorning
        : hour < 17
            ? l10n.quickSlotAfternoon
            : l10n.quickSlotEvening;
    return '$dayLabel · $period';
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
    final quickSlots = _quickSlots();

    if (draft.service == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(KlearRoutes.bookSelectService);
      });
      return const SizedBox.shrink();
    }

    return BookingStepScaffold(
      currentStep: 2,
      title: l10n.bookingDetailsTitle,
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
                  onPressed: _useSavedAddress,
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(l10n.useSavedAddress),
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: Text(l10n.useCurrentLocation),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.schedule_outlined,
              title: l10n.selectDateTime,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in quickSlots)
                  FilterChip(
                    label: Text(_slotLabel(slot, l10n)),
                    selected: _selectedDateTime != null &&
                        _selectedDateTime!.year == slot.year &&
                        _selectedDateTime!.month == slot.month &&
                        _selectedDateTime!.day == slot.day &&
                        _selectedDateTime!.hour == slot.hour &&
                        _selectedDateTime!.minute == slot.minute,
                    onSelected: (_) => _selectQuickSlot(slot),
                  ),
                ActionChip(
                  avatar: Icon(Icons.edit_calendar, size: 18, color: scheme.primary),
                  label: Text(l10n.customDateTime),
                  onPressed: _pickCustomDateTime,
                ),
              ],
            ),
            if (_selectedDateTime != null) ...[
              const SizedBox(height: 12),
              Text(
                DateFormat(
                  langCode == 'ar' ? 'yyyy/MM/dd HH:mm' : 'MMM dd, yyyy h:mm a',
                ).format(_selectedDateTime!),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                    ),
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
