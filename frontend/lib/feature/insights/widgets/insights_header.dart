import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/insights/providers/insights_provider.dart';
import 'package:watt_sense/feature/insights/models/insights_data_model.dart';
import 'package:watt_sense/feature/insights/services/pdf_export_service.dart';

class InsightsHeader extends ConsumerWidget {
  const InsightsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final score = ref.watch(efficiencyScoreProvider);
    final breakdownData = ref.watch(applianceBreakdownProvider);

    final topAppliances = breakdownData.map((item) {
      return ApplianceUsageModel(
        name: item['name'] as String,
        percentage: item['percentage'] as int,
      );
    }).toList();

    final topApplianceName = breakdownData.isNotEmpty
        ? breakdownData.first['name']
        : 'Appliance';
    final aiInsightText =
        "Your $topApplianceName usage is higher than AI models predict for local weather conditions. Try shifting its operational hours. Check Upgrade Options?";

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Insights",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedMonth,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                  onPressed: () async {
                    final exportData = InsightsDataModel(
                      reportMonth: selectedMonth,
                      efficiencyScore: score,
                      betterThanPercentage:
                          score, // Assuming betterThan is proportional to score as in the app mock
                      topAppliances: topAppliances,
                      aiInsightText: aiInsightText,
                    );

                    await PdfExportService.exportInsightsToPdf(exportData);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
