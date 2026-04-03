import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';
import 'package:watt_sense/feature/plans/widgets/cooling_feedback_banner.dart';
import 'package:watt_sense/feature/plans/widgets/cooling_plan_header.dart';
import 'package:watt_sense/feature/plans/widgets/cooling_plan_stats_card.dart';
import 'package:watt_sense/feature/plans/widgets/performance_map_widget.dart';
import 'package:watt_sense/feature/plans/widgets/action_accordion_item.dart';

class CoolingPlanScreen extends ConsumerWidget {
  const CoolingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final streak = ref.watch(streakProvider);
    final user = userAsync.valueOrNull;
    final activePlan = user?.activePlan;

    // Extract dynamic actions
    final List<dynamic> actions = activePlan?['keyActions'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF6FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CoolingFeedbackBanner().animate().fade().slideY(
                begin: -0.2,
                end: 0,
                curve: Curves.easeOutQuad,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CoolingPlanHeader()
                        .animate()
                        .fade(delay: 50.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                    const SizedBox(height: 32),

                    const CoolingPlanStatsCard()
                        .animate()
                        .fade(delay: 150.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                    const SizedBox(height: 32),

                    const PerformanceMapWidget()
                        .animate()
                        .fade(delay: 250.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                    const SizedBox(height: 32),

                    Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Actions",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (streak > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFEDD5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("🔥 "),
                                    Text(
                                      "$streak-day streak!",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                        .animate()
                        .fade(delay: 350.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                    const SizedBox(height: 16),

                    if (actions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "Generating your optimized actions...",
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...actions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final action = entry.value;
                        return ActionAccordionItem(
                              icon: _getIconForAppliance(
                                action['appliance'] ?? '',
                              ),
                              title: action['appliance'] ?? "Strategy",
                              subtitle: action['action'] ?? "Optimize usage",
                              initialExpanded: idx == 0,
                            )
                            .animate()
                            .fade(delay: (450 + idx * 100).ms)
                            .slideY(begin: 0.1, end: 0);
                      }),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForAppliance(String appliance) {
    final lower = appliance.toLowerCase();
    if (lower.contains('ac') || lower.contains('air'))
      return Icons.ac_unit_rounded;
    if (lower.contains('light')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('wash')) return Icons.local_laundry_service_outlined;
    if (lower.contains('fridge') || lower.contains('refrigerator'))
      return Icons.kitchen_rounded;
    if (lower.contains('blind') || lower.contains('curtain'))
      return Icons.blinds_closed_rounded;
    return Icons.auto_awesome;
  }
}
