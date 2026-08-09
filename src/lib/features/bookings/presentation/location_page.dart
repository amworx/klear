import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../app/app_router.dart';
import '../presentation/booking_providers.dart';

/// Step 2: user enters the address where the wash should happen.
class LocationPage extends ConsumerStatefulWidget {
  const LocationPage({super.key});

  @override
  ConsumerState<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<LocationPage> {
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(bookingDraftProvider);
    if (draft.address != null) {
      _addressController.text = draft.address!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(bookingDraftProvider.notifier).setAddress(
            _addressController.text.trim(),
          );
      context.push(KlearRoutes.bookDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterAddress)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: l10n.addressLabel,
                  hintText: l10n.addressHint,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.addressRequired;
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(bookingDraftProvider.notifier).setAddress(value);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _goNext,
            child: Text(l10n.continueLabel),
          ),
        ),
      ),
    );
  }
}
