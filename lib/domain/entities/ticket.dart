import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String id;
  final String customerName;
  final String customerPhone;
  final String subject;
  final String message;
  final String status; // open | in_progress | resolved
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.subject,
    required this.message,
    this.status = 'open',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SupportTicket.fromMap(String id, Map<String, dynamic> map) {
    DateTime createdAt;
    final raw = map['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else {
      createdAt = DateTime.now();
    }
    return SupportTicket(
      id: id,
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      createdAt: createdAt,
    );
  }

  SupportTicket copyWith({String? status}) {
    return SupportTicket(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
