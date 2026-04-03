import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/insights/providers/insights_provider.dart';

class EfficiencyScoreCard extends ConsumerWidget {
  const EfficiencyScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(efficiencyScoreProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF3F6FF), // extremely light blue
                Color(0xFFE2E9FE), // slightly darker blue tint
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ), // Gives a glossy look
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withAlpha(20),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EFFICIENCY SCORE",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        score.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        "/100",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                  _buildMiniChart(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.call_made_rounded,
                    color: AppColors.ecoGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Better than  ",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: "${score.toString()}%",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: "  of similar homes",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniChart() {
    final bars = [
      {'height': 24.0, 'color': AppColors.primaryBlue.withAlpha(100)},
      {'height': 36.0, 'color': AppColors.primaryBlue.withAlpha(100)},
      {'height': 48.0, 'color': AppColors.primaryBlue.withAlpha(100)},
      {'height': 64.0, 'color': AppColors.primaryBlue},
      {'height': 42.0, 'color': AppColors.primaryBlue.withAlpha(100)},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        return Container(
          width: 8,
          height: bar['height'] as double,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: bar['color'] as Color, // Lightish blue vs primary blue
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}
