import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/profile/models/contact_support_models.dart';
import 'package:watt_sense/feature/profile/repository/support_repository.dart';

final supportRepositoryProvider = Provider<ISupportRepository>((ref) {
  return SupportRepository();
});

final contactSupportProvider =
    StateNotifierProvider.autoDispose<
      ContactSupportController,
      ContactSupportState
    >((ref) {
      return ContactSupportController(
        repository: ref.read(supportRepositoryProvider),
      );
    });

enum ContactSupportSubmissionStatus {
  idle,
  submitting,
  validationError,
  success,
  retryableError,
  fatalError,
}

class ContactSupportDraft {
  const ContactSupportDraft({
    this.category = '',
    this.message = '',
    this.contactName = '',
    this.contactMethod = SupportContactMethod.email,
    this.email = '',
    this.phone = '',
    this.consentAccepted = false,
  });

  final String category;
  final String message;
  final String contactName;
  final SupportContactMethod contactMethod;
  final String email;
  final String phone;
  final bool consentAccepted;

  ContactSupportDraft copyWith({
    String? category,
    String? message,
    String? contactName,
    SupportContactMethod? contactMethod,
    String? email,
    String? phone,
    bool? consentAccepted,
  }) {
    return ContactSupportDraft(
      category: category ?? this.category,
      message: message ?? this.message,
      contactName: contactName ?? this.contactName,
      contactMethod: contactMethod ?? this.contactMethod,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      consentAccepted: consentAccepted ?? this.consentAccepted,
    );
  }
}

class ContactSupportState {
  const ContactSupportState({
    required this.status,
    required this.draft,
    required this.fieldErrors,
    this.message,
    this.ticketRef,
    this.requestId,
    this.timestamp,
    this.retryAfterSeconds,
    this.recoveryActionLabel = '',
  });

  final ContactSupportSubmissionStatus status;
  final ContactSupportDraft draft;
  final Map<String, String> fieldErrors;
  final String? message;
  final String? ticketRef;
  final String? requestId;
  final String? timestamp;
  final int? retryAfterSeconds;
  final String recoveryActionLabel;

  factory ContactSupportState.initial() {
    return const ContactSupportState(
      status: ContactSupportSubmissionStatus.idle,
      draft: ContactSupportDraft(),
      fieldErrors: <String, String>{},
      recoveryActionLabel: '',
    );
  }

  ContactSupportState copyWith({
    ContactSupportSubmissionStatus? status,
    ContactSupportDraft? draft,
    Map<String, String>? fieldErrors,
    String? message,
    String? ticketRef,
    String? requestId,
    String? timestamp,
    int? retryAfterSeconds,
    String? recoveryActionLabel,
    bool clearServerMeta = false,
  }) {
    return ContactSupportState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      message: message ?? this.message,
      ticketRef: clearServerMeta ? null : (ticketRef ?? this.ticketRef),
      requestId: clearServerMeta ? null : (requestId ?? this.requestId),
      timestamp: clearServerMeta ? null : (timestamp ?? this.timestamp),
      retryAfterSeconds: clearServerMeta
          ? null
          : (retryAfterSeconds ?? this.retryAfterSeconds),
      recoveryActionLabel: recoveryActionLabel ?? this.recoveryActionLabel,
    );
  }
}

class ContactSupportController extends StateNotifier<ContactSupportState> {
  ContactSupportController({required ISupportRepository repository})
    : _repository = repository,
      super(ContactSupportState.initial());

  final ISupportRepository _repository;

  Future<bool> Function()? _lastAction;

