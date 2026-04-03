import 'package:dio/dio.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/content/models/content_models.dart';

abstract class IContentRepository {
  Future<ContentResponse<FaqContentPayload>> fetchFaqs({
    String query = '',
    String topic = '',
    bool forceRefresh = false,
  });

  Future<ContentResponse<BillGuidePayload>> fetchBillGuide({
    bool forceRefresh = false,
  });

  Future<ContentResponse<LegalContentPayload>> fetchLegalDocument(
    String slug, {
    bool forceRefresh = false,
  });
}

class ContentRepository implements IContentRepository {
  ContentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;
  final Map<String, ContentFreshnessMetadata> _metadataCache =
      <String, ContentFreshnessMetadata>{};
  final Map<String, Object> _payloadCache = <String, Object>{};

  static const String _faqPath = '/content/faqs';
  static const String _billGuidePath = '/content/bill-guide';
  static const String _legalPath = '/content/legal';

  @override
  Future<ContentResponse<FaqContentPayload>> fetchFaqs({
    String query = '',
    String topic = '',
    bool forceRefresh = false,
  }) async {
    final key =
        'faqs::${query.trim().toLowerCase()}::${topic.trim().toLowerCase()}';
    final response = await _getWithConditionalHeaders(
      path: _faqPath,
      cacheKey: key,
      queryParams: <String, dynamic>{
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (topic.trim().isNotEmpty) 'topic': topic.trim(),
      },
      forceRefresh: forceRefresh,
    );

    if (response.statusCode == 304) {
      final cached = _payloadCache[key];
      if (cached is FaqContentPayload) {
        return ContentResponse<FaqContentPayload>(
          payload: cached,
          statusCode: 304,
          metadata: _metadataCache[key] ?? cached.metadata,
        );
      }
    }

    final envelope = _extractEnvelope(response.data);
    final faqItems = _extractList(envelope, const [
      'items',
      'faqs',
    ]).map(FaqItem.fromJson).toList(growable: false);

    final metadata = _resolveMetadata(
      cacheKey: key,
      response: response,
      envelope: envelope,
    );

    final payload = FaqContentPayload(items: faqItems, metadata: metadata);
    _payloadCache[key] = payload;

    return ContentResponse<FaqContentPayload>(
      payload: payload,
      statusCode: response.statusCode ?? 200,
      metadata: metadata,
    );
  }

  @override
  Future<ContentResponse<BillGuidePayload>> fetchBillGuide({
    bool forceRefresh = false,
  }) async {
    const key = 'bill-guide';
    final response = await _getWithConditionalHeaders(
      path: _billGuidePath,
      cacheKey: key,
      forceRefresh: forceRefresh,
    );

    if (response.statusCode == 304) {
      final cached = _payloadCache[key];
      if (cached is BillGuidePayload) {
        return ContentResponse<BillGuidePayload>(
          payload: cached,
          statusCode: 304,
          metadata: _metadataCache[key] ?? cached.metadata,
        );
      }
    }

    final envelope = _extractEnvelope(response.data);
    final sections = _extractList(envelope, const [
      'sections',
    ]).map(BillGuideSection.fromJson).toList(growable: false);
    final glossary = _extractList(envelope, const [
      'glossary',
      'terms',
    ]).map(BillGlossaryTerm.fromJson).toList(growable: false);

    final metadata = _resolveMetadata(
      cacheKey: key,
      response: response,
      envelope: envelope,
    );

    final payload = BillGuidePayload(
      sections: sections,
      glossary: glossary,
      metadata: metadata,
    );
    _payloadCache[key] = payload;

    return ContentResponse<BillGuidePayload>(
      payload: payload,
      statusCode: response.statusCode ?? 200,
      metadata: metadata,
    );
  }

  @override
  Future<ContentResponse<LegalContentPayload>> fetchLegalDocument(
    String slug, {
    bool forceRefresh = false,
  }) async {
    final normalizedSlug = slug.trim().isEmpty ? 'terms' : slug.trim();
    final key = 'legal::$normalizedSlug';

    final response = await _getWithConditionalHeaders(
      path: '$_legalPath/$normalizedSlug',
      cacheKey: key,
      forceRefresh: forceRefresh,
    );

    if (response.statusCode == 304) {
      final cached = _payloadCache[key];
      if (cached is LegalContentPayload) {
        return ContentResponse<LegalContentPayload>(
          payload: cached,
          statusCode: 304,
          metadata: _metadataCache[key] ?? cached.metadata,
        );
      }
    }

    final envelope = _extractEnvelope(response.data);
    final metadata = _resolveMetadata(
      cacheKey: key,
      response: response,
      envelope: envelope,
    );
    final payload = LegalContentPayload.fromJson(envelope, metadata);

    _payloadCache[key] = payload;

    return ContentResponse<LegalContentPayload>(
      payload: payload,
      statusCode: response.statusCode ?? 200,
      metadata: metadata,
    );
  }

  Future<Response<dynamic>> _getWithConditionalHeaders({
    required String path,
    required String cacheKey,
    Map<String, dynamic>? queryParams,
    required bool forceRefresh,
  }) async {
    final previousMetadata = _metadataCache[cacheKey];
    final headers = <String, String>{
      if (!forceRefresh && previousMetadata?.etag != null)
        'If-None-Match': previousMetadata!.etag!,
      'Cache-Control': 'no-cache',
    };

    try {
      return await _apiClient.get<dynamic>(
        path,
        queryParams: queryParams,
        options: Options(
          headers: headers,
          validateStatus: (code) {
            if (code == null) {
              return false;
            }
            return code >= 200 && code < 300 || code == 304;
          },
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  ContentFreshnessMetadata _resolveMetadata({
    required String cacheKey,
    required Response<dynamic> response,
    required Map<String, dynamic> envelope,
  }) {
    final previous =
        _metadataCache[cacheKey] ?? const ContentFreshnessMetadata();

    final headers = response.headers;
    final etag = _firstHeader(headers, 'etag') ?? previous.etag;
    final contentVersion =
        (envelope['contentVersion'] ?? previous.contentVersion ?? '')
            .toString();
    final lastUpdatedAt =
        (envelope['lastUpdatedAt'] ?? previous.lastUpdatedAt ?? '').toString();

    final metadata = ContentFreshnessMetadata(
      etag: etag,
      contentVersion: contentVersion,
      lastUpdatedAt: lastUpdatedAt,
    );

    _metadataCache[cacheKey] = metadata;
    return metadata;
  }

  String? _firstHeader(Headers headers, String key) {
    final values = headers.map[key.toLowerCase()];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  Map<String, dynamic> _extractEnvelope(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return data;
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }
}
