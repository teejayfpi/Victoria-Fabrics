/// Reusable, testable form validators.
///
/// Kept free of Flutter widget imports so they can be unit-tested directly and
/// reused by any form layer.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(
    r'^[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$',
  );

  // Nigerian MSISDN: optional +234 / 0 prefix followed by a 10-digit national
  // number starting with 7, 8 or 9. Deliberately permissive about separators.
  static final RegExp _phone = RegExp(r'^(\+?234|0)[789]\d{9}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required';
    if (!_email.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Normalises a Nigerian phone number to `+234XXXXXXXXXX`.
  static String? phone(String? value) {
    final digits = _digits(value);
    if (digits.isEmpty) return 'Phone number is required';
    if (!_phone.hasMatch(digits)) {
      return 'Enter a valid Nigerian phone number';
    }
    return null;
  }

  static String? name(String? value, {String field = 'Name'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    if (trimmed.length < 2) return '$field is too short';
    if (trimmed.length > 80) return '$field is too long';
    return null;
  }

  static String? address(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Delivery address is required';
    if (trimmed.length < 10) return 'Enter a more complete address';
    if (trimmed.length > 240) return 'Address is too long';
    return null;
  }

  static String? message(
    String? value, {
    int minLength = 10,
    int maxLength = 1000,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Please enter a message';
    if (trimmed.length < minLength) {
      return 'Please provide at least $minLength characters';
    }
    if (trimmed.length > maxLength) {
      return 'Message is too long (max $maxLength characters)';
    }
    return null;
  }

  /// Normalises a phone number to `+234XXXXXXXXXX`, or returns the input's
  /// digits when it cannot be parsed.
  static String normalisePhone(String? value) {
    final digits = _digits(value);
    if (digits.isEmpty) return '';
    if (digits.startsWith('234')) return '+$digits';
    if (digits.startsWith('0')) return '+234${digits.substring(1)}';
    return '+234$digits';
  }

  static String _digits(String? value) =>
      (value ?? '').replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');
}
