import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_state.dart';
import '../../domain/entities/store_settings.dart';
import '../../presentation/providers/settings_provider.dart';
import '../providers/admin_auth_provider.dart';

/// Owner-editable store settings: delivery fee, shop address for pickup, and
/// the contact details shown to customers.
///
/// Writes go to `settings/store` (staff-only per the security rules) and the
/// storefront picks the change up through its live stream, so a new delivery
/// fee is reflected on checkout without shipping a build.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(storeSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: AsyncValueView<StoreSettings>(
        value: async,
        onRetry: () => ref.invalidate(storeSettingsStreamProvider),
        builder: (context, settings) => _SettingsForm(initial: settings),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.initial});

  final StoreSettings initial;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _storeName;
  late final TextEditingController _addressLine;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _deliveryFee;
  late final TextEditingController _contactPhone;
  late final TextEditingController _contactWhatsapp;
  late final TextEditingController _contactEmail;
  late bool _deliveryEnabled;
  late bool _pickupEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _storeName = TextEditingController(text: s.storeName);
    _addressLine = TextEditingController(text: s.addressLine);
    _city = TextEditingController(text: s.city);
    _state = TextEditingController(text: s.state);
    _deliveryFee = TextEditingController(
        text: s.deliveryFee == s.deliveryFee.roundToDouble()
            ? s.deliveryFee.toStringAsFixed(0)
            : s.deliveryFee.toStringAsFixed(2));
    _contactPhone = TextEditingController(text: s.contactPhone);
    _contactWhatsapp = TextEditingController(text: s.contactWhatsapp);
    _contactEmail = TextEditingController(text: s.contactEmail);
    _deliveryEnabled = s.deliveryEnabled;
    _pickupEnabled = s.pickupEnabled;
  }

  @override
  void dispose() {
    _storeName.dispose();
    _addressLine.dispose();
    _city.dispose();
    _state.dispose();
    _deliveryFee.dispose();
    _contactPhone.dispose();
    _contactWhatsapp.dispose();
    _contactEmail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // The "at least one fulfilment method" invariant is checked before field
    // validation: it is a whole-form rule, not a per-field one.
    if (!_deliveryEnabled && !_pickupEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable delivery, pickup, or both.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      requireAdmin(ref.read(currentAdminProvider), minimum: AdminRole.staff);
      final updated = StoreSettings(
        storeName: _storeName.text.trim(),
        addressLine: _addressLine.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        deliveryFee: double.parse(_deliveryFee.text.trim()),
        deliveryEnabled: _deliveryEnabled,
        pickupEnabled: _pickupEnabled,
        contactPhone: _contactPhone.text.trim(),
        contactWhatsapp: _contactWhatsapp.text.trim(),
        contactEmail: _contactEmail.text.trim(),
      );

      final result = await ref.read(settingsRepositoryProvider).save(updated);
      result.fold(
        onSuccess: (_) {},
        onError: (failure) => throw Exception(failure.message),
      );

      AppLogger.info('Store settings saved', tag: 'admin_settings');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('Store settings save failed',
          tag: 'admin_settings', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e, st).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Section(
            title: 'Store',
            subtitle: 'Shown to customers on the storefront.',
            children: [
              _field(_storeName, 'Store name', Icons.storefront),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Pickup address',
            subtitle:
                'Where customers collect pickup orders. Leave blank to show '
                'only the store name.',
            children: [
              _field(_addressLine, 'Street address', Icons.home_outlined,
                  maxLines: 2, required: false),
              _field(_city, 'City', Icons.location_city_outlined,
                  required: false),
              _field(_state, 'State', Icons.map_outlined, required: false),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Delivery',
            subtitle: 'Applied to every delivery order at checkout.',
            children: [
              _field(
                _deliveryFee,
                'Delivery fee (${AppConstants.currencySymbol})',
                Icons.local_shipping_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter a number';
                  if (value < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Offer delivery'),
                subtitle: const Text('Customers can choose home delivery'),
                value: _deliveryEnabled,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _deliveryEnabled = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Offer pickup'),
                subtitle: const Text('Customers can collect from the store'),
                value: _pickupEnabled,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _pickupEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Contact',
            subtitle: 'Shown in the customer app for support and payments.',
            children: [
              _field(_contactPhone, 'Phone (display)', Icons.phone_outlined,
                  keyboardType: TextInputType.phone, required: false),
              _field(_contactWhatsapp, 'WhatsApp number', Icons.chat_outlined,
                  keyboardType: TextInputType.phone, required: false),
              _field(_contactEmail, 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  required: false),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppTheme.primaryColor,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator ??
            (v) {
              if (!required) return null;
              return (v == null || v.trim().isEmpty) ? 'Required' : null;
            },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
