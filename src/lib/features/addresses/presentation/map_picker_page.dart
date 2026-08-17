import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geocoding/nominatim_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../data/addresses_repository.dart';
import '../domain/user_address.dart';
import 'addresses_providers.dart';

/// A location chosen on the map (coordinate + human-readable address).
class PickedLocation {
  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });

  final double lat;
  final double lng;
  final String address;
}

/// Full-screen map picker.
///
/// The user pans the map to place the centered pin, searches for a place, or
/// uses their current location. Tapping "Use this location" pops with a
/// [PickedLocation]; "Save to address book" persists it for later.
class MapPickerPage extends ConsumerStatefulWidget {
  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends ConsumerState<MapPickerPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  LatLng _center = const LatLng(33.5138, 36.2765); // Damascus fallback.
  String? _address;
  bool _addressLoading = false;
  bool _locating = false;
  List<GeoPlace> _searchResults = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationServiceDisabled)),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      _mapController.move(target, 16);
      _onCenterChanged(target);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final target = camera.center;
    if ((target.latitude - _center.latitude).abs() < 0.0000001 &&
        (target.longitude - _center.longitude).abs() < 0.0000001) {
      return;
    }
    _onCenterChanged(target);
  }

  void _onCenterChanged(LatLng target) {
    _debounce?.cancel();
    _center = target;
    setState(() => _addressLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final service = ref.read(nominatimServiceProvider);
      String? address;
      try {
        address = await service.reverse(target.latitude, target.longitude);
      } catch (_) {
        address = null;
      }
      if (!mounted) return;
      setState(() {
        _address = address ??
            '${target.latitude.toStringAsFixed(5)}, '
                '${target.longitude.toStringAsFixed(5)}';
        _addressLoading = false;
      });
    });
  }

  Future<void> _search(String query) async {
    final l10n = AppLocalizations.of(context);
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _searchResults = const [];
    });
    try {
      final results =
          await ref.read(nominatimServiceProvider).search(query, limit: 5);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFailed)),
      );
    }
  }

  void _selectSearchResult(GeoPlace place) {
    _searchFocus.unfocus();
    setState(() {
      _searchResults = const [];
      _searchController.clear();
    });
    final target = LatLng(place.lat, place.lng);
    _mapController.move(target, 16);
    _onCenterChanged(target);
  }

  Future<void> _saveToBook() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final address = _address;
    if (address == null) return;

    final label = await showDialog<String>(
      context: context,
      builder: (context) => _SaveLabelDialog(l10n: l10n),
    );
    if (label == null || !mounted) return;

    try {
      await ref.read(addressesRepositoryProvider).insertAddress(
            UserAddress(
              id: '',
              userId: user.id,
              label: label,
              address: address,
              lat: _center.latitude,
              lng: _center.longitude,
            ),
          );
      ref.invalidate(userAddressesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapSavedToBook)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingServices)),
      );
    }
  }

  void _useLocation() {
    final address = _address;
    if (address == null) return;
    Navigator.of(context).pop(
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        address: address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapPickerTitle)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.klear.klear',
              ),
            ],
          ),
          // Centered pin (pointer events pass through to the map).
          IgnorePointer(
            child: Center(
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: scheme.primary,
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 6),
                ],
              ),
            ),
          ),
          // Search bar.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(28),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.mapSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: _search,
              ),
            ),
          ),
          // Search results.
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 76,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(
                          place.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(place),
                      );
                    },
                  ),
                ),
              ),
            ),
          // Current-location FAB.
          Positioned(
            right: 12,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'map-locate',
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          // Bottom address panel.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Material(
                elevation: 12,
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _addressLoading
                                ? Text(l10n.mapAddressLoading)
                                : Text(
                                    _address ??
                                        '${_center.latitude.toStringAsFixed(5)}, '
                                            '${_center.longitude.toStringAsFixed(5)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saveToBook,
                              icon: const Icon(Icons.bookmark_add_outlined,
                                  size: 18),
                              label: Text(l10n.mapSaveToBook),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _useLocation,
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(l10n.mapUseThisLocation),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog asking for a label before saving to the address book.
class _SaveLabelDialog extends StatefulWidget {
  const _SaveLabelDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_SaveLabelDialog> createState() => _SaveLabelDialogState();
}

class _SaveLabelDialogState extends State<_SaveLabelDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.mapSaveLabelTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in [
                  l10n.addressLabelHome,
                  l10n.addressLabelWork,
                  l10n.addressLabelOther,
                ])
                  ActionChip(
                    label: Text(label),
                    onPressed: () {
                      _controller.text = label;
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.mapLabelHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.addressLabelRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(l10n.saveLabel),
        ),
      ],
    );
  }
}