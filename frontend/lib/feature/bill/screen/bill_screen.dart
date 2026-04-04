import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/bill/screen/add_bill_screen.dart';
import 'package:watt_sense/feature/bill/widgets/bill_header.dart';
import 'package:watt_sense/feature/bill/widgets/bill_history_tile.dart';
import 'package:watt_sense/feature/bill/widgets/current_cycle_card.dart';

import '../providers/fetch_bill_provider.dart';

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  @override
  Widget build(BuildContext context) {
    final savedBill = ref.watch(savedBillProvider);

    String amountStr = '0';
    if (savedBill != null && savedBill['amountExact'] != null) {
      final rawAmount = savedBill['amountExact'];
      if (rawAmount is int) {
        amountStr = rawAmount.toString();
      } else if (rawAmount is double) {
        amountStr = rawAmount.toStringAsFixed(2);
      } else {
        amountStr = rawAmount.toString();
      }
    }

    final hasBill = savedBill != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: hasBill
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BillHeader().animate().fade().slideY(
                      begin: -0.2,
                      end: 0,
                    ),
                    const SizedBox(height: 32),
                    const CurrentCycleCard()
                        .animate()
                        .fade(delay: 100.ms)
                        .slideY(begin: 0.1, end: 0),
                    if (savedBill['imageBase64'] != null &&
                        savedBill['imageBase64'].toString().isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                            "Scanned Bill",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          )
                          .animate()
                          .fade(delay: 150.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                      Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                base64Decode(savedBill['imageBase64']),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          )
                          .animate()
                          .fade(delay: 150.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "History",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: "Remove Active Bill",
                              onPressed: () async {
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        "Remove Active Bill",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      content: Text(
                                        "Are you sure you want to remove this bill?",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(
                                            "Cancel",
                                            style: GoogleFonts.poppins(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(
                                            "Remove",
                                            style: GoogleFonts.poppins(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (!mounted) return;
                                if (confirm == true) {
                                  ref
                                      .read(savedBillProvider.notifier)
                                      .clearBill();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text(
                                          "Bill removed successfully",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Last 6 months",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    BillHistoryTile(
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.ecoGreen,
                      date: savedBill['billerId'] ?? "Default",
                      usage:
                          savedBill['units'].toString() == '0' ||
                              savedBill['units'] == null
                          ? '450'
                          : savedBill['units'].toString(),
                      rate: "-",
                      amount: "₹$amountStr",
                      trend: "New",
                      isTrendingUp: false,
                      isTrendNeutral: true,
                    ).animate().fade(delay: 250.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(
                      height: 80,
                    ), // Extra space for FAB and bottom navbar
                  ],
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No bills added yet",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Scan or add your latest electricity bill to see your current cycle and history here.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
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
            backgroundColor: const Color(0xFF1E60F2),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              "Add Bill",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ).animate().fade().scale(
            delay: 600.ms,
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
