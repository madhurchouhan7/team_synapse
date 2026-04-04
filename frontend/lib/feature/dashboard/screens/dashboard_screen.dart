import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/dashboard/providers/dashboard_provider.dart';
import 'package:watt_sense/feature/dashboard/widgets/dashboard_app_bar.dart';
import 'package:watt_sense/feature/dashboard/widgets/no_bills_empty_state.dart';
import 'package:watt_sense/feature/dashboard/widgets/quick_check_in_bottom_sheet.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';
import 'package:watt_sense/feature/profile/screens/profile_screen.dart';
import 'package:watt_sense/feature/insights/widgets/streak_card.dart';
import 'package:watt_sense/feature/bill/screen/add_bill_screen.dart';
import 'package:watt_sense/feature/notifications/screens/notification_list_screen.dart';
import 'package:watt_sense/feature/insights/providers/heatmap_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── State ──────────────────────────────────────────────────────────
    final userAsync = ref.watch(authStateProvider);
    final hasBills = ref.watch(hasBillsProvider);

    final displayName =
        userAsync.valueOrNull?.displayName?.split(' ').first ??
        userAsync.valueOrNull?.email.split('@').first ??
        'there';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: SafeArea(
          child: hasBills
              ? _DataView(displayName: displayName, user: userAsync.valueOrNull)
              : _EmptyView(
                  displayName: displayName,
                  user: userAsync.valueOrNull,
                ),
        ),
      ),
    );
  }
}

