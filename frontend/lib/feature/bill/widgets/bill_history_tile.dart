import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';

class BillHistoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String date;
  final String usage;
  final String rate;
  final String amount;
  final String trend;
  final bool isTrendingUp;
  final bool isTrendNeutral;

  const BillHistoryTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.date,
    required this.usage,
    required this.rate,
    required this.amount,
    required this.trend,
    this.isTrendingUp = false,
    this.isTrendNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25), // ~10% opacity
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$usage kWh • $rate / day",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isTrendNeutral
                          ? Colors.transparent
                          : (isTrendingUp
                                ? AppColors.alertRed.withAlpha(25)
                                : AppColors.ecoGreen.withAlpha(25)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isTrendNeutral)
                          Icon(
                            isTrendingUp
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 10,
                            color: isTrendingUp
                                ? AppColors.alertRed
                                : AppColors.ecoGreen,
                          ),
                        if (!isTrendNeutral) const SizedBox(width: 4),
                        Text(
                          trend,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isTrendNeutral
                                ? AppColors.textSecondary.withAlpha(150)
                                : (isTrendingUp
                                      ? AppColors.alertRed
                                      : AppColors.ecoGreen),
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
}
