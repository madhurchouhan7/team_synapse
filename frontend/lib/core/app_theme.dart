import 'package:flutter/material.dart';
import 'package:watt_sense/core/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.background,

      // color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.ecoGreen,
        error: AppColors.alertRed,
        surface: AppColors.surface,
      ),
    );
  }
}
