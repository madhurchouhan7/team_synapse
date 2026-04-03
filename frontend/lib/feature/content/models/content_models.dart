class ContentFreshnessMetadata {
  const ContentFreshnessMetadata({
    this.etag,
    this.contentVersion,
    this.lastUpdatedAt,
  });

  final String? etag;
  final String? contentVersion;
  final String? lastUpdatedAt;

  ContentFreshnessMetadata copyWith({
    String? etag,
    String? contentVersion,
    String? lastUpdatedAt,
  }) {
    return ContentFreshnessMetadata(
      etag: etag ?? this.etag,
      contentVersion: contentVersion ?? this.contentVersion,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  bool get hasValidator => (etag ?? '').trim().isNotEmpty;
}

class FaqItem {
  const FaqItem({
    required this.id,
    required this.topic,
    required this.question,
    required this.answer,
  });

  final String id;
  final String topic;
  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      topic: (json['topic'] ?? json['category'] ?? 'general').toString(),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
    );
  }
}

class FaqContentPayload {
  const FaqContentPayload({required this.items, required this.metadata});

  final List<FaqItem> items;
  final ContentFreshnessMetadata metadata;
}

class BillGuideSection {
  const BillGuideSection({
    required this.id,
    required this.heading,
    required this.body,
  });

  final String id;
  final String heading;
  final String body;

  factory BillGuideSection.fromJson(Map<String, dynamic> json) {
    return BillGuideSection(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      heading: (json['heading'] ?? json['title'] ?? '').toString(),
      body: (json['body'] ?? json['content'] ?? '').toString(),
    );
  }
}

class BillGlossaryTerm {
  const BillGlossaryTerm({required this.term, required this.definition});

  final String term;
  final String definition;

  factory BillGlossaryTerm.fromJson(Map<String, dynamic> json) {
    return BillGlossaryTerm(
      term: (json['term'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
    );
  }
}

class BillGuidePayload {
  const BillGuidePayload({
    required this.sections,
    required this.glossary,
    required this.metadata,
  });

  final List<BillGuideSection> sections;
  final List<BillGlossaryTerm> glossary;
  final ContentFreshnessMetadata metadata;
}

class LegalContentPayload {
  const LegalContentPayload({
    required this.slug,
    required this.title,
    required this.body,
    required this.contentVersion,
    required this.effectiveFrom,
    required this.lastUpdatedAt,
    required this.metadata,
  });

  final String slug;
  final String title;
  final String body;
  final String contentVersion;
  final String effectiveFrom;
  final String lastUpdatedAt;
  final ContentFreshnessMetadata metadata;

  factory LegalContentPayload.fromJson(
    Map<String, dynamic> json,
    ContentFreshnessMetadata metadata,
  ) {
    final fallbackVersion = metadata.contentVersion ?? '';
    final fallbackUpdated = metadata.lastUpdatedAt ?? '';

    return LegalContentPayload(
      slug: (json['slug'] ?? 'terms').toString(),
      title: (json['title'] ?? json['name'] ?? 'Legal').toString(),
      body: (json['body'] ?? json['content'] ?? '').toString(),
      contentVersion: (json['contentVersion'] ?? fallbackVersion).toString(),
      effectiveFrom: (json['effectiveFrom'] ?? '').toString(),
      lastUpdatedAt: (json['lastUpdatedAt'] ?? fallbackUpdated).toString(),
      metadata: metadata,
    );
  }
}

class ContentResponse<T> {
  const ContentResponse({
    required this.payload,
    required this.statusCode,
    required this.metadata,
  });

  final T payload;
  final int statusCode;
  final ContentFreshnessMetadata metadata;

  bool get unchanged => statusCode == 304;
}
