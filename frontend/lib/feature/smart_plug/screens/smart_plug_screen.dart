// lib/feature/smart_plug/screens/smart_plug_screen.dart
// Full management screen for Smart Plugs — list, register, view telemetry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';
import 'package:watt_sense/feature/smart_plug/models/telemetry_reading_model.dart';
import 'package:watt_sense/feature/smart_plug/providers/smart_plug_provider.dart';
import 'package:watt_sense/feature/smart_plug/providers/ws_telemetry_provider.dart';
import 'package:watt_sense/feature/smart_plug/widgets/simulation_control_panel.dart';

class SmartPlugScreen extends ConsumerStatefulWidget {
  const SmartPlugScreen({super.key});

  @override
  ConsumerState<SmartPlugScreen> createState() => _SmartPlugScreenState();
}

class _SmartPlugScreenState extends ConsumerState<SmartPlugScreen> {
  // Track chart tab selection per plug
  final Map<String, bool> _showAnomalyOnly = {};

  @override
  void initState() {
    super.initState();
    _connectWs();
  }

  void _connectWs() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(wsTelemetryProvider.notifier).connect(user.uid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: _buildAppBar(context),
        body: _buildBody(),
        floatingActionButton: _buildFABs(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final wsState = ref.watch(wsTelemetryProvider);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Color(0xFF0F172A),
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Plugs',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: wsState.isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                wsState.isConnected ? 'Live' : 'Reconnecting…',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: wsState.isConnected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Scenario switcher
        IconButton(
          icon: const Icon(Icons.science_outlined, color: Color(0xFF1E60F2)),
          onPressed: () => _showScenarioPanel(context),
          tooltip: 'Switch Scenario',
        ),
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          onPressed: () => ref.read(smartPlugListProvider.notifier).refresh(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final plugsAsync = ref.watch(smartPlugListProvider);
    final wsState = ref.watch(wsTelemetryProvider);

    return plugsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E60F2)),
      ),
      error: (e, _) => _ErrorState(
        message: 'Failed to load smart plugs',
        onRetry: () => ref.read(smartPlugListProvider.notifier).refresh(),
      ),
      data: (plugs) {
        if (plugs.isEmpty) return _EmptyState();
        return RefreshIndicator(
          color: const Color(0xFF1E60F2),
          onRefresh: () => ref.read(smartPlugListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // Live summary header
              _LiveSummaryCard(wsState: wsState, plugs: plugs),
              const SizedBox(height: 20),

              // Per-plug live cards
              ...plugs.map((plug) {
                final live = wsState.liveData[plug.plugId];
                return _LivePlugCard(
                  plug: plug,
                  live: live,
                  showAnomaly: _showAnomalyOnly[plug.plugId] ?? false,
                  onToggleAnomaly: () {
                    setState(() {
                      _showAnomalyOnly[plug.plugId] =
                          !(_showAnomalyOnly[plug.plugId] ?? false);
                    });
                  },
                  onDelete: () => _confirmDelete(context, plug),
                  onTriggerSpike: () => _triggerSpike(context, plug),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFABs(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'add_plug',
          onPressed: () => _showRegisterSheet(context),
          backgroundColor: const Color(0xFF1E60F2),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Add Plug',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showScenarioPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SimulationControlPanel(),
    );
  }

  Future<void> _triggerSpike(BuildContext context, SmartPlugModel plug) async {
    try {
      final isAnomaly = await ref
          .read(smartPlugListProvider.notifier)
          .triggerReading(plug.id, forceSpike: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAnomaly
                  ? 'Spike triggered on ${plug.name}. Anomaly detected!'
                  : 'Spike sent, but anomaly not flagged yet. Keep normal readings for ~20-30s then try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: isAnomaly
                ? const Color(0xFFEF4444)
                : const Color(0xFF64748B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _confirmDelete(BuildContext context, SmartPlugModel plug) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Remove plug?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Unregister "${plug.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(smartPlugListProvider.notifier).deletePlug(plug.id);
    }
  }

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterPlugSheet(ref: ref),
    );
  }
}

// ── Live summary card ─────────────────────────────────────────────────────────
class _LiveSummaryCard extends StatelessWidget {
  final WsTelemetryState wsState;
  final List<SmartPlugModel> plugs;
  const _LiveSummaryCard({required this.wsState, required this.plugs});

  @override
  Widget build(BuildContext context) {
    final isStreaming = wsState.liveData.isNotEmpty;
    // When WS is live → use summed live wattage.
    // Before first tick → fall back to sum of DB lastReading snapshots.
    final totalW = isStreaming
        ? wsState.totalLiveWattage
        : plugs.fold<double>(
            0.0,
            (s, p) => s + (p.lastReading?.wattage ?? 0.0),
          );
    final anomalies = wsState.anomalousPlugs.length;

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
            children: [
              Text(
                isStreaming ? 'Live Total' : 'Last Reading',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isStreaming) ...[
                _PulseDot(),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${totalW.toStringAsFixed(1)} W',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.electrical_services_rounded,
                label: '${plugs.length} plug${plugs.length > 1 ? 's' : ''}',
                color: Colors.white,
              ),
              if (anomalies > 0) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.warning_amber_rounded,
                  label: '$anomalies alert${anomalies > 1 ? 's' : ''}',
                  color: const Color(0xFFFCA5A5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Per-plug live card ────────────────────────────────────────────────────────
class _LivePlugCard extends StatelessWidget {
  final SmartPlugModel plug;
  final LivePlugData? live;
  final bool showAnomaly;
  final VoidCallback onToggleAnomaly;
  final VoidCallback onDelete;
  final VoidCallback onTriggerSpike;

  const _LivePlugCard({
    required this.plug,
    this.live,
    required this.showAnomaly,
    required this.onToggleAnomaly,
    required this.onDelete,
    required this.onTriggerSpike,
  });

  @override
  Widget build(BuildContext context) {
    // Fall back to DB snapshot while WS hasn't sent a reading yet
    final wattage = live?.wattage ?? plug.lastReading?.wattage ?? 0.0;
    final isAnomaly = live?.isAnomaly ?? plug.lastReading?.isAnomaly ?? false;
    final devState = live?.deviceState;
    final history = live?.history ?? [];
    final isLive = live != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnomaly ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
          width: isAnomaly ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isAnomaly
                ? const Color(0xFFEF4444).withOpacity(0.1)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAnomaly
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAnomaly
                        ? Icons.warning_amber_rounded
                        : Icons.electrical_services_rounded,
                    color: isAnomaly
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E60F2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plug.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (plug.appliance != null || devState != null)
                        Text(
                          devState != null
                              ? '${plug.appliance?.title ?? plug.name} · ${devState.replaceAll('_', ' ')}'
                              : plug.appliance?.title ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons
                _ActionMenu(onDelete: onDelete, onTriggerSpike: onTriggerSpike),
              ],
            ),

            const SizedBox(height: 14),

            // ── Wattage + voltage row ─────────────────────────────────────
            Row(
              children: [
                _MetricBubble(
                  label: 'POWER',
                  value: '${wattage.toStringAsFixed(1)} W',
                  color: isAnomaly
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF1E60F2),
                ),
                const SizedBox(width: 10),
                _MetricBubble(
                  label: 'VOLTAGE',
                  value: live != null
                      ? '${live!.voltage.toStringAsFixed(0)} V'
                      : '-- V',
                  color: const Color(0xFF10B981),
                ),
                if (devState != null) ...[
                  const SizedBox(width: 10),
                  _StateBadge(state: devState),
                ],
              ],
            ),

            // ── Status / real-time mini chart ────────────────────────────
            if (isLive && history.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MiniChart(readings: history, isAnomaly: isAnomaly),
            ] else if (!isLive) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: plug.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plug.isOnline
                        ? 'Connecting to live stream…'
                        : 'Last known reading',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],

            // ── Anomaly reason ────────────────────────────────────────────
            if (isAnomaly) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Abnormal power consumption detected',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Mini real-time chart ──────────────────────────────────────────────────────
class _MiniChart extends StatelessWidget {
  final List<TelemetryReading> readings;
  final bool isAnomaly;
  const _MiniChart({required this.readings, required this.isAnomaly});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.zero,
        primaryXAxis: DateTimeAxis(
          isVisible: false,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          isVisible: true,
          labelStyle: GoogleFonts.poppins(
            fontSize: 9,
            color: const Color(0xFF94A3B8),
          ),
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(
            width: 0.5,
            color: Color(0xFFF1F5F9),
          ),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value}W',
          maximumLabels: 3,
        ),
        series: <CartesianSeries>[
          AreaSeries<TelemetryReading, DateTime>(
            dataSource: readings,
            xValueMapper: (r, _) => r.timestamp,
            yValueMapper: (r, _) => r.wattage,
            color:
                (isAnomaly ? const Color(0xFFEF4444) : const Color(0xFF1E60F2))
                    .withOpacity(0.15),
            borderColor: isAnomaly
                ? const Color(0xFFEF4444)
                : const Color(0xFF1E60F2),
            borderWidth: 2,
            animationDuration: 0,
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────
class _MetricBubble extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricBubble({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String state;
  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFD0FF)),
      ),
      child: Text(
        state.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4A6FE0),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF86EFAC),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onTriggerSpike;
  const _ActionMenu({required this.onDelete, required this.onTriggerSpike});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Color(0xFF94A3B8),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'spike',
          child: Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Force Spike', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Remove', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'spike') onTriggerSpike();
        if (v == 'delete') onDelete();
      },
    );
  }
}

// ── Empty + Error states ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.electrical_services_rounded,
                color: Color(0xFF1E60F2),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Smart Plugs Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Add Plug to register a simulated appliance and watch real-time energy data appear.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins()),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

// ── Register plug bottom sheet ────────────────────────────────────────────────

// Preset appliance templates for quick registration
const _presets = [
  {
    'name': 'Air Conditioner',
    'vendor': 'simulator',
    'location': 'Living Room',
    'wattage': 1500.0,
    'category': 'cooling',
  },
  {
    'name': 'Refrigerator',
    'vendor': 'simulator',
    'location': 'Kitchen',
    'wattage': 150.0,
    'category': 'kitchen_fridge',
  },
  {
    'name': 'Washing Machine',
    'vendor': 'simulator',
    'location': 'Utility Room',
    'wattage': 500.0,
    'category': 'laundry',
  },
  {
    'name': 'Water Heater',
    'vendor': 'simulator',
    'location': 'Bathroom',
    'wattage': 2000.0,
    'category': 'heating',
  },
  {
    'name': 'TV & Set-top Box',
    'vendor': 'simulator',
    'location': 'Living Room',
    'wattage': 120.0,
    'category': 'entertainment',
  },
  {
    'name': 'LED Lighting',
    'vendor': 'simulator',
    'location': 'Hall',
    'wattage': 54.0,
    'category': 'lighting',
  },
  {
    'name': 'Microwave',
    'vendor': 'simulator',
    'location': 'Kitchen',
    'wattage': 900.0,
    'category': 'kitchen',
  },
  {
    'name': 'Laptop Charger',
    'vendor': 'simulator',
    'location': 'Study',
    'wattage': 65.0,
    'category': 'computing',
  },
];

class _RegisterPlugSheet extends StatefulWidget {
  final WidgetRef ref;
  const _RegisterPlugSheet({required this.ref});

  @override
  State<_RegisterPlugSheet> createState() => _RegisterPlugSheetState();
}

class _RegisterPlugSheetState extends State<_RegisterPlugSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Simulator tab
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int? _selectedPreset;

  // Tuya tab
  final _tuyaDeviceIdCtrl = TextEditingController();
  final _tuyaNameCtrl = TextEditingController();
  final _tuyaLocationCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _tuyaDeviceIdCtrl.dispose();
    _tuyaNameCtrl.dispose();
    _tuyaLocationCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    final p = _presets[index];
    setState(() {
      _selectedPreset = index;
      _nameCtrl.text = p['name'] as String;
      _locationCtrl.text = p['location'] as String;
    });
  }

