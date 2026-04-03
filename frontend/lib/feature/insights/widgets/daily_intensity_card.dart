import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/insights/providers/heatmap_provider.dart';

class DailyIntensityCard extends ConsumerStatefulWidget {
  const DailyIntensityCard({super.key});

  @override
  ConsumerState<DailyIntensityCard> createState() => _DailyIntensityCardState();
}

class _DailyIntensityCardState extends ConsumerState<DailyIntensityCard> {
  @override
  void initState() {
    super.initState();
    // Kick off a background server sync when the card first mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      ref
          .read(heatmapNotifierProvider.notifier)
          .refreshFromServer(year: now.year, month: now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the heatmap data (keyed by "YYYY-MM-DD")
    final heatmapData = ref.watch(heatmapProvider);

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // ── Build the calendar-month grid ────────────────────────────────────────
    // daysInMonth: correctly handles 28/29/30/31 day months
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    // weekdayOffset: 0=Mon … 6=Sun (Flutter's DateTime.weekday is 1=Mon, 7=Sun)
    final firstDayOfMonth = DateTime(year, month, 1);
    // Convert to 0-indexed Mon=0 offset
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;

    // Total grid slots (multiples of 7 rows)
    final totalCells = startOffset + daysInMonth;
    final numRows = (totalCells / 7).ceil();

    // Build month label: "March 2026"
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = '${monthNames[month - 1]} $year';

    // Day header labels
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic cell size that fills available width
        const horizontalPadding = 24.0 * 2;
        const columnSpacing = 6.0 * 6; // 6 gaps for 7 columns
        final availableWidth =
            constraints.maxWidth - horizontalPadding - columnSpacing;
        final double cellSize = (availableWidth / 7).floorToDouble();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueAccent.shade200.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Intensity',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      monthLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Day-of-week header ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dayLabels.map((label) {
                  return SizedBox(
                    width: cellSize,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withAlpha(160),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // ── Heatmap Grid ────────────────────────────────────────────────
              // Build [numRows] rows of 7 cells each. Empty cells (before day 1
              // or after the last day) are rendered as null → transparent.
              Column(
                children: List.generate(numRows, (rowIdx) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: rowIdx < numRows - 1 ? 6 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (colIdx) {
                        final cellIndex = rowIdx * 7 + colIdx;
                        final dayNumber = cellIndex - startOffset + 1;

                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          // Empty cell — placeholder keeps grid aligned
                          return SizedBox(width: cellSize, height: cellSize);
                        }

                        // Build the date key for this specific day
                        final dateKey =
                            '$year-${month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
                        final intensity = heatmapData[dateKey] ?? 0;

                        // Is this day in the future?
                        final cellDate = DateTime(year, month, dayNumber);
                        final isToday =
                            cellDate.year == now.year &&
                            cellDate.month == now.month &&
                            cellDate.day == now.day;
                        final isFuture = cellDate.isAfter(now);

                        return _HeatmapCell(
                          dayNumber: dayNumber,
                          intensity: intensity,
                          isToday: isToday,
                          isFuture: isFuture,
                          size: cellSize,
                        );
                      }),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),

              // ── Legend ───────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Less',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (int lvl = 0; lvl <= 3; lvl++) ...[
                    _LegendBox(level: lvl),
                    if (lvl < 3) const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    'More',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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

// ── Individual heatmap cell ──────────────────────────────────────────────────

class _HeatmapCell extends StatelessWidget {
  final int dayNumber;
  final int intensity;
  final bool isToday;
  final bool isFuture;
  final double size;

  const _HeatmapCell({
    required this.dayNumber,
    required this.intensity,
    required this.isToday,
    required this.isFuture,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFuture
        ? const Color(0xFFF1F5F9) // very light — future days
        : _colorForLevel(intensity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppColors.primaryBlue, width: 1.8)
            : null,
        boxShadow: intensity == 3 && !isFuture
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: size > 22
          ? Text(
              '$dayNumber',
              style: GoogleFonts.poppins(
                fontSize: size * 0.28,
                fontWeight: intensity >= 2 && !isFuture
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: _textColor(intensity, isFuture),
              ),
            )
          : null,
    );
  }

  Color _textColor(int level, bool future) {
    if (future) return Colors.grey.shade400;
    switch (level) {
      case 0:
        return Colors.grey.shade400;
      case 1:
        return const Color(0xFF1E40AF);
      case 2:
        return const Color(0xFF1E3A8A);
      case 3:
        return Colors.white;
      default:
        return Colors.grey.shade400;
    }
  }

  static Color _colorForLevel(int level) {
    switch (level) {
      case 0:
        return const Color(0xFFE2E8F0);
      case 1:
        return const Color(0xFFBFDBFE);
      case 2:
        return const Color(0xFF60A5FA);
      case 3:
        return AppColors.primaryBlue;
      default:
        return const Color(0xFFE2E8F0);
    }
  }
}

// ── Legend box ──────────────────────────────────────────────────────────────

class _LegendBox extends StatelessWidget {
  final int level;

  const _LegendBox({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _HeatmapCell._colorForLevel(level),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
