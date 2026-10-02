/// A saved delivery address belonging to a signed-in customer.
///
/// Persisted as an element of the `addresses` array on the `users/{uid}`
/// document, so the existing rule that scopes `users/{uid}` to its owner
/// (`request.auth.uid == uid`) already protects it — no rule change needed.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final bool isDefault;

  /// Single-line rendering used to pre-fill checkout and to confirm orders.
  String get formatted {
    final parts = [street, city, state]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'recipientName': recipientName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'isDefault': isDefault,
      };

  factory SavedAddress.fromMap(Map<String, dynamic> map) => SavedAddress(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? 'Address',
        recipientName: map['recipientName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        street: map['street'] as String? ?? '',
        city: map['city'] as String? ?? '',
        state: map['state'] as String? ?? '',
        isDefault: map['isDefault'] as bool? ?? false,
      );

  SavedAddress copyWith({
    String? label,
    String? recipientName,
    String? phone,
    String? street,
    String? city,
    String? state,
    bool? isDefault,
  }) =>
      SavedAddress(
        id: id,
        label: label ?? this.label,
        recipientName: recipientName ?? this.recipientName,
        phone: phone ?? this.phone,
        street: street ?? this.street,
        city: city ?? this.city,
        state: state ?? this.state,
        isDefault: isDefault ?? this.isDefault,
      );
}
