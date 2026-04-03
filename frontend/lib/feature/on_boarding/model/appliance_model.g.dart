// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appliance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApplianceModel _$ApplianceModelFromJson(Map<String, dynamic> json) =>
    _ApplianceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      svgPath: json['svgPath'] as String,
      category: json['category'] as String,
      usageHours: (json['usageHours'] as num?)?.toDouble() ?? 2.0,
    );

Map<String, dynamic> _$ApplianceModelToJson(_ApplianceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'svgPath': instance.svgPath,
      'category': instance.category,
      'usageHours': instance.usageHours,
    };
