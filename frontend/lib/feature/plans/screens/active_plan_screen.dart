import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/auth/repository/user_repository.dart';
import 'package:watt_sense/feature/notifications/screens/notification_list_screen.dart';
import 'package:watt_sense/feature/plans/provider/ai_plan_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:watt_sense/feature/insights/providers/heatmap_provider.dart';

import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';
import 'package:watt_sense/feature/dashboard/widgets/quick_check_in_bottom_sheet.dart';

class ActivePlanScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> activePlan;

  const ActivePlanScreen({super.key, required this.activePlan});

  @override
  ConsumerState<ActivePlanScreen> createState() => _ActivePlanScreenState();
}

class _ActivePlanScreenState extends ConsumerState<ActivePlanScreen> {
  // Toggle states: false = not completed today
  List<bool> actionToggles = [];
  bool _isDeleting = false;

  // SharedPreferences key prefix for toggle persistence
  static const _kTogglePrefix = 'daily_action_toggle_';
  static const _kLastResetDate = 'daily_action_last_reset_date';

  @override
  void initState() {
    super.initState();
    final actions = widget.activePlan['keyActions'] as List<dynamic>? ?? [];
    // Initialise with falsy defaults until prefs are loaded
    actionToggles = List.filled(actions.length, false);
    // Load persisted state + handle daily reset
    _loadToggles();
  }

  // ── Persistence helpers ──────────────────────────────────────────────────────

  /// Returns today's date as "YYYY-MM-DD" (local time, not UTC, so the reset
  /// aligns with the user's midnight rather than server midnight).
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Loads saved toggle states and resets them if it's a new day.
  Future<void> _loadToggles() async {
    final prefs = await SharedPreferences.getInstance();
    final actions = widget.activePlan['keyActions'] as List<dynamic>? ?? [];
    final savedDate = prefs.getString(_kLastResetDate) ?? '';
    final today = _todayKey;

    if (savedDate != today) {
      // ── New day: reset ALL toggles to false ──────────────────────────────────
      final newToggles = List.filled(actions.length, false);
      await _saveToggles(newToggles, prefs);
      await prefs.setString(_kLastResetDate, today);
      if (mounted) setState(() => actionToggles = newToggles);
    } else {
      // ── Same day: restore previous state ────────────────────────────────────
      final restored = List<bool>.generate(
        actions.length,
        (i) => prefs.getBool('$_kTogglePrefix$i') ?? false,
      );
      if (mounted) setState(() => actionToggles = restored);
    }

    // Sync heatmap intensity with restored state (background only)
    await _recordHeatmap();
  }

  /// Persists the toggle list to SharedPreferences.
  Future<void> _saveToggles(List<bool> toggles, [SharedPreferences? p]) async {
    final prefs = p ?? await SharedPreferences.getInstance();
    for (int i = 0; i < toggles.length; i++) {
      await prefs.setBool('$_kTogglePrefix$i', toggles[i]);
    }
  }

