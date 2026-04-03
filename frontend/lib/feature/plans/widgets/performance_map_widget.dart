import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';

class PerformanceMapWidget extends ConsumerWidget {
  const PerformanceMapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final days = ["M", "T", "W", "T", "F", "S", "S"];

    // Status colors based on streak: green for fulfilled days, amber/grey for missed
    // We mock the status for the past 7 days based on current streak count
    final statusColors = List.generate(7, (index) {
      if (index == 6) return Colors.white; // Today

      final reverseIndex = 5 - index; // 0 is yesterday, 5 is 6 days ago
      if (reverseIndex < streak) {
        return const Color(0xFF34D399); // Emerald (Success)
      } else if (reverseIndex == streak) {
        return const Color(0xFFFBBF24); // Amber (Missed recently)
      }
      return const Color(0xFFE2E8F0); // Grey (Inactive)
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 8.0;
        final double cellSize = (constraints.maxWidth - (spacing * 6)) / 7;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Performance Map",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Past 7 Days",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withAlpha(150),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isToday = index == 6;

                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          days[index],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary.withAlpha(150),
                          ),
                        ),
                        if (isToday)
                          Positioned(
                            top: -2,
                            right: -6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: statusColors[index],
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: AppColors.primaryBlue, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: isToday
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
