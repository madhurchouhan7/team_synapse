class SolarEstimateRequest {
  const SolarEstimateRequest({
    required this.monthlyUnits,
    required this.roofArea,
    required this.state,
    required this.discom,
    required this.shadingLevel,
    this.sanctionedLoadKw,
  });

  final double monthlyUnits;
  final double roofArea;
  final String state;
  final String discom;
  final String shadingLevel;
  final double? sanctionedLoadKw;

  Map<String, dynamic> toJson() {
    return {
      'monthlyUnits': monthlyUnits,
      'roofArea': roofArea,
      'state': state,
      'discom': discom,
      'shadingLevel': shadingLevel,
      if (sanctionedLoadKw != null) 'sanctionedLoadKw': sanctionedLoadKw,
    };
  }
}

class SolarRangeValue {
  const SolarRangeValue({
    required this.low,
    required this.base,
    required this.high,
  });

  final double low;
  final double base;
  final double high;

  factory SolarRangeValue.fromJson(Map<String, dynamic> json) {
    return SolarRangeValue(
      low: _toDouble(json['low']),
      base: _toDouble(json['base']),
      high: _toDouble(json['high']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class SolarEstimateResult {
  const SolarEstimateResult({
    required this.recommendedSystemSizeKw,
    required this.estimatedMonthlyGenerationKwh,
    required this.estimatedMonthlySavingsInr,
    required this.assumptions,
    required this.limitations,
    required this.confidenceLabel,
    required this.disclaimer,
  });

  final double recommendedSystemSizeKw;
  final SolarRangeValue estimatedMonthlyGenerationKwh;
  final SolarRangeValue estimatedMonthlySavingsInr;
  final Map<String, dynamic> assumptions;
  final List<String> limitations;
  final String confidenceLabel;
  final String disclaimer;

  factory SolarEstimateResult.fromJson(Map<String, dynamic> json) {
    return SolarEstimateResult(
      recommendedSystemSizeKw: SolarRangeValue._toDouble(
        json['recommendedSystemSizeKw'],
      ),
      estimatedMonthlyGenerationKwh: SolarRangeValue.fromJson(
        _asMap(json['estimatedMonthlyGenerationKwh']),
      ),
      estimatedMonthlySavingsInr: SolarRangeValue.fromJson(
        _asMap(json['estimatedMonthlySavingsInr']),
      ),
      assumptions: _asMap(json['assumptions']),
      limitations: _asStringList(json['limitations']),
      confidenceLabel: (json['confidenceLabel'] ?? '').toString(),
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }
}
