import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/bill/screen/add_bill_screen.dart';
import 'package:watt_sense/feature/dashboard/providers/dashboard_provider.dart';
import 'package:watt_sense/feature/insights/widgets/appliance_breakdown_card.dart';
import 'package:watt_sense/feature/insights/widgets/daily_intensity_card.dart';
import 'package:watt_sense/feature/insights/widgets/efficiency_score_card.dart';
import 'package:watt_sense/feature/insights/widgets/insights_header.dart';
import 'package:watt_sense/feature/insights/widgets/no_insights_empty_state.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBills = ref.watch(hasBillsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: hasBills ? const _DataView() : const _EmptyView(),
        ),
      ),
    );
  }
}

// ─── Empty state (no bills) ───────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── App Bar ────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.058,
            vertical: width * 0.03,
          ),
          child: Row(
            children: [
              Text(
                'Insights',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        // ── Empty state fills remaining space ───────────────────
        Expanded(
          child: NoInsightsEmptyState(
            onAddBill: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: AddBillScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Data view (bills exist) ──────────────────────────────────────────────────

class _DataView extends StatelessWidget {
  const _DataView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const InsightsHeader().animate().fade().slideY(begin: -0.2, end: 0),

          const SizedBox(height: 32),

          const EfficiencyScoreCard()
              .animate()
              .fade(delay: 100.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          const DailyIntensityCard()
              .animate()
              .fade(delay: 200.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          const ApplianceBreakdownCard()
              .animate()
              .fade(delay: 300.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
