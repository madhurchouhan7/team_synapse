import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/content/models/content_models.dart';
import 'package:watt_sense/feature/content/repository/content_repository.dart';

final contentRepositoryProvider = Provider<IContentRepository>((ref) {
  return ContentRepository();
});

final faqSearchQueryProvider = StateProvider<String>((ref) => '');
final faqSelectedTopicProvider = StateProvider<String>((ref) => 'all');
final legalSlugProvider = StateProvider<String>((ref) => 'terms');

class FaqContentState {
  const FaqContentState({
    required this.allItems,
    required this.filteredItems,
    required this.topics,
    required this.query,
    required this.selectedTopic,
    required this.emptyGuidance,
    required this.feedback,
    required this.metadata,
  });

  final List<FaqItem> allItems;
  final List<FaqItem> filteredItems;
  final List<String> topics;
  final String query;
  final String selectedTopic;
  final String emptyGuidance;
  final String feedback;
  final ContentFreshnessMetadata metadata;
}

final faqContentProvider =
    AsyncNotifierProvider<FaqContentNotifier, FaqContentState>(
      FaqContentNotifier.new,
    );

class FaqContentNotifier extends AsyncNotifier<FaqContentState> {
  @override
  FutureOr<FaqContentState> build() async {
    final query = ref.read(faqSearchQueryProvider);
    final topic = ref.read(faqSelectedTopicProvider);
    return _load(query: query, selectedTopic: topic, forceRefresh: false);
  }

  Future<void> setQuery(String value) async {
    ref.read(faqSearchQueryProvider.notifier).state = value;
    await _reload(forceRefresh: false);
  }

  Future<void> setTopic(String value) async {
    ref.read(faqSelectedTopicProvider.notifier).state = value;
    await _reload(forceRefresh: false);
  }

  Future<void> retry() async {
    await _reload(forceRefresh: false);
  }

  Future<void> refreshContent() async {
    await _reload(forceRefresh: true);
  }

  Future<void> _reload({required bool forceRefresh}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _load(
        query: ref.read(faqSearchQueryProvider),
        selectedTopic: ref.read(faqSelectedTopicProvider),
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<FaqContentState> _load({
    required String query,
    required String selectedTopic,
    required bool forceRefresh,
  }) async {
    final response = await ref
        .read(contentRepositoryProvider)
        .fetchFaqs(
          query: query,
          topic: selectedTopic,
          forceRefresh: forceRefresh,
        );

    final allItems = response.payload.items;
    final normalizedTopic = selectedTopic.trim().toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = allItems
        .where((item) {
          if (normalizedTopic.isEmpty || normalizedTopic == 'all') {
            return true;
          }
          return item.topic.toLowerCase() == normalizedTopic;
        })
        .where((item) {
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return item.question.toLowerCase().contains(normalizedQuery) ||
              item.answer.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    final uniqueTopics = <String>{
      'all',
      ...allItems
          .map((item) => item.topic)
          .where((topic) => topic.trim().isNotEmpty),
    }.toList(growable: false);

    return FaqContentState(
      allItems: allItems,
      filteredItems: filtered,
      topics: uniqueTopics,
      query: query,
      selectedTopic: selectedTopic,
      emptyGuidance: filtered.isEmpty
          ? 'No matching FAQs. Try a different keyword.'
          : '',
      feedback: response.unchanged ? 'Already up to date.' : '',
      metadata: response.metadata,
    );
  }
}

final billGuideProvider =
    AsyncNotifierProvider<BillGuideNotifier, BillGuideState>(
      BillGuideNotifier.new,
    );

class BillGuideState {
  const BillGuideState({
    required this.payload,
    required this.feedback,
    required this.metadata,
  });

  final BillGuidePayload payload;
  final String feedback;
  final ContentFreshnessMetadata metadata;
}

class BillGuideNotifier extends AsyncNotifier<BillGuideState> {
  @override
  FutureOr<BillGuideState> build() async {
    return _load(forceRefresh: false);
  }

  Future<void> retry() async {
    await _reload(forceRefresh: false);
  }

  Future<void> refreshContent() async {
    await _reload(forceRefresh: true);
  }

  Future<void> _reload({required bool forceRefresh}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _load(forceRefresh: forceRefresh),
    );
  }

  Future<BillGuideState> _load({required bool forceRefresh}) async {
    final response = await ref
        .read(contentRepositoryProvider)
        .fetchBillGuide(forceRefresh: forceRefresh);
    return BillGuideState(
      payload: response.payload,
      feedback: response.unchanged ? 'Already up to date.' : '',
      metadata: response.metadata,
    );
  }
}

class LegalContentState {
  const LegalContentState({
    required this.payload,
    required this.feedback,
    required this.metadata,
    required this.statusCode,
  });

  final LegalContentPayload payload;
  final String feedback;
  final ContentFreshnessMetadata metadata;
  final int statusCode;
}

final legalContentProvider =
    AsyncNotifierProvider<LegalContentNotifier, LegalContentState>(
      LegalContentNotifier.new,
    );

class LegalContentNotifier extends AsyncNotifier<LegalContentState> {
  @override
  FutureOr<LegalContentState> build() async {
    final slug = ref.read(legalSlugProvider);
    return _load(slug: slug, forceRefresh: false);
  }

  Future<void> setSlug(String slug) async {
    ref.read(legalSlugProvider.notifier).state = slug;
    await _reload(forceRefresh: false);
  }

  Future<void> retry() async {
    await _reload(forceRefresh: false);
  }

  Future<void> refreshContent() async {
    await _reload(forceRefresh: true);
  }

  Future<void> _reload({required bool forceRefresh}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final slug = ref.read(legalSlugProvider);
      return _load(slug: slug, forceRefresh: forceRefresh);
    });
  }

  Future<LegalContentState> _load({
    required String slug,
    required bool forceRefresh,
  }) async {
    final response = await ref
        .read(contentRepositoryProvider)
        .fetchLegalDocument(slug, forceRefresh: forceRefresh);

    final feedback = response.statusCode == 304
        ? 'Already up to date.'
        : 'Content updated to ${response.payload.contentVersion}';

    return LegalContentState(
      payload: response.payload,
      feedback: feedback,
      metadata: response.metadata,
      statusCode: response.statusCode,
    );
  }
}
