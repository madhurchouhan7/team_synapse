import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';
import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';
import 'package:watt_sense/feature/insights/providers/heatmap_provider.dart';

// Dynamically sets current month context
final selectedMonthProvider = Provider<String>((ref) {
  final now = DateTime.now();
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[now.month - 1]} ${now.year}';
});

// Provides the total energy consumed from the latest saved bill
final totalConsumptionProvider = Provider<double>((ref) {
  final savedBill = ref.watch(savedBillProvider);
  if (savedBill != null) {
    // Attempt to get unitsConsumed (might be from OCR or biller data)
    final units = double.tryParse(savedBill['unitsConsumed']?.toString() ?? '');
    if (units != null) return units;

    // Fallback: estimate based on amount (e.g. ₹8 per unit)
    final amount =
        double.tryParse(savedBill['amountExact']?.toString() ?? '0') ?? 0;
    if (amount > 0) return (amount / 8).roundToDouble();
  }
  return 452.0; // Baseline mock if no bill exists
});

// Provides the total cost from the latest saved bill
final totalCostProvider = Provider<double>((ref) {
  final savedBill = ref.watch(savedBillProvider);
  if (savedBill != null) {
    return double.tryParse(savedBill['amountExact']?.toString() ?? '3850') ??
        3850.0;
  }
  return 3850.0;
});

// Provides dynamic Efficiency Score from the AI Plan schema
final efficiencyScoreProvider = Provider<int>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final isOptimistic = ref.watch(optimisticCheckInProvider);
  final user = userAsync.valueOrNull;
  final activePlan = user?.activePlan;

  int baseScore = 82;
  if (activePlan != null && activePlan['efficiencyScore'] != null) {
    baseScore = (activePlan['efficiencyScore'] as num).toInt();
  }

  // Boost score slightly if user checked in today
  bool checkedInToday = isOptimistic;
  if (!checkedInToday && user?.lastCheckIn != null) {
    final now = DateTime.now();
    final last = user!.lastCheckIn!;
    if (now.year == last.year &&
        now.month == last.month &&
        now.day == last.day) {
      checkedInToday = true;
    }
  }

  if (checkedInToday) {
    baseScore = (baseScore + 5).clamp(0, 100);
  }

  return baseScore;
});

// Dynamic appliance breakdown based on what the AI prioritized
final applianceBreakdownProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final activePlan = userAsync.valueOrNull?.activePlan;

  if (activePlan != null && activePlan['keyActions'] != null) {
    final actions = activePlan['keyActions'] as List<dynamic>;
    if (actions.isNotEmpty) {
      // Map actions to detailed items if we have them
      return [
        {
          'name': actions.isNotEmpty
              ? actions[0]['appliance']?.toString() ?? 'Air'
              : 'Air',
          'percentage': 45,
          'colorHex': 0xFF2563EB,
          'icon': Icons.ac_unit_rounded,
        },
        {
          'name': actions.length > 1
              ? actions[1]['appliance']?.toString() ?? 'Refrigerator'
              : 'Refrigerator',
          'percentage': 20,
          'colorHex': 0xFF60A5FA,
          'icon': Icons.kitchen_rounded,
        },
        {
          'name': 'Water Heater',
          'percentage': 15,
          'colorHex': 0xFF93C5FD,
          'icon': Icons.hot_tub_rounded,
        },
        {
          'name': 'Lighting',
          'percentage': 10,
          'colorHex': 0xFFBFDBFE,
          'icon': Icons.lightbulb_outline_rounded,
        },
        {
          'name': 'Others',
          'percentage': 10,
          'colorHex': 0xFFE2E8F0,
          'icon': Icons.more_horiz_rounded,
        },
      ];
    }
  }

  return [
    {
      'name': 'Air',
      'percentage': 45,
      'colorHex': 0xFF2563EB,
      'icon': Icons.ac_unit_rounded,
    },
    {
      'name': 'Refrigerator',
      'percentage': 20,
      'colorHex': 0xFF60A5FA,
      'icon': Icons.kitchen_rounded,
    },
    {
      'name': 'Water Heater',
      'percentage': 15,
      'colorHex': 0xFF93C5FD,
      'icon': Icons.hot_tub_rounded,
    },
    {
      'name': 'Lighting',
      'percentage': 10,
      'colorHex': 0xFFBFDBFE,
      'icon': Icons.lightbulb_outline_rounded,
    },
    {
      'name': 'Others',
      'percentage': 10,
      'colorHex': 0xFFE2E8F0,
      'icon': Icons.more_horiz_rounded,
    },
  ];
});

// Provides detailed appliance data for the Full Report
final detailedApplianceProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final breakdown = ref.watch(applianceBreakdownProvider);
  final totalUnits = ref.watch(totalConsumptionProvider);
  final totalCost = ref.watch(totalCostProvider);

  return breakdown.map((item) {
    final percent = (item['percentage'] as int) / 100;
    return {
      ...item,
      'kwh': (totalUnits * percent).toStringAsFixed(1),
      'cost': (totalCost * percent).toInt(),
      'status': item['percentage'] > 30 ? 'High Usage' : 'Normal',
      'subtitle': item['name'].toString().contains('Air')
          ? 'Primary bedroom & Living'
          : 'Household appliance',
    };
  }).toList();
});

// Dynamic daily intensity — reads from Hive heatmap cache, returns a
// sorted list of intensity values for the current month (one per day so far).
// Backward-compatible consumer for anything watching dailyIntensityProvider.
final dailyIntensityProvider = Provider<List<int>>((ref) {
  // Reading from heatmapProvider (Hive-backed, instant)
  final heatmapData = ref.watch(heatmapProvider);

  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final daysInMonth = DateUtils.getDaysInMonth(year, month);

  // Build intensity list, one entry per day from day 1 to daysInMonth
  return List<int>.generate(daysInMonth, (i) {
    final day = i + 1;
    final dateKey =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return heatmapData[dateKey] ?? 0;
  });
});
