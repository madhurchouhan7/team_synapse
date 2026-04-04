import 'package:freezed_annotation/freezed_annotation.dart';

part 'efficiency_plan_model.freezed.dart';

@freezed
abstract class EfficiencyPlanModel with _$EfficiencyPlanModel {
  const EfficiencyPlanModel._();

  const factory EfficiencyPlanModel({
    required String summary,
    required double estimatedCurrentMonthlyCost,
    required EstimatedSavings estimatedSavingsIfFollowed,
    required double efficiencyScore,
    required List<KeyAction> keyActions,
    required SlabAlert slabAlert,
    required List<String> quickWins,
    required String monthlyTip,
  }) = _EfficiencyPlanModel;

  factory EfficiencyPlanModel.fromJson(Map<String, dynamic> json) {
    final rawActions = json['keyActions'];
    final actions = rawActions is List
        ? rawActions
              .whereType<Map<String, dynamic>>()
              .map(KeyAction.fromJson)
              .toList()
        : <KeyAction>[];

    return EfficiencyPlanModel(
      summary: _asString(json['summary'], fallback: ''),
      estimatedCurrentMonthlyCost: _asDouble(
        json['estimatedCurrentMonthlyCost'],
      ),
      estimatedSavingsIfFollowed: EstimatedSavings.fromJson(
        _asMap(json['estimatedSavingsIfFollowed']),
      ),
      efficiencyScore: _asDouble(json['efficiencyScore']),
      keyActions: actions,
      slabAlert: SlabAlert.fromJson(_asMap(json['slabAlert'])),
      quickWins: _asStringList(json['quickWins']),
      monthlyTip: _asString(json['monthlyTip'], fallback: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'estimatedCurrentMonthlyCost': estimatedCurrentMonthlyCost,
      'estimatedSavingsIfFollowed': estimatedSavingsIfFollowed.toJson(),
      'efficiencyScore': efficiencyScore,
      'keyActions': keyActions.map((e) => e.toJson()).toList(),
      'slabAlert': slabAlert.toJson(),
      'quickWins': quickWins,
      'monthlyTip': monthlyTip,
    };
  }
}

@freezed
abstract class EstimatedSavings with _$EstimatedSavings {
  const EstimatedSavings._();

  const factory EstimatedSavings({
    required double units,
    required double rupees,
    required double percentage,
  }) = _EstimatedSavings;

  factory EstimatedSavings.fromJson(Map<String, dynamic> json) {
    return EstimatedSavings(
      units: _asDouble(json['units']),
      rupees: _asDouble(json['rupees']),
      percentage: _asDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'units': units, 'rupees': rupees, 'percentage': percentage};
  }
}

@freezed
abstract class KeyAction with _$KeyAction {
  const KeyAction._();

  const factory KeyAction({
    required String priority,
    required String appliance,
    required String action,
    required String impact,
    required String estimatedSaving,
  }) = _KeyAction;

  factory KeyAction.fromJson(Map<String, dynamic> json) {
    return KeyAction(
      priority: _asString(json['priority'], fallback: 'medium'),
      appliance: _asString(json['appliance'], fallback: 'General Household'),
      action: _asString(json['action'], fallback: ''),
      impact: _asString(json['impact'], fallback: ''),
      estimatedSaving: _asString(json['estimatedSaving'], fallback: '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'appliance': appliance,
      'action': action,
      'impact': impact,
      'estimatedSaving': estimatedSaving,
    };
  }
}

@freezed
abstract class SlabAlert with _$SlabAlert {
  const SlabAlert._();

  const factory SlabAlert({
    required bool isInDangerZone,
    required String currentSlab,
    double? nextSlabAt,
    double? unitsToNextSlab,
    String? warning,
  }) = _SlabAlert;

  factory SlabAlert.fromJson(Map<String, dynamic> json) {
    return SlabAlert(
      isInDangerZone: _asBool(json['isInDangerZone']),
      currentSlab: _asString(json['currentSlab'], fallback: 'unknown'),
      nextSlabAt: _asNullableDouble(json['nextSlabAt']),
      unitsToNextSlab: _asNullableDouble(json['unitsToNextSlab']),
      warning: json['warning'] == null ? null : _asString(json['warning']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isInDangerZone': isInDangerZone,
      'currentSlab': currentSlab,
      'nextSlabAt': nextSlabAt,
      'unitsToNextSlab': unitsToNextSlab,
      'warning': warning,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    return parsed ?? fallback;
  }
  return fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  return _asDouble(value);
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    const truthy = {'true', '1', 'yes'};
    const falsy = {'false', '0', 'no'};
    final normalized = value.trim().toLowerCase();
    if (truthy.contains(normalized)) {
      return true;
    }
    if (falsy.contains(normalized)) {
      return false;
    }
  }
  if (value is num) {
    return value != 0;
  }
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => _asString(item)).toList();
  }
  return <String>[];
}
