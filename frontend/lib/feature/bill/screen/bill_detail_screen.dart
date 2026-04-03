import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';
import 'package:watt_sense/feature/bill/widgets/bill_amount_card.dart';
import 'package:watt_sense/feature/bill/widgets/bill_decoder_card.dart';
import 'package:watt_sense/feature/bill/widgets/consumption_estimate_card.dart';
import 'package:watt_sense/feature/bill/widgets/plan_status_card.dart';
import 'package:watt_sense/feature/bill/widgets/spending_alert_banner.dart';
import 'package:watt_sense/feature/bill/widgets/tariff_breakdown_card.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedBill = ref.watch(savedBillProvider);
    final title = savedBill?['billerId'] ?? "Electricity Bill";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light grey bg
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
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
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.primaryBlue,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.primaryBlue,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const BillAmountCard().animate().fade().slideY(
                begin: 0.1,
                end: 0,
                curve: Curves.easeOutQuad,
              ),

              const SizedBox(height: 24),

              const SpendingAlertBanner()
                  .animate()
                  .fade(delay: 100.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              const PlanStatusCard()
                  .animate()
                  .fade(delay: 200.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              const BillDecoderCard()
                  .animate()
                  .fade(delay: 300.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              const TariffBreakdownCard()
                  .animate()
                  .fade(delay: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              const ConsumptionEstimateCard()
                  .animate()
                  .fade(delay: 500.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