  /// Computes the current intensity and sends it to the heatmap notifier.
  Future<void> _recordHeatmap() async {
    final completed = actionToggles.where((v) => v).length;
    final total = actionToggles.length;
    // Fire-and-forget; errors are caught inside the notifier
    ref
        .read(heatmapNotifierProvider.notifier)
        .recordIntensity(completedCount: completed, totalCount: total);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final streakState = ref.watch(streakStateProvider);
    final streak = streakState.streak;
    final checkedInToday = streakState.checkedInToday;
    final plan = widget.activePlan;

    // Fallback UI mapping
    final savingsObj =
        plan['estimatedSavingsIfFollowed'] as Map<String, dynamic>?;
    final savingsRupees = savingsObj?['rupees']?.toString() ?? '0.00';
    final savingsPercent = savingsObj?['percentage']?.toString() ?? '0';

    final actions = plan['keyActions'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Overview',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Active Plan',
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
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
                      'Delete Plan?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete the current plan? This action cannot be undone.',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
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

              if (confirm == true) {
                setState(() => _isDeleting = true);
                try {
                  await ref.read(userRepositoryProvider).saveActivePlan(null);
                  await ref.read(aiPlanProvider.notifier).clearPlan();
                  if (context.mounted) {
                    ref.invalidate(authStateProvider);
                    // No need to pushReplacement to DesignPlanScreen.
                    // Invalidating authProvider causes PlansScreen to organically render DesignPlanScreen
                    // while naturally keeping the BottomNavigationBar visible.
                  }
                } catch (e) {
                  if (context.mounted) {
                    setState(() => _isDeleting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete plan: $e')),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationListScreen(),
                ),
              );
            },
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
          // Padding(
          //   padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          //   child: CircleAvatar(
          //     radius: 18,
          //     backgroundColor: Colors.grey.shade200,
          //     backgroundImage: user?.photoUrl != null
          //         ? NetworkImage(user!.photoUrl!)
          //         : null,
          //     child: user?.photoUrl == null
          //         ? const Icon(Icons.person, color: Colors.grey)
          //         : null,
          //   ),
          // ),
        ],
      ),
      body: _isDeleting
          ? _buildShimmerLoading()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildPrimaryCard(plan).animate().fade().slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                    const SizedBox(height: 24),
                    _buildMetricsRow(
                          savingsRupees,
                          savingsPercent,
                          streak,
                          checkedInToday,
                        )
                        .animate()
                        .fade(delay: 100.ms)
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Daily Actions',
                      'Manage',
                    ).animate().fade(delay: 200.ms),
                    const SizedBox(height: 16),
                    ...List.generate(actions.length, (index) {
                      final action = actions[index] as Map<String, dynamic>;
                      return _buildActionTile(action, index)
                          .animate()
                          .fade(delay: (250 + (index * 50)).ms)
                          .slideX(begin: 0.1, end: 0, duration: 400.ms);
                    }),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Previous Plans',
                      'View All',
                    ).animate().fade(delay: 350.ms),
                    const SizedBox(height: 16),
                    _buildPreviousPlanTile(
                      icon: Icons.local_fire_department,
                      title: 'Winter Heating',
                      subtitle: 'Ended Mar 30 • ',
                      highlight: '92% Adherence',
                      highlightColor: Colors.green,
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 12),
                    _buildPreviousPlanTile(
                      icon: Icons.bolt,
                      title: 'Spring Baseline',
                      subtitle: 'Ended May 30 • ',
                      highlight: '78% Adherence',
                      highlightColor: Colors.orange,
                    ).animate().fade(delay: 450.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(
                      height: 100,
                    ), // padding for invisible bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  height: 24,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  3,
                  (index) => Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white54);
  }

  Widget _buildPrimaryCard(Map<String, dynamic> plan) {
    // Determine priority
    final highestPriority = plan['keyActions']?[0]?['priority'] ?? 'High';

    int totalActions = actionToggles.length;
    int activeActions = actionToggles.where((e) => e).length;
    double adherenceRatio = totalActions > 0
        ? activeActions / totalActions
        : 0.0;
    int adherenceValue = (adherenceRatio * 100).round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ac_unit, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Efficiency Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Active since Today',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Priority\n${highestPriority.toString().replaceFirst(highestPriority[0], highestPriority[0].toUpperCase())}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Circular Progress
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: adherenceRatio,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$adherenceValue%',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ADHERENCE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => showQuickCheckInBottomSheet(context),
              icon: const Icon(
                Icons.check_circle_outline,
                color: AppColors.primaryBlue,
              ),
              label: Text(
                'Quick Check-in',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
    String savingsRupees,
    String savingsPercent,
    int streak,
    bool checkedInToday,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: checkedInToday
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        checkedInToday ? '✅ TODAY' : 'ON TRACK',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: checkedInToday
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: streak.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: '/30',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak == 1 ? '1 Day Streak' : '$streak Days Streak',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  child: LinearProgressIndicator(
                    value: (streak / 30).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      checkedInToday ? Colors.green : Colors.orange.shade400,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SAVINGS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.savings, size: 16, color: AppColors.primaryBlue),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹$savingsRupees',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated this cycle',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '↗ +$savingsPercent% vs last month',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          action,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(Map<String, dynamic> actionMap, int index) {
    String title = actionMap['action'] ?? 'Unspecified Action';
    String subtitle = actionMap['appliance'] ?? '';

    // Choose an icon based on appliance logic roughly
    IconData icon = Icons.electrical_services;
    Color iconBg = Colors.purple.shade50;
    Color iconColor = Colors.purple.shade400;

    final lower = subtitle.toLowerCase();
    if (lower.contains('ac') || lower.contains('cooling')) {
      icon = Icons.thermostat;
      iconBg = Colors.blue.shade50;
      iconColor = AppColors.primaryBlue;
    } else if (lower.contains('geyser') || lower.contains('water')) {
      icon = Icons.water_drop;
      iconBg = Colors.orange.shade50;
      iconColor = Colors.orange.shade500;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily • $subtitle',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Styled switch with active tick
          SizedBox(
            width: 50,
            height: 30,
            child: Switch(
              value: actionToggles[index],
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primaryBlue,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
              ),
              onChanged: (val) {
                setState(() {
                  actionToggles[index] = val;
                });
                // Persist to SharedPreferences
                _saveToggles(actionToggles);
                // Update heatmap intensity (optimistic + background API call)
                _recordHeatmap();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousPlanTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String highlight,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: highlight,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: highlightColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
