import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/car_attribute_catalog.dart';
import '../domain/klear_car.dart';
import 'cars_providers.dart';

/// Add / edit a car. When [car] is provided the form pre-fills and updates,
/// otherwise it inserts a new car for the current user. The built-in
/// make/model/plate/size fields are always shown; additional admin-defined
/// attributes (from the visible catalog) are rendered dynamically and their
/// values persisted to `car_attribute_values`.
class CarFormPage extends ConsumerStatefulWidget {
  const CarFormPage({super.key, this.car});

  final KlearCar? car;

  @override
  ConsumerState<CarFormPage> createState() => _CarFormPageState();
}

class _CarFormPageState extends ConsumerState<CarFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _plateController;
  late KlearCarSize _size;
  bool _saving = false;

  // Dynamic (catalog) attribute state, keyed by attribute key.
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _selectValues = {};

  /// System attributes already rendered as first-class fields.
  static const _systemKeys = {'make', 'model', 'plate_number', 'size'};

  bool get _isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.car?.make ?? '');
    _modelController = TextEditingController(text: widget.car?.model ?? '');
    _plateController =
        TextEditingController(text: widget.car?.plateNumber ?? '');
    _size = widget.car?.size ?? KlearCarSize.medium;
    _seedDynamicControllers();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Initializes one text controller per dynamic text attribute and one
  /// selected value per select attribute from the car being edited.
  void _seedDynamicControllers() {
    final attributes = widget.car?.attributes ?? const {};
    _textControllers.clear();
    _selectValues.clear();
    for (final entry in attributes.entries) {
      _selectValues[entry.key] = entry.value;
    }
  }

  /// Ensures a controller exists for every dynamic text attribute in the
  /// loaded catalog (preserving the seeded value when editing).
  void _ensureControllersFor(List<CarAttribute> catalog) {
    for (final attr in catalog) {
      if (attr.dataType == CarAttrDataType.text) {
        _textControllers.putIfAbsent(
          attr.key,
          () => TextEditingController(
            text: widget.car?.attributes[attr.key] ?? '',
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final catalog = _currentCatalog();
    // Validate required select attributes.
    for (final attr in catalog) {
      if (attr.isRequired &&
          attr.dataType == CarAttrDataType.select &&
          (_selectValues[attr.key] == null ||
              _selectValues[attr.key]!.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${attr.label(Localizations.localeOf(context).languageCode)}: '
              '${l10n.fieldRequired}',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      String carId;
      if (_isEditing) {
        carId = widget.car!.id;
        await updateCar(
          ref,
          KlearCar(
            id: carId,
            userId: widget.car!.userId,
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            plateNumber: _plateController.text.trim(),
            size: _size,
            createdAt: widget.car!.createdAt,
          ),
        );
      } else {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;
        final created = await addCar(
          ref,
          KlearCar(
            id: '',
            userId: userId,
            make: _makeController.text.trim(),
            model: _modelController.text.trim(),
            plateNumber: _plateController.text.trim(),
            size: _size,
          ),
        );
        carId = created.id;
      }
      // Persist dynamic attribute values (text + select) for this car.
      final values = <String, String>{};
      for (final attr in catalog) {
        var value = _selectValues[attr.key] ?? '';
        if (attr.dataType == CarAttrDataType.text) {
          value = _textControllers[attr.key]?.text.trim() ?? '';
        }
        values[attr.key] = value;
      }
      if (values.isNotEmpty) {
        await saveCarAttributes(ref, carId, values);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed)),
      );
    }
  }

  List<CarAttribute> _currentCatalog() {
    final catalogAsync = ref.read(carAttributesCatalogProvider);
    final catalog = catalogAsync.value ?? const <CarAttribute>[];
    return catalog.where((a) => !_systemKeys.contains(a.key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final langCode = Localizations.localeOf(context).languageCode;

    final catalogAsync = ref.watch(carAttributesCatalogProvider);
    final catalog = (catalogAsync.value ?? const <CarAttribute>[])
        .where((a) => !_systemKeys.contains(a.key))
        .toList();
    _ensureControllersFor(catalog);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCar : l10n.addCar),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Make
            TextFormField(
              controller: _makeController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.carMake,
                hintText: l10n.carMakeHint,
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.carMakeRequired
                  : null,
            ),
            const SizedBox(height: 16),
            // Model
            TextFormField(
              controller: _modelController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.carModel,
                hintText: l10n.carModelHint,
                prefixIcon: const Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.carModelRequired
                  : null,
            ),
            const SizedBox(height: 16),
            // Plate number (always LTR input)
            TextFormField(
              controller: _plateController,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.carPlate,
                hintText: l10n.carPlateHint,
                hintTextDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.carPlateRequired
                  : null,
            ),
            const SizedBox(height: 24),
            // Size — drives the price estimate
            Text(
              l10n.carSize,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<KlearCarSize>(
              segments: [
                ButtonSegment(
                  value: KlearCarSize.small,
                  label: Text(l10n.sizeSmall),
                  icon: const Icon(Icons.directions_car_filled_outlined),
                ),
                ButtonSegment(
                  value: KlearCarSize.medium,
                  label: Text(l10n.sizeMedium),
                  icon: const Icon(Icons.directions_car),
                ),
                ButtonSegment(
                  value: KlearCarSize.large,
                  label: Text(l10n.sizeLarge),
                  icon: const Icon(Icons.airport_shuttle_outlined),
                ),
              ],
              selected: {_size},
              onSelectionChanged: (selection) {
                setState(() => _size = selection.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.sizeAdjustment}: '
              '${_sizeLabel(_size, l10n)} · ×'
              '${_formatFactor(_size.priceFactor)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            // Dynamic catalog attributes (admin-defined, excluding system ones
            // already rendered above).
            if (catalog.isNotEmpty) ...[
              const SizedBox(height: 24),
              for (final attr in catalog) ...[
                if (attr.dataType == CarAttrDataType.select)
                  _buildSelectField(attr, langCode)
                else
                  _buildTextField(attr, langCode),
                const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? l10n.saving : l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(CarAttribute attr, String langCode) {
    final controller = _textControllers[attr.key] ?? TextEditingController();
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: attr.label(langCode),
        prefixIcon: const Icon(Icons.edit_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: attr.isRequired
          ? (value) => (value == null || value.trim().isEmpty)
              ? _fieldError(attr, langCode)
              : null
          : null,
    );
  }

  Widget _buildSelectField(CarAttribute attr, String langCode) {
    final options = attr.options
        .map((o) => DropdownMenuItem(
              value: o.value,
              child: Text(o.label(langCode)),
            ))
        .toList();
    final current = _selectValues[attr.key];
    return DropdownButtonFormField<String>(
      initialValue: options.any((o) => o.value == current) ? current : null,
      items: options,
      decoration: InputDecoration(
        labelText: attr.label(langCode),
        prefixIcon: const Icon(Icons.list_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onChanged: (value) => setState(() {
        if (value != null) _selectValues[attr.key] = value;
      }),
      validator: attr.isRequired
          ? (value) => (value == null) ? _fieldError(attr, langCode) : null
          : null,
    );
  }

  String _fieldError(CarAttribute attr, String langCode) {
    final l10n = AppLocalizations.of(context);
    return '${attr.label(langCode)}: ${l10n.fieldRequired}';
  }

  String _sizeLabel(KlearCarSize size, AppLocalizations l10n) {
    switch (size) {
      case KlearCarSize.small:
        return l10n.sizeSmall;
      case KlearCarSize.medium:
        return l10n.sizeMedium;
      case KlearCarSize.large:
        return l10n.sizeLarge;
    }
  }

  String _formatFactor(double factor) {
    return factor == factor.roundToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);
  }
}
