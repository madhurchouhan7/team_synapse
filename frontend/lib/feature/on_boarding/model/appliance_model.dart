import 'package:freezed_annotation/freezed_annotation.dart';

part 'appliance_model.freezed.dart';
part 'appliance_model.g.dart';

@freezed
abstract class ApplianceModel with _$ApplianceModel {
  const factory ApplianceModel({
    required String id,
    required String title,
    required String description,
    required String svgPath,
    required String category,
    @Default(2.0) double usageHours,
  }) = _ApplianceModel;

  factory ApplianceModel.fromJson(Map<String, dynamic> json) =>
      _$ApplianceModelFromJson(json);
}
