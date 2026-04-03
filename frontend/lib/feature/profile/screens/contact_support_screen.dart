import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/profile/models/contact_support_models.dart';
import 'package:watt_sense/feature/profile/provider/contact_support_provider.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactSupportProvider);
    final notifier = ref.read(contactSupportProvider.notifier);
    final draft = state.draft;

    _syncControllers(draft);

    final isSubmitting =
        state.status == ContactSupportSubmissionStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F8FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SupportHeroCard(),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Issue Details',
              icon: Icons.report_problem_outlined,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('supportCategoryField'),
                    initialValue: draft.category.isEmpty
                        ? null
                        : draft.category,
                    decoration: _inputDecoration(
                      label: 'Category',
                      error: state.fieldErrors['category'],
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'billing',
                        child: Text('Billing'),
                      ),
                      DropdownMenuItem(
                        value: 'outage',
                        child: Text('Power Outage'),
                      ),
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('Technical'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (value) => notifier.updateCategory(value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('supportMessageField'),
                    controller: _messageController,
                    maxLines: 5,
                    enabled: !isSubmitting,
                    onChanged: notifier.updateMessage,
                    decoration: _inputDecoration(
                      label: 'Message',
                      hint: 'Describe what happened, when, and what you tried.',
                      error: state.fieldErrors['message'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Contact Information',
              icon: Icons.contact_mail_outlined,
              child: Column(
                children: [
                  TextField(
                    key: const Key('supportContactNameField'),
                    controller: _nameController,
                    enabled: !isSubmitting,
                    onChanged: notifier.updateContactName,
                    decoration: _inputDecoration(
                      label: 'Your name',
                      error: state.fieldErrors['contactName'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SupportContactMethod>(
                    key: const Key('supportContactMethodField'),
                    initialValue: draft.contactMethod,
                    decoration: _inputDecoration(
                      label: 'Preferred contact method',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SupportContactMethod.email,
                        child: Text('Email'),
                      ),
                      DropdownMenuItem(
                        value: SupportContactMethod.phone,
                        child: Text('Phone'),
                      ),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              notifier.updateContactMethod(value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  if (draft.contactMethod == SupportContactMethod.email)
                    TextField(
                      key: const Key('supportEmailField'),
                      controller: _emailController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: notifier.updateEmail,
                      decoration: _inputDecoration(
                        label: 'Email',
                        error: state.fieldErrors['email'],
                      ),
                    )
                  else
                    TextField(
                      key: const Key('supportPhoneField'),
                      controller: _phoneController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.phone,
                      onChanged: notifier.updatePhone,
                      decoration: _inputDecoration(
                        label: 'Phone',
                        error: state.fieldErrors['phone'],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: CheckboxListTile(
                key: const Key('supportConsentField'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                value: draft.consentAccepted,
                onChanged: isSubmitting
                    ? null
                    : (value) => notifier.updateConsentAccepted(value ?? false),
                title: Text(
                  'I consent to storing this support request for assistance and audit history.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                subtitle: state.fieldErrors['consent'] == null
                    ? null
                    : Text(
                        state.fieldErrors['consent']!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB42318),
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('supportSubmitButton'),
              onPressed: isSubmitting ? null : notifier.submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSubmitting ? 'Submitting...' : 'Submit Ticket',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            if (state.status ==
                ContactSupportSubmissionStatus.retryableError) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('supportRetryButton'),
                onPressed: notifier.retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
            if ((state.message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _StatusCard(
                message: state.message!,
                isSuccess:
                    state.status == ContactSupportSubmissionStatus.success,
              ),
            ],
            if ((state.ticketRef ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  title: Text(
                    'Ticket Reference',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    state.ticketRef!,
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.confirmation_number_outlined),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? error,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
    );
  }

  void _syncControllers(ContactSupportDraft draft) {
    if (_messageController.text != draft.message) {
      _messageController.text = draft.message;
    }
    if (_nameController.text != draft.contactName) {
      _nameController.text = draft.contactName;
    }
    if (_emailController.text != draft.email) {
      _emailController.text = draft.email;
    }
    if (_phoneController.text != draft.phone) {
      _phoneController.text = draft.phone;
    }
  }
}

class _SupportHeroCard extends StatelessWidget {
  const _SupportHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Share complete details so we can create a faster, trackable resolution ticket.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final background = isSuccess
        ? const Color(0xFFECFDF3)
        : const Color(0xFFFEF3F2);
    final border = isSuccess
        ? const Color(0xFFABEFC6)
        : const Color(0xFFFECACA);
    final textColor = isSuccess
        ? const Color(0xFF027A48)
        : const Color(0xFFB42318);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
