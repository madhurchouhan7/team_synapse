import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';
import 'package:watt_sense/feature/on_boarding/model/on_boarding_state.dart';
import 'package:watt_sense/feature/on_boarding/repository/appliance_repository.dart';

final onBoardingPage5Provider =
    StateNotifierProvider<OnBoardingPage5Notifier, OnBoardingPage5State>((ref) {
      final repository = ref.read(applianceRepositoryProvider);
      return OnBoardingPage5Notifier(repository: repository);
    });

class OnBoardingPage5Notifier extends StateNotifier<OnBoardingPage5State> {
  final ApplianceRepository _repository;

  OnBoardingPage5Notifier({required ApplianceRepository repository})
    : _repository = repository,
      super(const OnBoardingPage5State());

  List<LevelOption> getUsageOptions(ApplianceModel appliance) {
    switch (appliance.category) {
      case 'HEATING':
        return [
          LevelOption('Low', '1-2/day'),
          LevelOption('Medium', '2-3/day'),
          LevelOption('High', '3+/day'),
        ];
      case 'ALWAYS ON':
        return [
          LevelOption('Low', '12h/day'),
          LevelOption('Medium', '18h/day'),
          LevelOption('High', '24h/day'),
        ];
      case 'OCCASIONAL USE':
        return [
          LevelOption('Low', '1-2/week'),
          LevelOption('Medium', '3-4/week'),
          LevelOption('High', '5+/week'),
        ];
      case 'COOLING':
      default:
        return [
          LevelOption('Low', '1-4h/day'),
          LevelOption('Medium', '5-8h/day'),
          LevelOption('High', '9+h/day'),
        ];
    }
  }

  List<DropdownConfig> getDropdownConfigs(ApplianceModel appliance) {
    if (appliance.title == 'Air Conditioner') {
      return [
        DropdownConfig('TONNAGE', ['1.0 Ton', '1.5 Ton', '2.0 Ton', '2.5 Ton']),
        DropdownConfig('STAR RATING', ['3 Star', '4 Star', '5 Star']),
      ];
    } else if (appliance.title == 'Geyser') {
      return [
        DropdownConfig('CAPACITY', ['10L', '15L', '25L', '35L']),
        DropdownConfig('STAR RATING', ['3 Star', '4 Star', '5 Star']),
      ];
    } else if (appliance.title == 'Refridgerator' ||
        appliance.title == 'Refrigerator') {
      return [
        DropdownConfig('TYPE', ['Single Door', 'Double Door', 'Multi Door']),
        DropdownConfig('STAR RATING', ['3 Star', '4 Star', '5 Star']),
      ];
    } else {
      final types = appliance.description
          .split(', ')
          .where((t) => t.isNotEmpty)
          .toList();
      return [
        if (types.length > 1) DropdownConfig('TYPE', types),
        DropdownConfig('STAR RATING', ['3 Star', '4 Star', '5 Star']),
      ];
    }
  }

  ApplianceLocalState _createDefaultState(ApplianceModel app) {
    final dropdowns = getDropdownConfigs(app);
    Map<String, String> initialDropdowns = {};
    for (var d in dropdowns) {
      if (d.options.isNotEmpty) {
        initialDropdowns[d.label] = d.options.first;
        if (app.title == 'Air Conditioner') {
          if (d.label == 'TONNAGE') initialDropdowns[d.label] = '1.5 Ton';
          if (d.label == 'STAR RATING') initialDropdowns[d.label] = '5 Star';
        }
      }
    }
    return ApplianceLocalState(
      usageLevel: 'Medium',
      count: 1,
      selectedDropdowns: initialDropdowns,
    );
  }

  ApplianceLocalState getOrInitState(ApplianceModel app) {
    return state.localStates[app.id] ?? _createDefaultState(app);
  }

  void preloadState(Map<String, ApplianceLocalState> existingStates) {
    state = state.copyWith(localStates: existingStates);
  }

  void updateUsageLevel(ApplianceModel app, String level) {
    final currentState = getOrInitState(app);
    state = state.copyWith(
      localStates: Map.from(state.localStates)
        ..[app.id] = currentState.copyWith(usageLevel: level),
    );
  }

  void updateCount(ApplianceModel app, int newCount) {
    if (newCount < 1) return;
    final currentState = getOrInitState(app);
    state = state.copyWith(
      localStates: Map.from(state.localStates)
        ..[app.id] = currentState.copyWith(count: newCount),
    );
  }

  void updateDropdown(ApplianceModel app, String label, String value) {
    final currentState = getOrInitState(app);
    final newDropdowns = Map<String, String>.from(
      currentState.selectedDropdowns,
    );
    newDropdowns[label] = value;
    state = state.copyWith(
      localStates: Map.from(state.localStates)
        ..[app.id] = currentState.copyWith(selectedDropdowns: newDropdowns),
    );
  }

  void toggleExpanded(ApplianceModel app) {
    final currentState = getOrInitState(app);
    state = state.copyWith(
      localStates: Map.from(
        state.localStates,
      )..[app.id] = currentState.copyWith(isExpanded: !currentState.isExpanded),
    );
  }

  Future<void> finishSetup(List<ApplianceModel> selectedAppliances) async {
    // Ensure we have a complete state including defaults for untouched appliances
    final List<Map<String, dynamic>> finalData = [];
    for (var app in selectedAppliances) {
      final state = getOrInitState(app);
      finalData.add({
        'applianceId': app.id,
        'title': app.title,
        'category': app.category,
        'usageHours': app.usageHours,
        'usageLevel': state.usageLevel,
        'count': state.count,
        'selectedDropdowns': state.selectedDropdowns,
        'svgPath': app.svgPath,
      });
    }
    print("Setup Finished with data: $finalData");
    // Persist to backend
    await _repository.saveAppliances(finalData);
  }
}
