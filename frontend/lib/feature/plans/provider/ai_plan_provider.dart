import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/feature/plans/model/efficiency_plan_model.dart';
import 'package:watt_sense/feature/plans/repository/ai_plan_repository.dart';
import 'package:watt_sense/feature/on_boarding/provider/selected_appliance_notifier.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_5_notifier.dart';
import 'package:watt_sense/feature/plans/provider/plan_preferences_provider.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';

const String _kCachedPlanKey = 'cached_ai_efficiency_plan';

class AiPlanNotifier extends AsyncNotifier<EfficiencyPlanModel?> {
  @override
  FutureOr<EfficiencyPlanModel?> build() async {
    // Attempt to hydrate from disk cache when the app starts.
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_kCachedPlanKey);

    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData);
        return EfficiencyPlanModel.fromJson(decoded);
      } catch (e) {
        // Fallback gracefully on corrupted local cache
      }
    }

    return null; // Go to preference flow
  }

  Future<void> generatePlan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final repository = ref.read(aiPlanRepositoryProvider);
        final appliances = ref.read(selectedAppliancesProvider);
        final applianceStates = ref.read(onBoardingPage5Provider).localStates;
        final preferences = ref.read(planPreferencesProvider);

        final userGoalParams = {
          "goal": preferences.mainGoals.isNotEmpty
              ? preferences.mainGoals.join(',')
              : "reduce_bill",
          "focusArea": preferences.focusArea,
          "location": "India",
        };

        final savedBill = ref.read(savedBillProvider);

        num unitsConsumed = 0;
        num totalAmount = 0;
        num grossAmount = 0;
        num subsidyAmount = 0;

        if (savedBill != null) {
          if (savedBill['units'] != null) {
            unitsConsumed = num.tryParse(savedBill['units'].toString()) ?? 0;
          }
          if (savedBill['amountExact'] != null) {
            totalAmount =
                num.tryParse(savedBill['amountExact'].toString()) ?? 0;
          }
          if (savedBill['grossAmount'] != null) {
            grossAmount =
                num.tryParse(savedBill['grossAmount'].toString()) ??
                totalAmount;
          } else {
            grossAmount = totalAmount;
          }
          if (savedBill['subsidyAmount'] != null) {
            subsidyAmount =
                num.tryParse(savedBill['subsidyAmount'].toString()) ?? 0;
          }
        }

        final billInfo = {
          "month": savedBill?['billerId'] ?? "Recent Bill",
          "unitsConsumed": unitsConsumed.toInt(),
          "totalAmount": totalAmount.toInt(),
          "grossAmount": grossAmount.toInt(),
          "subsidyAmount": subsidyAmount.toInt(),
          "pricePerUnit": unitsConsumed > 0
              ? (grossAmount / unitsConsumed)
              : 7.11,
        };

        developer.log(
          'AI plan generation started',
          name: 'AiPlanNotifier',
          error: {
            'applianceCount': appliances.length,
            'goal': userGoalParams['goal'],
            'focusArea': userGoalParams['focusArea'],
            'unitsConsumed': billInfo['unitsConsumed'],
            'grossAmount': billInfo['grossAmount'],
          },
        );

        final generatedPlan = await repository.generatePlan(
          userGoalParams: userGoalParams,
          appliances: appliances,
          applianceStates: applianceStates,
          billInfo: billInfo,
        );

        developer.log(
          'AI plan generation succeeded',
          name: 'AiPlanNotifier',
          error: {
            'efficiencyScore': generatedPlan.efficiencyScore,
            'keyActionCount': generatedPlan.keyActions.length,
            'quickWinsCount': generatedPlan.quickWins.length,
          },
        );

        // Save it locally!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _kCachedPlanKey,
          jsonEncode(generatedPlan.toJson()),
        );

        return generatedPlan;
      } catch (e, st) {
        developer.log(
          'AI plan generation failed',
          name: 'AiPlanNotifier',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
    });
  }

  Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedPlanKey);
    state = const AsyncData(null);
  }
}

final aiPlanProvider =
    AsyncNotifierProvider<AiPlanNotifier, EfficiencyPlanModel?>(
      AiPlanNotifier.new,
    );
