class InsightsDataModel {
  final String reportMonth;
  final int efficiencyScore;
  final int betterThanPercentage;
  final List<ApplianceUsageModel> topAppliances;
  final String aiInsightText;

  InsightsDataModel({
    required this.reportMonth,
    required this.efficiencyScore,
    required this.betterThanPercentage,
    required this.topAppliances,
    required this.aiInsightText,
  });
}

class ApplianceUsageModel {
  final String name;
  final int percentage;

  ApplianceUsageModel({required this.name, required this.percentage});
}
