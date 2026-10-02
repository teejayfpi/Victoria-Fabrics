import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error/error_mapper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/user_profile_provider.dart';

/// Edit the customer's own name and phone.
///
/// Values are stored on `users/{uid}` (owner-scoped by the security rules) and
/// pre-fill checkout, so a returning customer does not retype them. The Google
/// account name is only used as a starting suggestion.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userDataControllerProvider).saveContactDetails(
            displayName: _name.text,
            phone: _phone.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e, st) {
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
    final profile = ref.watch(userProfileValueProvider);
    final user = ref.watch(currentUserProvider);

    if (!_initialised) {
      _name.text = profile.displayName.isNotEmpty
          ? profile.displayName
          : (user?.displayName ?? '');
      _phone.text = profile.phone;
      _initialised = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 40, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Enter your phone number';
                  if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Email is managed by your sign-in provider.',
                ),
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
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
