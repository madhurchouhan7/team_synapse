// lib/feature/smart_plug/widgets/anomaly_alert_banner.dart
// Real-time dismissible anomaly alert banner.
// Listens to BOTH the REST summary provider AND WebSocket live anomaly events.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/smart_plug/providers/ws_telemetry_provider.dart';

class AnomalyAlertBanner extends ConsumerStatefulWidget {
  final VoidCallback? onViewDetails;
  const AnomalyAlertBanner({super.key, this.onViewDetails});

  @override
  ConsumerState<AnomalyAlertBanner> createState() =>
      _AnomalyAlertBannerState();
}

class _AnomalyAlertBannerState extends ConsumerState<AnomalyAlertBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed           = false;
  String? _lastAnomalyType; // track last WS anomaly so we re-show on new ones
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..value = 1.0;
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    setState(() => _dismissed = true);
    ref.read(wsTelemetryProvider.notifier).clearAnomaly();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(wsTelemetryProvider);

    // Determine if we have live or REST-based anomaly
    final hasLiveAnomaly = wsState.hasAnomalies;
    final anomalousPlugs = wsState.anomalousPlugs;

    // Re-show banner when a new WS anomaly event arrives
    final anomalyEvent = wsState.latestAnomaly;
    final anomalyKey   = anomalyEvent != null
        ? '${anomalyEvent.data['plugId']}_${anomalyEvent.data['timestamp']}'
        : null;

    // Compare set of live anomalous plugs to detect new culprits
    final currentAnomalousIds = anomalousPlugs.map((p) => p.plugId).join(',');
    final hasNewLiveAnomaly = currentAnomalousIds.isNotEmpty && 
                             !currentAnomalousIds.split(',').every((id) => _lastAnomalyType?.contains(id) ?? false);

    if ((anomalyKey != null && anomalyKey != _lastAnomalyType) || hasNewLiveAnomaly) {
      _lastAnomalyType = anomalyKey ?? currentAnomalousIds;
      _dismissed       = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.forward();
      });
    }

    // Only show if there is an ACTUAL anomaly AND not dismissed
    if (_dismissed || (!hasLiveAnomaly && anomalyEvent == null)) {
      return const SizedBox.shrink();
    }

    // Build message
    String title   = '⚡ Abnormal Usage Detected!';
    String message = 'Check your smart plugs.';

    if (anomalyEvent != null) {
      final d      = anomalyEvent.data;
      final name   = d['applianceName'] ?? d['plugName'] ?? 'Device';
      final watts  = d['wattage'] != null
          ? '${(d['wattage'] as num).toStringAsFixed(0)}W'
          : '';
      title   = '⚡ Abnormal: $name';
      message = '$name is drawing $watts — ${d['anomalyReason'] ?? 'higher than normal.'}';
    } else if (anomalousPlugs.isNotEmpty) {
      final p = anomalousPlugs.first;
      title   = '⚡ Abnormal: ${p.plugName}';
      message = '${p.plugName} is drawing ${p.wattage.toStringAsFixed(0)}W — higher than normal.';
    }

    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin:      const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:  const Color(0xFFEF4444).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              widget.onViewDetails?.call();
              ref.read(wsTelemetryProvider.notifier).clearAnomaly();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PulseIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 2),
                        Text(message,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (widget.onViewDetails != null) ...[
                          const SizedBox(height: 4),
                          Text('Tap for details →',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              )),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.warning_amber_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}
