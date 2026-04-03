import 'package:freezed_annotation/freezed_annotation.dart';

part 'on_boarding_state.freezed.dart';

@freezed
abstract class ApplianceLocalState with _$ApplianceLocalState {
  const factory ApplianceLocalState({
    required String usageLevel,
    required int count,
    required Map<String, String> selectedDropdowns,
    @Default(false) bool isExpanded,
  }) = _ApplianceLocalState;
}

@freezed
abstract class OnBoardingPage5State with _$OnBoardingPage5State {
  const factory OnBoardingPage5State({
    @Default({}) Map<String, ApplianceLocalState> localStates,
  }) = _OnBoardingPage5State;
}

class DropdownConfig {
  final String label;
  final List<String> options;
  DropdownConfig(this.label, this.options);
}

class LevelOption {
  final String label;
  final String duration;
  LevelOption(this.label, this.duration);
}
