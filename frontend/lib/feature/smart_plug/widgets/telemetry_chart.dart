// lib/feature/smart_plug/widgets/telemetry_chart.dart
// Line chart of recent wattage readings using Syncfusion Flutter Charts.
// Anomaly data points are highlighted in red.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:watt_sense/feature/smart_plug/models/telemetry_reading_model.dart';

class TelemetryChart extends StatelessWidget {
  final List<TelemetryReading> readings;
  final double? baselineWattage;

  const TelemetryChart({
    super.key,
    required this.readings,
    this.baselineWattage,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_rounded,
                color: Color(0xFF94A3B8), size: 36),
            const SizedBox(height: 8),
            Text(
              'No readings yet',
              style: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Split into normal and anomaly series
    final normalReadings  = readings.where((r) => !r.isAnomaly).toList();
    final anomalyReadings = readings.where((r) => r.isAnomaly).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
        primaryXAxis: DateTimeAxis(
          labelStyle: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
          ),
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          dateFormat: null,
          intervalType: DateTimeIntervalType.minutes,
        ),
        primaryYAxis: NumericAxis(
          labelStyle: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
          ),
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(
            width: 1,
            color: Color(0xFFF1F5F9),
          ),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value}W',
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: const Color(0xFF1E293B),
          textStyle: GoogleFonts.poppins(
              color: Colors.white, fontSize: 11),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          textStyle: GoogleFonts.poppins(fontSize: 11),
        ),
        series: <CartesianSeries>[
          // Normal readings — blue spline
          SplineSeries<TelemetryReading, DateTime>(
            name: 'Wattage',
            dataSource:   normalReadings,
            xValueMapper: (r, _) => r.timestamp,
            yValueMapper: (r, _) => r.wattage,
            color:         const Color(0xFF1E60F2),
            width:         2,
            markerSettings: const MarkerSettings(
              isVisible: false,
            ),
            animationDuration: 500,
          ),

          // Anomaly readings — red scatter points
          ScatterSeries<TelemetryReading, DateTime>(
            name: 'Anomaly',
            dataSource:   anomalyReadings,
            xValueMapper: (r, _) => r.timestamp,
            yValueMapper: (r, _) => r.wattage,
            color:         const Color(0xFFEF4444),
            markerSettings: const MarkerSettings(
              isVisible:  true,
              shape:      DataMarkerType.diamond,
              height:     10,
              width:      10,
            ),
            animationDuration: 500,
          ),

          // Baseline reference line (if available)
          if (baselineWattage != null && baselineWattage! > 0)
            LineSeries<TelemetryReading, DateTime>(
              name: 'Baseline',
              dataSource:   readings,
              xValueMapper: (r, _) => r.timestamp,
              yValueMapper: (_, __) => baselineWattage,
              color:         const Color(0xFFF59E0B),
              width:         1.5,
              dashArray: const [6, 4],
              markerSettings: const MarkerSettings(isVisible: false),
              animationDuration: 300,
            ),
        ],
      ),
    );
  }
}
