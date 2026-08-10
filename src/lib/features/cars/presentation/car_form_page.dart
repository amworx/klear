import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/klear_car.dart';
import 'cars_providers.dart';

/// Add / edit a car. When [car] is provided the form pre-fills and updates,
/// otherwise it inserts a new car for the current user.
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

  bool get _isEditing => widget.car != null;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.car?.make ?? '');
    _modelController = TextEditingController(text: widget.car?.model ?? '');
    _plateController =
        TextEditingController(text: widget.car?.plateNumber ?? '');
    _size = widget.car?.size ?? KlearCarSize.medium;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await updateCar(
          ref,
          KlearCar(
            id: widget.car!.id,
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
        await addCar(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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