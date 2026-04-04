// lib/feature/smart_plug/widgets/anomaly_alert_banner.dart
// Dismissible alert banner shown at the top of the dashboard
// when one or more smart plugs are consuming power abnormally.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';
import 'package:watt_sense/feature/smart_plug/providers/smart_plug_provider.dart';

class AnomalyAlertBanner extends ConsumerStatefulWidget {
  /// Called when the user taps "View Details"
  final VoidCallback? onViewDetails;

  const AnomalyAlertBanner({super.key, this.onViewDetails});

  @override
  ConsumerState<AnomalyAlertBanner> createState() => _AnomalyAlertBannerState();
}

class _AnomalyAlertBannerState extends ConsumerState<AnomalyAlertBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final summaryAsync = ref.watch(smartPlugSummaryProvider);

    return summaryAsync.maybeWhen(
      data: (summary) {
        if (!summary.hasAnomalies) return const SizedBox.shrink();

        // Find anomalous plugs
        final anomalousPlugs = summary.plugs
            .where((p) => p.lastReading?.isAnomaly == true)
            .toList();

        return FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onViewDetails,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pulse icon
                      _PulseIcon(),
                      const SizedBox(width: 12),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Abnormal Usage Detected!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _buildMessage(anomalousPlugs),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            if (widget.onViewDetails != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tap to view details →',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Dismiss button
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  String _buildMessage(List<SmartPlugModel> anomalousPlugs) {
    if (anomalousPlugs.isEmpty) return 'Check your smart plugs.';
    if (anomalousPlugs.length == 1) {
      final p = anomalousPlugs.first;
      final w = p.lastReading?.wattage?.toStringAsFixed(0) ?? '--';
      return '${p.name} is drawing ${w}W — higher than normal.';
    }
    return '${anomalousPlugs.length} appliances are consuming power abnormally.';
  }
}

// Pulsing red circle to draw attention
class _PulseIcon extends StatefulWidget {
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
