// lib/feature/smart_plug/models/smart_plug_model.dart

class SmartPlugModel {
  final String id;
  final String plugId;
  final String name;
  final String vendor;
  final String? location;
  final bool isOnline;
  final bool isSimulated;
  final double baselineWattage;
  final SmartPlugLastReading? lastReading;
  final SmartPlugAppliance? appliance;
  final DateTime createdAt;

  const SmartPlugModel({
    required this.id,
    required this.plugId,
    required this.name,
    required this.vendor,
    this.location,
    required this.isOnline,
    required this.isSimulated,
    required this.baselineWattage,
    this.lastReading,
    this.appliance,
    required this.createdAt,
  });

  factory SmartPlugModel.fromMap(Map<String, dynamic> map) {
    return SmartPlugModel(
      id:               map['id'] as String? ?? map['_id'] as String? ?? '',
      plugId:           map['plugId'] as String? ?? '',
      name:             map['name'] as String? ?? 'Unknown Plug',
      vendor:           map['vendor'] as String? ?? 'simulator',
      location:         map['location'] as String?,
      isOnline:         map['isOnline'] as bool? ?? false,
      isSimulated:      map['isSimulated'] as bool? ?? true,
      baselineWattage:  (map['baselineWattage'] as num?)?.toDouble() ?? 0.0,
      lastReading: map['lastReading'] != null
          ? SmartPlugLastReading.fromMap(
              (map['lastReading'] as Map).cast<String, dynamic>())
          : null,
      appliance: map['applianceId'] != null && map['applianceId'] is Map
          ? SmartPlugAppliance.fromMap(
              (map['applianceId'] as Map).cast<String, dynamic>())
          : null,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SmartPlugLastReading {
  final double? wattage;
  final DateTime? timestamp;
  final bool isAnomaly;

  const SmartPlugLastReading({
    this.wattage,
    this.timestamp,
    required this.isAnomaly,
  });

  factory SmartPlugLastReading.fromMap(Map<String, dynamic> map) {
    return SmartPlugLastReading(
      wattage:   (map['wattage'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? ''),
      isAnomaly: map['isAnomaly'] as bool? ?? false,
    );
  }
}

class SmartPlugAppliance {
  final String id;
  final String title;
  final String category;
  final double wattage;
  final String? svgPath;

  const SmartPlugAppliance({
    required this.id,
    required this.title,
    required this.category,
    required this.wattage,
    this.svgPath,
  });

  factory SmartPlugAppliance.fromMap(Map<String, dynamic> map) {
    return SmartPlugAppliance(
      id:       map['id'] as String? ?? map['_id'] as String? ?? '',
      title:    map['title'] as String? ?? 'Appliance',
      category: map['category'] as String? ?? 'other',
      wattage:  (map['wattage'] as num?)?.toDouble() ?? 0.0,
      svgPath:  map['svgPath'] as String?,
    );
  }
}
