import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';

class MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  MenuItemData({required this.icon, required this.title, required this.onTap});
}

class ProfileMenuSection extends StatelessWidget {
  final String? title;
  final List<MenuItemData> items;

  const ProfileMenuSection({super.key, this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withAlpha(150),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF8FAFC,
                ), // Same light gray as the image list
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Icon(
                          item.icon,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary.withAlpha(200),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onTap: item.onTap,
                      ),
                      if (index < items.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.shade300,
                          indent: 52, // Indent to align with text
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
