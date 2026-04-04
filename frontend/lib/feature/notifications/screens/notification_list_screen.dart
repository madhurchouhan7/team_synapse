// lib/feature/notifications/screens/notification_list_screen.dart
// Enhanced notification list with visual distinction for anomaly alerts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/notifications/models/notification_model.dart';
import 'package:watt_sense/feature/notifications/providers/notification_provider.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          state.maybeWhen(
            data: (notifications) {
              final unread = notifications.where((n) => !n.read).length;
              if (unread == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unread unread',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E60F2)),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFEF4444), size: 40),
                const SizedBox(height: 12),
                Text(
                  'Failed to load notifications',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(notificationListProvider.notifier).refresh(),
                  child: Text('Retry', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Color(0xFF94A3B8), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'You have no notifications yet.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            // Separate anomaly alerts from general notifications
            final anomalies = notifications
                .where((n) => n.isAnomalyAlert)
                .toList();
            final general = notifications
                .where((n) => !n.isAnomalyAlert)
                .toList();

            return RefreshIndicator(
              color: const Color(0xFF1E60F2),
              onRefresh: () =>
                  ref.read(notificationListProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                children: [
                  // ── Anomaly alerts section ──────────────────────────────
                  if (anomalies.isNotEmpty) ...[
                    _SectionHeader(
                      label: '⚡ Usage Alerts',
                      count: anomalies.length,
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 8),
                    ...anomalies.map(
                      (n) => _AnomalyNotificationCard(
                        notification: n,
                        onTap: () => ref
                            .read(notificationListProvider.notifier)
                            .markAsRead(n.id),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── General notifications section ───────────────────────
                  if (general.isNotEmpty) ...[
                    if (anomalies.isNotEmpty)
                      _SectionHeader(
                        label: 'All Notifications',
                        count: general.length,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap:  true,
                      physics:     const NeverScrollableScrollPhysics(),
                      itemCount:   general.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = general[index];
                        return _NotificationTile(
                          notification: n,
                          onTap: () => ref
                              .read(notificationListProvider.notifier)
                              .markAsRead(n.id),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Anomaly card — visually distinct red card ────────────────────────────────
class _AnomalyNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _AnomalyNotificationCard(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.read
              ? const Color(0xFFFFF5F5)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.read
                ? const Color(0xFFFECACA)
                : const Color(0xFFFCA5A5),
            width: notification.read ? 1 : 1.5,
          ),
          boxShadow: notification.read
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: notification.read
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: notification.read
                    ? const Color(0xFFEF4444)
                    : Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontWeight: notification.read
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF991B1B),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.anomalyWattage != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${notification.anomalyWattage} W detected',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Standard notification tile ────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Icon(
        notification.read
            ? Icons.notifications_none_rounded
            : Icons.notifications_active_rounded,
        color: notification.read
            ? AppColors.textSecondary
            : AppColors.primaryBlue,
      ),
      title: Text(
        notification.title,
        style: GoogleFonts.poppins(
          fontWeight:
              notification.read ? FontWeight.w500 : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        notification.body,
        style: GoogleFonts.poppins(color: AppColors.textSecondary),
      ),
      onTap: onTap,
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