// ─── Empty State (no bills added) ─────────────────────────────────────────────
class _EmptyView extends ConsumerWidget {
  final String displayName;
  final UserModel? user;
  const _EmptyView({required this.displayName, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(authRepositoryProvider).refreshUserData();
        ref.invalidate(authStateProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── App bar ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: width * 0.04,
                  ),
                  child: DashboardAppBar(
                    user: user,
                    displayName: displayName,
                    onNotificationTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationListScreen(),
                        ),
                      );
                    },
                  ),
                ),

                // ── Empty state centred in remaining space ────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(vertical: width * 0.04),
                      child: NoBillsEmptyState(
                        onAddBill: () {
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data View (bills exist) ──────────────────────────────────────────────────
class _DataView extends ConsumerWidget {
  final String displayName;
  final UserModel? user;
  const _DataView({required this.displayName, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authRepositoryProvider).refreshUserData();
          ref.invalidate(authStateProvider);
          final now = DateTime.now();
          await ref
              .read(heatmapNotifierProvider.notifier)
              .refreshFromServer(year: now.year, month: now.month);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardAppBar(
                displayName: displayName,
                user: user,
                onNotificationTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationListScreen(),
                    ),
                  );
                },
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildStatCards(ref),

              const SizedBox(height: 28),
              _buildSectionTitle('Active Plan', showIndicator: true),
              const SizedBox(height: 16),
              _buildActivePlanCard(context, ref, user),
              const SizedBox(height: 28),
              const StreakCard(),
              const SizedBox(height: 28),
              _buildSectionTitle('Action Items'),
              const SizedBox(height: 16),
              _buildActionItems(user),
              const SizedBox(height: 28),
              _buildSectionTitleWithAction('Recent Activity', 'View All'),
              const SizedBox(height: 16),
              _buildRecentActivity(ref),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(WidgetRef ref) {
    final savedBill = ref.watch(savedBillProvider);
    final currentBillAmount = savedBill?['amountExact'];
    String currentBillStr;
    if (currentBillAmount != null) {
      // amountExact can be int, double, or String (from OCR/text fields)
      final parsed = double.tryParse(currentBillAmount.toString());
      if (parsed != null) {
        currentBillStr = parsed == parsed.truncateToDouble()
            ? parsed.toInt().toString()
            : parsed.toStringAsFixed(2);
      } else {
        currentBillStr = currentBillAmount.toString();
      }
    } else {
      currentBillStr = '--';
    }
    final hasBill = savedBill != null;

    final rawSubsidy = savedBill?['subsidyAmount'];
    String? subsidyStr;
    if (rawSubsidy != null &&
        rawSubsidy.toString() != '0.00' &&
        rawSubsidy.toString().isNotEmpty) {
      if (rawSubsidy is int) {
        subsidyStr = rawSubsidy.toString();
      } else if (rawSubsidy is double) {
        subsidyStr = rawSubsidy.toStringAsFixed(2);
      } else {
        subsidyStr = rawSubsidy.toString();
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconWidget: const Icon(
              Icons.receipt_long,
              color: Color(0xFF1E60F2),
              size: 20,
            ),
            iconBg: const Color(0xFFEFF6FF),
            badge: hasBill
                ? const _TrendBadge(value: 'NEW', isUp: false)
                : null,
            label: 'Current Bill',
            value: '₹$currentBillStr',
            subLabel: hasBill
                ? 'Due ${savedBill['dueDate'] ?? 'Soon'}'
                : 'No bill fetched',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            iconWidget: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 20,
            ),
            iconBg: const Color(0xFFECFDF5),
            label: subsidyStr != null ? 'Subsidy Saved' : 'Last Paid',
            value: subsidyStr != null
                ? '₹$subsidyStr'
                : (hasBill ? '₹--' : '--'),
            subLabel: subsidyStr != null
                ? 'Govt Subsidy Applied!'
                : (hasBill ? 'Checking history...' : 'No local history'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showIndicator = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showIndicator) ...[
          const SizedBox(width: 8),
          Container(
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitleWithAction(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(title),
        Text(
          action,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E60F2),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlanCard(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
  ) {
    if (user?.activePlan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
            const Icon(Icons.auto_awesome, color: Color(0xFF94A3B8), size: 32),
            const SizedBox(height: 12),
            Text(
              'No AI Plan Active',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Head to the Plans tab to generate your AI savings strategy!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final p = user!.activePlan!;
    final planName = p['planName']?.toString() ?? 'AI Efficiency Plan';
    final estSavingsObj = p['estimatedSavingsIfFollowed'] as Map<String, dynamic>?;
    final pct = estSavingsObj?['percentage']?.toString() ?? '0';
    final tierDesc = 'Targeting $pct% savings';

    final savedBill = ref.watch(savedBillProvider);
    final currentSpend =
        double.tryParse(savedBill?['amountExact']?.toString() ?? '0') ?? 0;

    var usageTarget = 'Optimizing...';
    double fillRatio = 0.0;

    final estCost = double.tryParse(p['estimatedCurrentMonthlyCost']?.toString() ?? '');
    final estSavings = double.tryParse(estSavingsObj?['rupees']?.toString() ?? '');

    if (estCost != null && estSavings != null) {
      final targetRupees = estCost - estSavings;

      if (targetRupees > 0) {
        usageTarget =
            '₹${currentSpend.toInt()} / ₹${targetRupees.toInt()} Limit';
        fillRatio = currentSpend / targetRupees;
      }
    } else if (currentSpend > 0) {
      usageTarget = '₹${currentSpend.toInt()} Usage';
      fillRatio = 0.3; // Show a small hint of progress if target is unavailable
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E60F2), Color(0xFF144CC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E60F2).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tierDesc,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              Text(
                usageTarget,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (_, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3996),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * fillRatio.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => showQuickCheckInBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E60F2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Quick Check-in',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItems(UserModel? user) {
    List<Widget> customStrategies = [];

    if (user?.activePlan != null && user!.activePlan!['keyActions'] != null) {
      final actions = user.activePlan!['keyActions'] as List<dynamic>;
      // Take first 2 strategies for dashboard compact view
      for (var actionItem in actions.take(2)) {
        final priority =
            actionItem['priority']?.toString().toLowerCase() ?? 'medium';
        Color iconColor;
        Color bgColor;
        Color borderColor;
        IconData icon;

        if (priority == 'high') {
          iconColor = const Color(0xFFEA580C);
          bgColor = const Color(0xFFFFF7ED);
          borderColor = const Color(0xFFFFEDD5);
          icon = Icons.priority_high_rounded;
        } else {
          iconColor = const Color(0xFF16A34A);
          bgColor = const Color(0xFFF0FDF4);
          borderColor = const Color(0xFFBBF7D0);
          icon = Icons.tips_and_updates_outlined;
        }

        customStrategies.add(
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionItem['appliance']?.toString() ?? 'Smart Strategy',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actionItem['action']?.toString() ??
                            'Optimize to save...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Default placeholder if strategies array is totally empty/missing
    if (customStrategies.isEmpty) {
      customStrategies.add(
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Actions Pending',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate a plan to see customized savings tips here.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...customStrategies,
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Log New Meter Reading',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(WidgetRef ref) {
    final savedBill = ref.watch(savedBillProvider);
    final activities = <Map<String, dynamic>>[];

    // Inject the real tracked bill if it exists
    if (savedBill != null) {
      activities.add({
        'title': savedBill['billerId'] ?? 'Electricity Bill',
        'subtitle': 'Due ${savedBill['dueDate'] ?? 'Soon'}',
        'amount': '₹${savedBill['amountExact']?.toString() ?? 0}',
        'status': 'Pending',
        'isPaid': false,
        'isGrey': false,
        'imageBase64': savedBill['imageBase64'],
      });
    }

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off,
              color: Color(0xFF94A3B8),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isGrey = (item['isGrey'] as bool?) ?? false;
          final isPaid = (item['isPaid'] as bool?) ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isGrey
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(
                          item['imageBase64'] != null ? 8 : 32,
                        ),
                        image:
                            item['imageBase64'] != null &&
                                item['imageBase64'].toString().isNotEmpty
                            ? DecorationImage(
                                image: MemoryImage(
                                  base64Decode(item['imageBase64']),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          item['imageBase64'] != null &&
                              item['imageBase64'].toString().isNotEmpty
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                            ) // Empty space to respect image size
                          : Icon(
                              isGrey
                                  ? Icons.build_outlined
                                  : Icons.description_outlined,
                              color: isGrey
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF1E60F2),
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item['amount'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['status'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (index < activities.length - 1)
                const Divider(
                  height: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final Widget iconWidget;
  final Color iconBg;
  final Widget? badge;
  final String label;
  final String value;
  final String? subLabel;

  const _StatCard({
    required this.iconWidget,
    required this.iconBg,
    required this.label,
    required this.value,
    this.badge,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: iconWidget,
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              subLabel!,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String value;
  final bool isUp;

  const _TrendBadge({required this.value, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUp ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            color: isUp ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isUp ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
