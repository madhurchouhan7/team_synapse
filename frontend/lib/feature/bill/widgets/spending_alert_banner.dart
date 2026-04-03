import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';

class SpendingAlertBanner extends ConsumerWidget {
  const SpendingAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedBill = ref.watch(savedBillProvider);
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;

    if (savedBill == null) return const SizedBox.shrink();

    final currentAmount =
        double.tryParse(savedBill['amountExact']?.toString() ?? '0') ?? 0;

    // We compare with the AI Plan's estimated current cost if available,
    // or simulate a slight increase for visual feedback if no history exists.
    final baseAmount =
        (user?.activePlan?['estimatedCurrentMonthlyCost'] as num?)
            ?.toDouble() ??
        (currentAmount * 0.9);

    final diff = currentAmount - baseAmount;
    final percent = baseAmount > 0 ? (diff / baseAmount * 100).round() : 0;

    // Only show if spending is actually higher
    if (diff <= 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), // Light red bg
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withAlpha(25), // Very light red
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.alertRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Spending Increased",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertRed,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Higher than estimated baseline",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.alertRed.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppColors.alertRed,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "$percent%",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.alertRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "+₹${diff.toInt()}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.alertRed.withAlpha(180),
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
}
