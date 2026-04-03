enum SupportContactMethod { email, phone }

class SupportPreferredContact {
  const SupportPreferredContact({
    required this.name,
    required this.method,
    this.email,
    this.phone,
  });

  final String name;
  final SupportContactMethod method;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'method': method.name,
      if (email != null && email!.trim().isNotEmpty) 'email': email,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone,
    };
  }
}

class SupportConsentSnapshot {
  const SupportConsentSnapshot({
    required this.policySlug,
    required this.consentVersion,
    required this.acceptedAt,
  });

  final String policySlug;
  final String consentVersion;
  final DateTime acceptedAt;

  Map<String, dynamic> toJson() {
    return {
      'policySlug': policySlug,
      'consentVersion': consentVersion,
      'acceptedAt': acceptedAt.toUtc().toIso8601String(),
    };
  }
}

class ContactSupportTicketRequest {
  const ContactSupportTicketRequest({
    required this.category,
    required this.message,
    required this.preferredContact,
    required this.consent,
  });

  final String category;
  final String message;
  final SupportPreferredContact preferredContact;
  final SupportConsentSnapshot consent;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'message': message,
      'preferredContact': preferredContact.toJson(),
      'consent': consent.toJson(),
    };
  }
}

class ContactSupportTicketResult {
  const ContactSupportTicketResult({
    required this.ticketRef,
    required this.status,
    this.requestId,
    this.timestamp,
  });

  final String ticketRef;
  final String status;
  final String? requestId;
  final String? timestamp;

  factory ContactSupportTicketResult.fromJson(Map<String, dynamic> json) {
    return ContactSupportTicketResult(
      ticketRef: (json['ticketRef'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestId: json['requestId']?.toString(),
      timestamp: json['timestamp']?.toString(),
    );
  }
}
