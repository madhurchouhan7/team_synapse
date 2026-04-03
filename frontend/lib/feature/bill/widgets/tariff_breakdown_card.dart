import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/insights/providers/insights_provider.dart';

class TariffBreakdownCard extends ConsumerStatefulWidget {
  const TariffBreakdownCard({super.key});

  @override
  ConsumerState<TariffBreakdownCard> createState() =>
      _TariffBreakdownCardState();
}

class _TariffBreakdownCardState extends ConsumerState<TariffBreakdownCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final totalUnits = ref.watch(totalConsumptionProvider);

    // Perform dynamic calculations for typical progressive utility slabs
    double unitsRemaining = totalUnits;

    double slab1Units = unitsRemaining > 100 ? 100 : unitsRemaining;
    unitsRemaining -= slab1Units;
    double slab1Cost = slab1Units * 3.5;

    double slab2Units = unitsRemaining > 200 ? 200 : unitsRemaining;
    unitsRemaining -= slab2Units;
    double slab2Cost = slab2Units * 5.0;

    double slab3Units = unitsRemaining > 0 ? unitsRemaining : 0;
    double slab3Cost = slab3Units * 7.5;

    const double fixedCharges = 200.00; // Simplified realistic fixed cost

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tariff Breakdown",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeaderRow(),
                        const SizedBox(height: 16),
                        _buildRow(
                          "0-100 units",
                          "\u20B93.5/u",
                          "\u20B9${slab1Cost.toStringAsFixed(2)}",
                        ),
                        if (slab2Units > 0) ...[
                          const SizedBox(height: 16),
                          _buildRow(
                            "101-300 units",
                            "\u20B95.0/u",
                            "\u20B9${slab2Cost.toStringAsFixed(2)}",
                          ),
                        ],
                        if (slab3Units > 0) ...[
                          const SizedBox(height: 16),
                          _buildRow(
                            "301+ units",
                            "\u20B97.5/u",
                            "\u20B9${slab3Cost.toStringAsFixed(2)}",
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildFooterRow(
                          "Fixed Charges",
                          "\u20B9${fixedCharges.toStringAsFixed(2)}",
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            "SLAB",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "RATE",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "TOTAL",
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String slab, String rate, String total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            slab,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            rate,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            total,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(String label, String total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            total,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
