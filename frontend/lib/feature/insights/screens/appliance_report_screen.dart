import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
// import 'package:watt_sense/feature/insights/providers/insights_provider.dart';
import 'dart:math';

class ApplianceReportScreen extends ConsumerStatefulWidget {
  const ApplianceReportScreen({super.key});

  @override
  ConsumerState<ApplianceReportScreen> createState() =>
      _ApplianceReportScreenState();
}

class _ApplianceReportScreenState extends ConsumerState<ApplianceReportScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _past7Days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _past7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
    ).reversed.toList();
    _selectedDate = _past7Days.last;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Map<String, dynamic>> _generateBreakdownData(DateTime date) {
    final random = Random(date.day * date.month * date.year);
    int ac = 25 + random.nextInt(30);
    int heating = 10 + random.nextInt(20);
    int lighting = 10 + random.nextInt(15);
    int others = 100 - (ac + heating + lighting);
    return [
      {"name": "Cooling (AC)", "percentage": ac, "colorHex": 0xFF3B82F6},
      {"name": "Heating", "percentage": heating, "colorHex": 0xFFEF4444},
      {"name": "Lighting", "percentage": lighting, "colorHex": 0xFFEAB308},
      {"name": "Others", "percentage": others, "colorHex": 0xFF10B981},
    ];
  }

  List<Map<String, dynamic>> _generateDetailedData(DateTime date) {
    final random = Random(date.day * date.month * date.year);
    final isWeekend = date.weekday == 6 || date.weekday == 7;
    // On weekends, expect more power usage
    final multiplier = isWeekend ? 1.5 : 1.0;
    
    final totalCost = (60 + random.nextInt(80)) * multiplier; 
    
    return [
      {
        "name": "Master Bedroom AC",
        "subtitle": "1.5 Ton • Inverter",
        "kwh": ((4 + random.nextDouble() * 6) * multiplier).toStringAsFixed(1),
        "cost": (totalCost * 0.45).toStringAsFixed(0),
        "status": random.nextBool() ? "Optimal" : "High Usage",
        "colorHex": 0xFF3B82F6,
        "icon": Icons.ac_unit_rounded,
      },
      {
        "name": "Water Heater",
        "subtitle": "25L • Storage",
        "kwh": ((2 + random.nextDouble() * 3) * multiplier).toStringAsFixed(1),
        "cost": (totalCost * 0.20).toStringAsFixed(0),
        "status": random.nextBool() ? "Optimal" : "High Usage",
        "colorHex": 0xFFEF4444,
        "icon": Icons.water_drop_rounded,
      },
      {
        "name": "Living Room Lights",
        "subtitle": "LED Array",
        "kwh": ((0.5 + random.nextDouble() * 1) * multiplier).toStringAsFixed(1),
        "cost": (totalCost * 0.10).toStringAsFixed(0),
        "status": "Optimal",
        "colorHex": 0xFFEAB308,
        "icon": Icons.lightbulb_outline_rounded,
      },
      {
        "name": "Refrigerator",
        "subtitle": "Double Door",
        "kwh": ((2.5 + random.nextDouble() * 2) * multiplier).toStringAsFixed(1),
        "cost": (totalCost * 0.25).toStringAsFixed(0),
        "status": "Optimal",
        "colorHex": 0xFF10B981,
        "icon": Icons.kitchen_rounded,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final breakdownData = _generateBreakdownData(_selectedDate);
    final detailedData = _generateDetailedData(_selectedDate);
    final totalKwh = detailedData.fold(
      0.0, 
      (sum, item) => sum + double.parse(item['kwh'] as String)
    );
    
    final formattedDate = "${_selectedDate.day} ${_getMonthName(_selectedDate.month)}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Appliance Report",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formattedDate,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date Selector (Past 7 Days) ──────────────────────────────
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _past7Days.length,
                itemBuilder: (context, index) {
                  final date = _past7Days[index];
                  final isSelected = _selectedDate.day == date.day && 
                                     _selectedDate.month == date.month &&
                                     _selectedDate.year == date.year;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fade().slideY(begin: -0.1),

            const SizedBox(height: 32),

            // ── Consumption Summary Card ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DAILY SUMMARY",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withOpacity(0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: DonutChartPainter(
                              data: breakdownData,
                              strokeWidth: 20,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalKwh.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                "Total kWh",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Legend Grid (2 columns)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 35,
                          crossAxisSpacing: 16,
                        ),
                    itemCount: breakdownData.length,
                    itemBuilder: (context, index) {
                      final item = breakdownData[index];
                      return Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(item['colorHex'] as int),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['name'] as String,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            "${item['percentage']}%",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ).animate().fade().scale(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 40),

            Text(
              "Appliance Breakdown",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ).animate().fade(delay: 200.ms).slideX(begin: -0.1, end: 0),

            const SizedBox(height: 16),

            // ── Appliance List ──────────────────────────────────────
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detailedData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = detailedData[index];
                return _ApplianceCard(item: item)
                    .animate()
                    .fade(delay: (300 + index * 100).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ApplianceCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ApplianceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item['status'] == 'High Usage'
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(item['colorHex'] as int).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  (item['icon'] as IconData?) ?? Icons.devices_other_rounded,
                  color: Color(item['colorHex'] as int),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      item['subtitle'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${item['cost']}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "${item['kwh']} kWh",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['status'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (item['status'] == 'High Usage')
                InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        "Deep Dive",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donut Chart Painter (Reusable) ───────────────────────────────────────────

class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double strokeWidth;

  DonutChartPainter({required this.data, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -pi / 2;
    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final double gapAngle = 0.05;

    for (var item in data) {
      final double percentage = (item['percentage'] as int) / 100;
      final double sweepAngle = (percentage * 2 * pi);

      final double currentSweep = max(0, sweepAngle - gapAngle);

      final paint = Paint()
        ..color = Color(item['colorHex'] as int)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        currentSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
