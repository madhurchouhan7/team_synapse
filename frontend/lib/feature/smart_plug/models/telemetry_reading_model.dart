// lib/feature/smart_plug/models/telemetry_reading_model.dart

class TelemetryReading {
  final String id;
  final String plugId;
  final double wattage;
  final double? voltage;
  final double? current;
  final double? powerFactor;
  final bool isAnomaly;
  final double? anomalyScore;
  final String? anomalyReason;
  final DateTime timestamp;

  const TelemetryReading({
    required this.id,
    required this.plugId,
    required this.wattage,
    this.voltage,
    this.current,
    this.powerFactor,
    required this.isAnomaly,
    this.anomalyScore,
    this.anomalyReason,
    required this.timestamp,
  });

  factory TelemetryReading.fromMap(Map<String, dynamic> map) {
    return TelemetryReading(
      id:           map['id'] as String? ?? map['_id'] as String? ?? '',
      plugId:       map['plugId'] as String? ?? '',
      wattage:      (map['wattage'] as num?)?.toDouble() ?? 0.0,
      voltage:      (map['voltage'] as num?)?.toDouble(),
      current:      (map['current'] as num?)?.toDouble(),
      powerFactor:  (map['powerFactor'] as num?)?.toDouble(),
      isAnomaly:    map['isAnomaly'] as bool? ?? false,
      anomalyScore: (map['anomalyScore'] as num?)?.toDouble(),
      anomalyReason: map['anomalyReason'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
