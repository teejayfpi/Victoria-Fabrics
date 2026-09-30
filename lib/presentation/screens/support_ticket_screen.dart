import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../domain/entities/ticket.dart';
import '../../services/notification_service.dart';

class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ticket = SupportTicket(
        id: const Uuid().v4(),
        customerName: _nameController.text.trim(),
        customerPhone: Validators.normalisePhone(_phoneController.text),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
      );

      final result =
          await ref.read(orderRepositoryProvider).submitTicket(ticket);
      result.fold(
        onSuccess: (_) {},
        onError: (failure) => throw Exception(failure.message),
      );
      AppLogger.info('Support ticket submitted', tag: 'support');

      // Play a confirmation sound for the customer
      await NotificationService.instance.showNotification(
        title: '✅ Ticket Submitted!',
        body:
            'We got your message and will get back to you shortly.',
      );

      if (mounted) setState(() => _submitted = true);
    } catch (e, st) {
      AppLogger.error('Support ticket submission failed',
          tag: 'support', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMapper.map(e, st).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: _submitted ? _buildSuccessView() : _buildForm(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 80, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ticket Submitted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for reaching out. Our team will review your message and contact you at ${_phoneController.text}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
              ),
              child: const Text('Back to Home',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                  _nameController.clear();
                  _phoneController.clear();
                  _subjectController.clear();
                  _messageController.clear();
                });
              },
              child: const Text('Submit Another Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'How can we help?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fill in the form below and our team will get back to you as soon as possible.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.name(v, field: 'Your name'),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '08012345678',
              ),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),

            // Subject
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject *',
                prefixIcon: Icon(Icons.subject_outlined),
                hintText: 'e.g. Order issue, Product enquiry...',
              ),
              validator: (v) => Validators.required(v, field: 'Subject'),
            ),
            const SizedBox(height: 16),

            // Message
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message *',
                hintText: 'Describe your issue or question in detail...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: Validators.message,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Ticket',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
