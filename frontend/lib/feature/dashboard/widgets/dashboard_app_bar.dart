import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';

/// Top app-bar row shown on the DashboardScreen.
///
/// Left  side: greeting text + bold user display name.
/// Right side: notification bell button and user profile icon.
class DashboardAppBar extends StatelessWidget {
  final String displayName;
  final UserModel? user;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DashboardAppBar({
    super.key,
    required this.displayName,
    this.user,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Greeting ──────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName.isNotEmpty ? displayName : 'User',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // ── Notification bell ─────────────────────────────────
        GestureDetector(
          onTap: onNotificationTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF334155),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Profile Icon ──────────────────────────────────────
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF1E60F2).withOpacity(0.1),
            foregroundImage:
                user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                ? NetworkImage(user!.photoUrl!)
                : null,
            onForegroundImageError: (_, __) {},
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E60F2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
