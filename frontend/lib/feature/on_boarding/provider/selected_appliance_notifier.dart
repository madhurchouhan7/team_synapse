import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';

// Provider that holds the list of selected appliances
final selectedAppliancesProvider =
    StateNotifierProvider<SelectedAppliancesNotifier, List<ApplianceModel>>(
      (ref) => SelectedAppliancesNotifier(),
    );

class SelectedAppliancesNotifier extends StateNotifier<List<ApplianceModel>> {
  SelectedAppliancesNotifier() : super([]);

  // Toggle appliance selection (add or remove)
  void toggleAppliance(ApplianceModel appliance) {
    final isSelected = state.any((item) => item.id == appliance.id);

    if (isSelected) {
      // Remove from list
      state = state.where((item) => item.id != appliance.id).toList();
    } else {
      // Add to list
      state = [...state, appliance];
    }
  }

  // Explicitly set appliances list
  void setAppliances(List<ApplianceModel> appliances) {
    state = appliances;
  }

  // Check if an appliance is selected
  bool isSelected(String applianceId) {
    return state.any((item) => item.id == applianceId);
  }

  // Update usage hours for a specific appliance (using Freezed's copyWith)
  void updateUsageHours(String applianceId, double hours) {
    state = state.map((appliance) {
      if (appliance.id == applianceId) {
        return appliance.copyWith(
          usageHours: hours,
        ); // 🎯 copyWith from Freezed
      }
      return appliance;
    }).toList();
  }

  // Clear all selections
  void clearAll() {
    state = [];
  }

  // Get total count of selected appliances
  int get selectedCount => state.length;

  // Get appliance by ID
  ApplianceModel? getApplianceById(String id) {
    try {
      return state.firstWhere((appliance) => appliance.id == id);
    } catch (e) {
      return null;
    }
  }

  // Export data as JSON (useful for saving to backend)
  List<Map<String, dynamic>> toJson() {
    return state.map((appliance) => appliance.toJson()).toList();
  }
}
