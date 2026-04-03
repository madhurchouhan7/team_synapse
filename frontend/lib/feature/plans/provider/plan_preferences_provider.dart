import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanPreferences {
  final List<String> mainGoals;
  final String focusArea;

  PlanPreferences({
    this.mainGoals = const [],
    this.focusArea = 'ai_decide', // Default to Let AI decide
  });

  PlanPreferences copyWith({List<String>? mainGoals, String? focusArea}) {
    return PlanPreferences(
      mainGoals: mainGoals ?? this.mainGoals,
      focusArea: focusArea ?? this.focusArea,
    );
  }
}

class PlanPreferencesNotifier extends Notifier<PlanPreferences> {
  @override
  PlanPreferences build() {
    return PlanPreferences();
  }

  void toggleGoal(String goalId) {
    if (state.mainGoals.contains(goalId)) {
      state = state.copyWith(
        mainGoals: state.mainGoals.where((g) => g != goalId).toList(),
      );
    } else {
      state = state.copyWith(mainGoals: [...state.mainGoals, goalId]);
    }
  }

  void setFocusArea(String focusId) {
    state = state.copyWith(focusArea: focusId);
  }
}

final planPreferencesProvider =
    NotifierProvider<PlanPreferencesNotifier, PlanPreferences>(
      PlanPreferencesNotifier.new,
    );
