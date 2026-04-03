import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';

class BillTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? infoText;
  final Widget? infoIcon;
  final bool isLarge;

  const BillTextField({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.infoText,
    this.infoIcon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withAlpha(200),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: isLarge ? 56 : 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: prefixIcon,
                ),
              ],
              Expanded(
                child: TextField(
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary.withAlpha(150),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: suffixIcon,
                ),
              ],
            ],
          ),
        ),
        if (infoText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (infoIcon != null) ...[infoIcon!, const SizedBox(width: 4)],
              Text(
                infoText!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
