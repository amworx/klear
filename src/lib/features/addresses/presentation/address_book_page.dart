import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/auth_providers.dart';
import '../data/addresses_repository.dart';
import '../domain/user_address.dart';
import 'addresses_providers.dart';
import 'map_picker_page.dart';

/// The user's address book.
///
/// - [selectable] mode (booking/profile flows): tapping an address pops with
///   a [PickedLocation] for that address.
/// - Management mode (Account tab): tapping shows actions (set default /
///   delete). The FAB opens the map picker to add a new address.
class AddressBookPage extends ConsumerWidget {
  const AddressBookPage({super.key, this.selectable = false});

  final bool selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final addressesAsync = ref.watch(userAddressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectable ? l10n.addressBookSelectTitle : l10n.addressBookTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFromMap(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.addressAddNew),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : addressesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.errorLoadingServices)),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return _EmptyState(l10n: l10n);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _AddressTile(
                      address: address,
                      selectable: selectable,
                      l10n: l10n,
                      onTap: () {
                        if (selectable) {
                          Navigator.of(context).pop(
                            PickedLocation(
                              lat: address.lat,
                              lng: address.lng,
                              address: address.address,
                            ),
                          );
                        } else {
                          _showActions(context, ref, address, l10n);
                        }
                      },
                      onSetDefault: () => _setDefault(context, ref, address),
                      onDelete: () => _delete(context, ref, address, l10n),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _addFromMap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final picked = await context.push<PickedLocation>(KlearRoutes.mapPicker);
    if (picked == null || !context.mounted) return;

    // Ask for a label, then persist.
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _LabelDialog(l10n: l10n),
    );
    if (label == null || !context.mounted) return;

    try {
      await ref.read(addressesRepositoryProvider).insertAddress(
            UserAddress(
              id: '',
              userId: user.id,
              label: label,
              address: picked.address,
              lat: picked.lat,
              lng: picked.lng,
            ),
          );
      ref.invalidate(userAddressesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mapSavedToBook)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingServices)),
      );
    }
  }

  void _showActions(
    BuildContext context,
    WidgetRef ref,
    UserAddress address,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                address.isDefault
                    ? Icons.check_circle
                    : Icons.home_outlined,
              ),
              title: Text(address.label),
              subtitle: Text(address.address, maxLines: 2),
            ),
            const Divider(height: 1),
            if (!address.isDefault)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.addressSetDefault),
                onTap: () {
                  Navigator.of(context).pop();
                  _setDefault(context, ref, address);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                l10n.addressDelete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _delete(context, ref, address, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    UserAddress address,
  ) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      await ref
          .read(addressesRepositoryProvider)
          .setDefaultAddress(user.id, address.id);
      ref.invalidate(userAddressesProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorLoadingServices)),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    UserAddress address,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addressDeleteConfirm),
        content: Text('${address.label} — ${address.address}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addressDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(addressesRepositoryProvider).deleteAddress(address.id);
      ref.invalidate(userAddressesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addressDeleted)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorLoadingServices)),
      );
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selectable,
    required this.l10n,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  final UserAddress address;
  final bool selectable;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            address.isDefault ? Icons.home : Icons.place_outlined,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Text(address.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.addressDefault,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(address.address, maxLines: 2),
        ),
        onTap: onTap,
        trailing: selectable
            ? const Icon(Icons.chevron_right)
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'default') onSetDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!address.isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.star_outline),
                        title: Text(l10n.addressSetDefault),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        l10n.addressDelete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              l10n.addressBookEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addressBookEmptyHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog asking for a label before saving a new address.
class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
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