import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../app/app_router.dart';
import '../../core/geocoding/nominatim_service.dart';
import '../account/domain/klear_user.dart';
import '../account/presentation/auth_providers.dart';
import '../addresses/presentation/map_picker_page.dart';

/// Profile setup screen. New users fill in name + location before booking.
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double? _lat;
  double? _lng;
  bool _locationLoading = false;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
      _addressController.text = profile.address ?? '';
      _lat = profile.lat;
      _lng = profile.lng;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      // 1. Check service availability.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationLoading = false;
          _locationDenied = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).locationServiceDisabled)),
          );
        }
        return;
      }

      // 2. Check permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationLoading = false;
          _locationDenied = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).locationPermissionDenied)),
          );
        }
        return;
      }

      // 3. Get current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 4. Best effort: reverse-geocode into a readable address.
      String address = '${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)}';
      try {
        final reversed = await ref
            .read(nominatimServiceProvider)
            .reverse(position.latitude, position.longitude);
        if (reversed != null && reversed.isNotEmpty) address = reversed;
      } catch (_) {
        // Keep the coordinate fallback.
      }
      if (!mounted) return;

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _addressController.text = address;
        _locationLoading = false;
        _locationDenied = false;
      });
    } catch (e) {
      setState(() => _locationLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).errorLoadingServices}: $e')),
        );
      }
    }
  }

  /// Opens the full-screen map picker and fills address + coordinates.
  Future<void> _chooseOnMap() async {
    final picked = await context.push<PickedLocation>(KlearRoutes.mapPicker);
    if (picked == null || !mounted) return;
    setState(() {
      _lat = picked.lat;
      _lng = picked.lng;
      _addressController.text = picked.address;
      _locationDenied = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in.')),
      );
      return;
    }
    final updated = KlearUser(
      id: user.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      lat: _lat,
      lng: _lng,
      address: _addressController.text.trim(),
      role: auth.profile?.role ?? 'customer',
      createdAt: auth.profile?.createdAt,
    );
    try {
      await ref.read(authProvider.notifier).updateProfile(updated);
      if (!mounted) return;
      context.go('/');
    } on KlearPhoneTakenException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).phoneAlreadyInUse)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).errorLoadingServices}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.profileSetupSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  hintText: l10n.fullNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fullNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: '09xxxxxxxx',
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.phoneRequired;
                  }
                  if (value.trim().length < 9) {
                    return l10n.phoneInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: l10n.addressLabel,
                  hintText: l10n.addressHint,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Location picker — map-first, with manual fallback below.
              FilledButton.tonalIcon(
                onPressed: _chooseOnMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.chooseOnMap),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Location tile
              Card(
                color: _locationDenied
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                child: ListTile(
                  leading: _locationLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.my_location,
                          color: _lat != null
                              ? Theme.of(context).colorScheme.tertiary
                              : null,
                        ),
                  title: Text(l10n.useCurrentLocation),
                  subtitle: _lat != null && _lng != null
                      ? Text(
                          '$_lat, $_lng',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Text(
                          _locationDenied
                              ? l10n.locationPermissionDenied
                              : l10n.notSelected,
                          style: TextStyle(
                            color: _locationDenied
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                  trailing: Icon(
                    _lat != null ? Icons.check_circle : Icons.chevron_right,
                    color: _lat != null
                        ? Theme.of(context).colorScheme.tertiary
                        : null,
                  ),
                  onTap: _locationLoading ? null : _getCurrentLocation,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: auth.isLoading ? null : _save,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ),
      ),
    );
  }
}
