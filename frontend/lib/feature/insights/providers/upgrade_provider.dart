import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for estimated potential savings
final estimatedSavingsProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'amount': '₹24,500',
    'period': 'year',
    'equivalent': '10 planting 12 trees annually',
  };
});

// Provider for upgrade recommendations
final upgradeRecommendationsProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  return [
    {
      'id': '1',
      'title': '10-Year-Old AC',
      'alert': 'High Usage Alert',
      'description': 'Bedroom unit consuming 42% of total load.',
      'recommendedUpgrade': 'Inverter 5-Star Split',
      'annualSavings': '₹14,200',
      'paybackPeriod': '18 months',
      'environmentalImpact': 'HIGH',
      'icon': Icons.ac_unit_rounded,
      'iconColor': 0xFF2563EB,
    },
    {
      'id': '2',
      'title': '3-Star Refrigerator',
      'alert': 'Inefficient Load',
      'description': 'Double-door unit (2018 model).',
      'upgradePath': 'Twin inverter 5-Star',
      'annualSavings': '₹6,800',
      'paybackPeriod': '24 months break-even',
      'efficiencyGain': 0.75, // 75% efficiency gain bar
      'icon': Icons.kitchen_rounded,
      'iconColor': 0xFF60A5FA,
    },
  ];
});

// Provider for performance comparison data
final performanceComparisonProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  return [
    {
      'title': 'Modern inverter compressors',
      'description':
          'adjust cooling speed dynamically, reducing startup surge by 50% compared to your current units.',
      'icon': Icons.speed_rounded,
    },
    {
      'title': 'Transitioning to R32 refrigerants',
      'description':
          'reduces GWP (Global Warming Potential) by 3x compared to older R22 models found in your AC.',
      'icon': Icons.eco_rounded,
    },
    {
      'title': 'Smart connectivity',
      'description':
          'allows scheduling peak-hour throttling, potentially saving an additional ₹2,300/year on TCO billing.',
      'icon': Icons.schedule_rounded,
    },
  ];
});

// Provider for subsidy information
final subsidyProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'eligible': true,
    'amount': '₹5,000',
    'description': 'You\'re eligible for ₹5,000 govt. rebate on 5-star swaps',
    'buttonText': 'Check Eligibility',
  };
});
