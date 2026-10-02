import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/app_logger.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/saved_address.dart';
import '../providers/user_profile_provider.dart';

/// Manage the customer's saved delivery addresses. Stored on `users/{uid}`,
/// which the security rules already scope to the owning account.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(userProfileValueProvider).addresses;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add address', style: TextStyle(color: Colors.white)),
      ),
      body: addresses.isEmpty
          ? const _EmptyAddresses()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _AddressTile(
                  address: address,
                  onEdit: () => _openEditor(context, ref, address),
                  onDelete: () => _confirmDelete(context, ref, address),
                  onSetDefault: address.isDefault
                      ? null
                      : () => ref
                          .read(userDataControllerProvider)
                          .setDefaultAddress(address.id),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    SavedAddress? existing,
  ) async {
    final result = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressEditor(address: existing),
    );
    if (result == null) return;
    await ref.read(userDataControllerProvider).saveAddress(result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('"${address.label}" will be removed from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(userDataControllerProvider).deleteAddress(address.id);
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault ? AppTheme.primaryColor : Colors.grey[200]!,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(address.formatted, style: TextStyle(color: Colors.grey[700])),
          if (address.recipientName.isNotEmpty || address.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [address.recipientName, address.phone]
                  .where((s) => s.trim().isNotEmpty)
                  .join(' · '),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              if (onSetDefault != null)
                TextButton(
                  onPressed: onSetDefault,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Set as default'),
                ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No saved addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save an address to check out faster next time.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit form. Returns the assembled [SavedAddress] via `Navigator.pop`.
class _AddressEditor extends StatefulWidget {
  const _AddressEditor({this.address});

  final SavedAddress? address;

  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _label = TextEditingController(text: a?.label ?? '');
    _name = TextEditingController(text: a?.recipientName ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _street = TextEditingController(text: a?.street ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final address = SavedAddress(
      id: widget.address?.id ?? const Uuid().v4(),
      label: _label.text.trim(),
      recipientName: _name.text.trim(),
      phone: _phone.text.trim(),
      street: _street.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      isDefault: _isDefault,
    );
    AppLogger.debug('Saved address submitted', tag: 'profile');
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.address == null ? 'Add address' : 'Edit address',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _field(_label, 'Label (e.g. Home, Office)', Icons.label_outline),
              _field(_name, 'Recipient name', Icons.person_outline),
              _field(
                _phone,
                'Phone number',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _field(_street, 'Street address', Icons.home_outlined,
                  maxLines: 2),
              _field(_city, 'City', Icons.location_city_outlined),
              _field(_state, 'State', Icons.map_outlined),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use as default address'),
                value: _isDefault,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}
