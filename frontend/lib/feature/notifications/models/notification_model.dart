class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime sentAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.read,
    required this.sentAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? map['_id'] as String,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'generic',
      data:
          (map['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      read: map['read'] as bool? ?? false,
      sentAt:
          DateTime.tryParse(map['sentAt'] as String? ?? '') ??
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// True when this notification represents an abnormal power consumption alert.
  bool get isAnomalyAlert =>
      type == 'high_usage_alert' || type == 'smart_plug_anomaly';

  /// Plug name extracted from data payload (if present).
  String? get anomalyPlugName => data['plugName'] as String?;

  /// Wattage string extracted from data payload (if present).
  String? get anomalyWattage => data['wattage'] as String?;
}