  void updateCategory(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(category: value),
      fieldErrors: _removeFieldError('category'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updateMessage(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(message: value),
      fieldErrors: _removeFieldError('message'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updateContactName(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(contactName: value),
      fieldErrors: _removeFieldError('contactName'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updateContactMethod(SupportContactMethod value) {
    state = state.copyWith(
      draft: state.draft.copyWith(contactMethod: value),
      fieldErrors: _removeFieldError(
        value == SupportContactMethod.email ? 'email' : 'phone',
      ),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updateEmail(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(email: value),
      fieldErrors: _removeFieldError('email'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updatePhone(String value) {
    state = state.copyWith(
      draft: state.draft.copyWith(phone: value),
      fieldErrors: _removeFieldError('phone'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  void updateConsentAccepted(bool value) {
    state = state.copyWith(
      draft: state.draft.copyWith(consentAccepted: value),
      fieldErrors: _removeFieldError('consent'),
      status: ContactSupportSubmissionStatus.idle,
      clearServerMeta: true,
    );
  }

  Future<bool> submit() async {
    Future<bool> run() async {
      final validationErrors = _validate(state.draft);
      if (validationErrors.isNotEmpty) {
        state = state.copyWith(
          status: ContactSupportSubmissionStatus.validationError,
          fieldErrors: validationErrors,
          message: 'Please review the highlighted fields and try again.',
          recoveryActionLabel: 'Fix fields',
          clearServerMeta: true,
        );
        return false;
      }

      state = state.copyWith(
        status: ContactSupportSubmissionStatus.submitting,
        fieldErrors: const <String, String>{},
        message: 'Submitting support request...',
        recoveryActionLabel: '',
        clearServerMeta: true,
      );

      try {
        final result = await _repository.submitTicket(
          _buildRequest(state.draft),
        );

        state = state.copyWith(
          status: ContactSupportSubmissionStatus.success,
          message: 'Support request submitted successfully.',
          ticketRef: result.ticketRef,
          requestId: result.requestId,
          timestamp: result.timestamp,
          recoveryActionLabel: '',
        );
        return true;
      } on SupportSubmissionException catch (error) {
        if (error.isRetryable) {
          final retryHint = error.retryAfterSeconds == null
              ? 'Please retry in a few moments.'
              : 'Please retry after ${error.retryAfterSeconds} seconds.';

          state = state.copyWith(
            status: ContactSupportSubmissionStatus.retryableError,
            message: '${error.message} $retryHint',
            requestId: error.requestId,
            timestamp: error.timestamp,
            retryAfterSeconds: error.retryAfterSeconds,
            recoveryActionLabel: 'Retry',
          );
          return false;
        }

        state = state.copyWith(
          status: ContactSupportSubmissionStatus.fatalError,
          message: error.message,
          requestId: error.requestId,
          timestamp: error.timestamp,
          recoveryActionLabel: 'Try later',
        );
        return false;
      }
    }

    _lastAction = run;
    return run();
  }

  Future<bool> retry() async {
    if (_lastAction == null) {
      return false;
    }
    return _lastAction!.call();
  }

  ContactSupportTicketRequest _buildRequest(ContactSupportDraft draft) {
    return ContactSupportTicketRequest(
      category: draft.category.trim(),
      message: draft.message.trim(),
      preferredContact: SupportPreferredContact(
        name: draft.contactName.trim(),
        method: draft.contactMethod,
        email: draft.contactMethod == SupportContactMethod.email
            ? draft.email.trim()
            : null,
        phone: draft.contactMethod == SupportContactMethod.phone
            ? draft.phone.trim()
            : null,
      ),
      consent: SupportConsentSnapshot(
        policySlug: 'support-privacy',
        consentVersion: '2026.03',
        acceptedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Map<String, String> _validate(ContactSupportDraft draft) {
    final errors = <String, String>{};

    if (draft.category.trim().isEmpty) {
      errors['category'] = 'Category is required.';
    }

    if (draft.message.trim().isEmpty) {
      errors['message'] = 'Message is required.';
    } else if (draft.message.trim().length < 10) {
      errors['message'] = 'Message must be at least 10 characters.';
    }

    if (draft.contactName.trim().isEmpty) {
      errors['contactName'] = 'Contact name is required.';
    }

    if (draft.contactMethod == SupportContactMethod.email) {
      final email = draft.email.trim();
      if (email.isEmpty) {
        errors['email'] = 'Email is required for email contact.';
      } else if (!email.contains('@')) {
        errors['email'] = 'Enter a valid email address.';
      }
    } else {
      final phone = draft.phone.trim();
      if (phone.isEmpty) {
        errors['phone'] = 'Phone is required for phone contact.';
      } else if (phone.length < 7) {
        errors['phone'] = 'Phone must be at least 7 digits.';
      }
    }

    if (!draft.consentAccepted) {
      errors['consent'] = 'You must accept support data processing consent.';
    }

    return errors;
  }

  Map<String, String> _removeFieldError(String key) {
    if (!state.fieldErrors.containsKey(key)) {
      return state.fieldErrors;
    }

    final next = Map<String, String>.from(state.fieldErrors);
    next.remove(key);
    return next;
  }
}