  // ── Register simulated plug ─────────────────────────────────────────────────
  Future<void> _registerSimulated() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMsg = 'Please enter a name or pick a preset.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final wattage = _selectedPreset != null
        ? _presets[_selectedPreset!]['wattage'] as double
        : null;

    try {
      final result = await widget.ref
          .read(smartPlugListProvider.notifier)
          .registerPlug(
            name: name,
            location: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
            isSimulated: true,
            vendor: 'simulator',
            baselineWattage: wattage,
          );
      if (mounted) {
        Navigator.of(context).pop();
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"${result.name}" registered! Readings stream in ~5s.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Register real Tuya device ───────────────────────────────────────────────
  Future<void> _registerTuya() async {
    final deviceId = _tuyaDeviceIdCtrl.text.trim();
    if (deviceId.isEmpty) {
      setState(() => _errorMsg = 'Please enter the Tuya Device ID.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await widget.ref
          .read(smartPlugListProvider.notifier)
          .registerPlug(
            name: _tuyaNameCtrl.text.trim().isEmpty
                ? 'Tuya Device'
                : _tuyaNameCtrl.text.trim(),
            location: _tuyaLocationCtrl.text.trim().isEmpty
                ? null
                : _tuyaLocationCtrl.text.trim(),
            isSimulated: false,
            vendor: 'tuya',
            tuyaDeviceId: deviceId,
          );
      if (mounted) {
        Navigator.of(context).pop();
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"${result.name}" linked! Real-time data starts in 5s.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: const Color(0xFF1E60F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  tabs: const [
                    Tab(text: '🔵  Simulator'),
                    Tab(text: '🟠  Tuya Device'),
                  ],
                  onTap: (_) => setState(() => _errorMsg = null),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Tab views
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabCtrl,
                children: [_simulatorTab(), _tuyaTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Simulator tab ─────────────────────────────────────────────────────────
  Widget _simulatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a preset or enter custom details.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presets.length, (i) {
              final p = _presets[i];
              final selected = _selectedPreset == i;
              return GestureDetector(
                onTap: () => _applyPreset(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1E60F2)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),
          _buildField(
            controller: _nameCtrl,
            label: 'Name',
            hint: 'e.g. Living Room AC',
            icon: Icons.label_outline,
          ),
          const SizedBox(height: 10),
          _buildField(
            controller: _locationCtrl,
            label: 'Location (optional)',
            hint: 'e.g. Bedroom',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerSimulated,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E60F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Register Plug',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tuya tab ──────────────────────────────────────────────────────────────
  Widget _tuyaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Setup guide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔧', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Tuya Setup Guide',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...[
                  '1. Open the Tuya / Smart Life app on your phone',
                  '2. Add your smart plug in the app',
                  '3. Go to iot.tuya.com → Cloud → Your Project → Devices',
                  '4. Copy the Device ID from the device list',
                  '5. Paste it below and tap Link Device',
                ].map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      step,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _buildField(
            controller: _tuyaDeviceIdCtrl,
            label: 'Tuya Device ID *',
            hint: 'e.g. eb3b5bac7b12345678',
            icon: Icons.qr_code_2_rounded,
          ),
          const SizedBox(height: 10),
          _buildField(
            controller: _tuyaNameCtrl,
            label: 'Display Name (optional)',
            hint: 'e.g. Kitchen Plug',
            icon: Icons.label_outline,
          ),
          const SizedBox(height: 10),
          _buildField(
            controller: _tuyaLocationCtrl,
            label: 'Location (optional)',
            hint: 'e.g. Kitchen',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerTuya,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Link Tuya Device',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 18),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1E60F2),
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }
}
