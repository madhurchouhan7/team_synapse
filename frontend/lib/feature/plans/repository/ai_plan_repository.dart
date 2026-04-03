import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/plans/model/efficiency_plan_model.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';
import 'package:watt_sense/feature/on_boarding/model/on_boarding_state.dart';
import 'package:watt_sense/core/network/api_client.dart';

final aiPlanRepositoryProvider = Provider(
  (ref) => AiPlanRepository(ApiClient.instance),
);

class AiPlanRepository {
  final ApiClient _client;

  AiPlanRepository(this._client);

  Future<EfficiencyPlanModel> generatePlan({
    required Map<String, dynamic> userGoalParams,
    required List<ApplianceModel> appliances,
    required Map<String, ApplianceLocalState> applianceStates,
    required Map<String, dynamic> billInfo,
  }) async {
    try {
      final requestThreadId = 'thread-${DateTime.now().millisecondsSinceEpoch}';
      final tenantId = userGoalParams["tenantId"] ?? "local-tenant";
      final List<Map<String, dynamic>> applianceList = appliances.map((app) {
        final state = applianceStates[app.id];
        return {
          "name": app.title,
          "count": state?.count ?? 1,
          "usageLevel": state?.usageLevel ?? "Medium",
          "wattage": _extractWattage(state?.selectedDropdowns),
          "starRating": _extractStar(state?.selectedDropdowns),
        };
      }).toList();

      final payload = {
        "user": {...userGoalParams, "tenantId": tenantId},
        "appliances": applianceList,
        "bill": billInfo,
        "threadId": requestThreadId,
      };

      developer.log(
        'Generate AI plan request started',
        name: 'AiPlanRepository',
        error: {
          'threadId': requestThreadId,
          'mode': 'collaborative',
          'applianceCount': applianceList.length,
          'hasBill': billInfo.isNotEmpty,
          'tenantId': tenantId,
        },
      );

      final response = await _client.post(
        '/ai/generate-plan',
        data: payload,
        // Gemini API can take 25-35s — override only for this call
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          headers: {
            'x-ai-mode': 'collaborative',
            'x-thread-id': requestThreadId,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final metadata =
            data is Map<String, dynamic> &&
                data['metadata'] is Map<String, dynamic>
            ? data['metadata'] as Map<String, dynamic>
            : <String, dynamic>{};

        developer.log(
          'Generate AI plan response received',
          name: 'AiPlanRepository',
          error: {
            'statusCode': response.statusCode,
            'executionPath': metadata['executionPath'],
            'requestedMode': metadata['requestedMode'],
            'orchestrationVersion': metadata['orchestrationVersion'],
            'qualityScore': metadata['qualityScore'],
            'debateRounds': metadata['debateRounds'],
            'phase4': metadata['phase4'],
            'phase5': metadata['phase5'],
            'phase6': metadata['phase6'],
          },
        );

        if (data is Map<String, dynamic> &&
            data['finalPlan'] is Map<String, dynamic>) {
          return EfficiencyPlanModel.fromJson(
            data['finalPlan'] as Map<String, dynamic>,
          );
        }
        if (data is Map<String, dynamic>) {
          return EfficiencyPlanModel.fromJson(data);
        }
        throw Exception('Invalid plan payload shape');
      } else {
        throw Exception("Failed to generate plan");
      }
    } catch (e, st) {
      developer.log(
        'Generate AI plan request failed',
        name: 'AiPlanRepository',
        error: e,
        stackTrace: st,
      );
      throw Exception("Error generating AI Plan: $e");
    }
  }

  String _extractWattage(Map<String, String>? dropdowns) {
    if (dropdowns == null) return "unknown";
    return dropdowns.values.firstWhere(
      (v) => v.contains("W") || v.contains("Ton") || v.contains("Liters"),
      orElse: () => "unknown",
    );
  }

  String _extractStar(Map<String, String>? dropdowns) {
    if (dropdowns == null) return "unknown";
    return dropdowns.values.firstWhere(
      (v) => v.contains("Star"),
      orElse: () => "unknown",
    );
  }
}
