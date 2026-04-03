import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/insights/widgets/savings_summary_widget.dart';
import 'package:watt_sense/feature/insights/widgets/upgrade_card_widget.dart';
import 'package:watt_sense/feature/insights/widgets/performance_comparison_widget.dart';
import 'package:watt_sense/feature/insights/widgets/subsidy_section_widget.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Upgrade Hub',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SavingsSummaryWidget(),
              SizedBox(height: 24),
              UpgradeCardWidget(),
              SizedBox(height: 24),
              PerformanceComparisonWidget(),
              SizedBox(height: 24),
              SubsidySectionWidget(),
              SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
