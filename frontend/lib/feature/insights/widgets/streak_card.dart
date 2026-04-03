import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';

class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(streakStateProvider);
    final weekdays = ref.watch(streakWeekdaysProvider);

    final streak = streakState.streak;
    final checkedInToday = streakState.checkedInToday;
    final isStreakBroken = streakState.isStreakBroken;

    final now = DateTime.now();
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final todayLabel =
        '${weekdayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}';
    final todayIndex = now.weekday - 1; // 0=Mon … 6=Sun

    final List<String> dayLabels = ["M", "T", "W", "T", "F", "S", "S"];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade50.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CONSISTENCY",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your Streak",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Today's date
                  Text(
                    todayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Streak badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? Colors.orange.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: streak > 0
                        ? Colors.orange.shade200
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak > 0 ? "🔥" : "💤",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      streak > 0 ? "$streak Days" : "No Streak",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: streak > 0
                            ? Colors.orange.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Broken streak warning ─────────────────────────────────────────
          if (isStreakBroken) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    children: [
                      Text(
                        "Streak broken! Check in today to start again",
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Weekday Dots ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == todayIndex;
              final isAchieved = weekdays[index];
              // Today's dot: show pending (outline) if not yet checked in
              final isTodayPending = isToday && !checkedInToday;

              return Column(
                children: [
                  Text(
                    dayLabels[index],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isAchieved
                          ? Colors.orange.shade400
                          : isTodayPending
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: isTodayPending || isToday
                          ? Border.all(
                              color: isAchieved
                                  ? Colors.orange.shade500
                                  : Colors.orange.shade300,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isAchieved
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : isTodayPending
                          ? const Text("⚡", style: TextStyle(fontSize: 12))
                          : null,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 20),

          // ── Bottom info strip ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: checkedInToday
                  ? Colors.green.shade50
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: checkedInToday
                  ? Border.all(color: Colors.green.shade100)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  checkedInToday
                      ? Icons.check_circle_rounded
                      : Icons.stars_rounded,
                  color: checkedInToday
                      ? Colors.green.shade500
                      : Colors.orange.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _buildInfoMessage(streak, checkedInToday, isStreakBroken),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: checkedInToday
                          ? Colors.green.shade700
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildInfoMessage(
    int streak,
    bool checkedInToday,
    bool isStreakBroken,
  ) {
    if (checkedInToday) {
      return "✅ Checked in today! Great consistency — keep it up!";
    }
    if (isStreakBroken) {
      return "Your streak was broken. Check in today to start a new one!";
    }
    if (streak > 0) {
      return "You've saved roughly ₹${streak * 12} with your consistency!";
    }
    return "Check in daily to build your streak and see savings!";
  }
}
