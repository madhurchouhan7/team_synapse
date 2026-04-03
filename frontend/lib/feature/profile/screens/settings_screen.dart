import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _billReminders = true;
  bool _planAlerts = true;
  bool _weeklyInsights = false;
  bool _biometricLock = true;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.valueOrNull;
    final email = user?.email ?? 'user@example.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("ACCOUNT"),
              _buildSectionContainer([
                _buildSettingsItem(
                  icon: Icons.mail_outline_rounded,
                  title: "Email",
                  subtitle: email,
                  trailing: _buildChevron(),
                ),
                _buildSettingsItem(
                  icon: Icons.phone_outlined,
                  title: "Phone Number",
                  subtitle: "+1 (555) 123-4567",
                  trailing: _buildChevron(),
                ),
                _buildSettingsItem(
                  icon: Icons.lock_outline_rounded,
                  title: "Password",
                  subtitle: "********",
                  trailing: _buildChevron(),
                  withBorder: false,
                ),
              ]),

              const SizedBox(height: 8),

              _buildSectionHeader("NOTIFICATIONS"),
              _buildSectionContainer([
                _buildSettingsItem(
                  icon: Icons.receipt_long_outlined,
                  title: "Bill Reminders",
                  trailing: _buildSwitch(_billReminders, (val) {
                    setState(() => _billReminders = val);
                  }),
                ),
                _buildSettingsItem(
                  icon: Icons.notifications_none_rounded,
                  title: "Plan Alerts",
                  trailing: _buildSwitch(_planAlerts, (val) {
                    setState(() => _planAlerts = val);
                  }),
                ),
                _buildSettingsItem(
                  icon: Icons.show_chart_rounded,
                  title: "Weekly Insights",
                  trailing: _buildSwitch(_weeklyInsights, (val) {
                    setState(() => _weeklyInsights = val);
                  }),
                  withBorder: false,
                ),
              ]),

              const SizedBox(height: 8),

              _buildSectionHeader("PREFERENCES"),
              _buildSectionContainer([
                _buildSettingsItem(
                  icon: Icons.payments_outlined,
                  title: "Currency",
                  trailing: _buildTextTrailing("₹ (INR)"),
                ),
                _buildSettingsItem(
                  icon: Icons.bolt_outlined,
                  title: "Units",
                  trailing: _buildTextTrailing("kWh"),
                ),
                _buildSettingsItem(
                  icon: Icons.dark_mode_outlined,
                  title: "Theme",
                  trailing: _buildTextTrailing("Light"),
                  withBorder: false,
                ),
              ]),

              const SizedBox(height: 8),

              _buildSectionHeader("SECURITY"),
              _buildSectionContainer([
                _buildSettingsItem(
                  icon: Icons.fingerprint_rounded,
                  title: "Biometric Lock",
                  trailing: _buildSwitch(_biometricLock, (val) {
                    setState(() => _biometricLock = val);
                  }),
                ),
                _buildSettingsItem(
                  icon: Icons.devices_outlined,
                  title: "Session Management",
                  trailing: _buildChevron(),
                  withBorder: false,
                ),
              ]),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => _showLogoutDialog(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "Log Out",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  "App Version 2.4.0 (Build 108)",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool withBorder = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (withBorder)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
            indent: 64,
            endIndent: 16,
          ),
      ],
    );
  }

  Widget _buildChevron() {
    return Icon(
      Icons.chevron_right_rounded,
      color: Colors.grey.shade400,
      size: 20,
    );
  }

  Widget _buildTextTrailing(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        _buildChevron(),
      ],
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 24,
      child: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.primaryBlue,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your WattWise account?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}
