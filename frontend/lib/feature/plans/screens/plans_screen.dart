import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/plans/provider/ai_plan_provider.dart';
import 'package:watt_sense/feature/plans/screens/design_plan_screen.dart';
import 'package:watt_sense/feature/plans/screens/active_plan_screen.dart';
import 'package:watt_sense/feature/plans/screens/plan_ready_screen.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:shimmer/shimmer.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  @override
  Widget build(BuildContext context) {
    final aiPlanState = ref.watch(aiPlanProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return aiPlanState.when(
      data: (plan) {
        // Prevent flickering when authState is loading (e.g. after activation/invalidation)
        if (authState.isLoading) {
          // While loading, if we don't have an active plan in hand yet, show shimmer.
          if (user?.activePlan == null) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: _buildLoadingShimmer(),
            );
          }
        }

        // 1. If user has an already active AI Plan persisting in the backend, show it.
        if (user != null && user.activePlan != null) {
          return ActivePlanScreen(activePlan: user.activePlan!);
        }

        // 2. If plan hasn't been generated yet, show the design flow.
        if (plan == null) {
          return const DesignPlanScreen();
        }

        // 3. If plan is generated but NOT active to the backend yet, show the staging preview.
        return const PlanReadyScreen();
      },
      loading: () =>
          Scaffold(backgroundColor: Colors.white, body: _buildLoadingShimmer()),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to generate plan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(aiPlanProvider.notifier).generatePlan();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            // Title skeleton
            Container(width: 200, height: 32, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 150, height: 32, color: Colors.white),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 16, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 300, height: 16, color: Colors.white),
            const SizedBox(height: 32),
            // Blue card skeleton
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 32),
            // Action highlights skeleton
            Container(width: 140, height: 16, color: Colors.white),
            const SizedBox(height: 24),
            // Action items
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 200,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
