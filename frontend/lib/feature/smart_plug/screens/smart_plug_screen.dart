// lib/feature/smart_plug/screens/smart_plug_screen.dart
// Full management screen for Smart Plugs — list, register, view telemetry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';
import 'package:watt_sense/feature/smart_plug/models/telemetry_reading_model.dart';
import 'package:watt_sense/feature/smart_plug/providers/smart_plug_provider.dart';
import 'package:watt_sense/feature/smart_plug/providers/telemetry_provider.dart';
import 'package:watt_sense/feature/smart_plug/widgets/plug_card.dart';
import 'package:watt_sense/feature/smart_plug/widgets/telemetry_chart.dart';

class SmartPlugScreen extends ConsumerWidget {
  const SmartPlugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: _buildAppBar(context, ref),
        body: _SmartPlugBody(),
        floatingActionButton: _AddPlugFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: Color(0xFF0F172A), size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Smart Plugs',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: Color(0xFF1E60F2)),
          onPressed: () {
            ref.read(smartPlugListProvider.notifier).refresh();
          },
        ),
      ],
    );
  }
}

// ─── Main body ───────────────────────────────────────────────────────────────
class _SmartPlugBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugsAsync = ref.watch(smartPlugListProvider);

    return plugsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E60F2)),
      ),
      error: (e, _) => _ErrorState(
        message: 'Failed to load smart plugs',
        onRetry: () => ref.read(smartPlugListProvider.notifier).refresh(),
      ),
      data: (plugs) {
        if (plugs.isEmpty) {
          return _EmptyState();
        }
        return RefreshIndicator(
          color: const Color(0xFF1E60F2),
          onRefresh: () => ref.read(smartPlugListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _SummaryHeader(plugs: plugs),
              const SizedBox(height: 20),
              ...plugs.map(
                (plug) => PlugCard(
                  plug: plug,
                  onTap: () => _showTelemetrySheet(context, ref, plug),
                  onDelete: () => _confirmDelete(context, ref, plug),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTelemetrySheet(
      BuildContext context, WidgetRef ref, SmartPlugModel plug) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TelemetrySheet(plug: plug),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SmartPlugModel plug) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove plug?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to unregister "${plug.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: GoogleFonts.poppins(color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(smartPlugListProvider.notifier).deletePlug(plug.id);
    }
  }
}

// ─── Summary header ───────────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final List<SmartPlugModel> plugs;
  const _SummaryHeader({required this.plugs});

  @override
  Widget build(BuildContext context) {
    final online   = plugs.where((p) => p.isOnline).length;
    final anomaly  = plugs.where((p) => p.lastReading?.isAnomaly == true).length;
    final liveW    = plugs.fold<double>(
        0.0, (sum, p) => sum + (p.lastReading?.wattage ?? 0.0));

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
          Text(
            'Live Total Consumption',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${liveW.toStringAsFixed(1)} W',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                  icon: Icons.power_rounded,
                  label: '$online Online',
                  color: Colors.white),
              const SizedBox(width: 10),
              if (anomaly > 0)
                _StatPill(
                  icon: Icons.warning_amber_rounded,
                  label: '$anomaly Alert${anomaly > 1 ? 's' : ''}',
                  color: const Color(0xFFFCA5A5),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style:
                  GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Telemetry bottom sheet ──────────────────────────────────────────────────
class _TelemetrySheet extends ConsumerWidget {
  final SmartPlugModel plug;
  const _TelemetrySheet({required this.plug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryState = ref.watch(telemetryProvider(plug.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize:     0.95,
      minChildSize:     0.4,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: ListView(
              controller: controller,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Plug name + status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.electrical_services_rounded,
                          color: Color(0xFF1E60F2), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plug.name,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (plug.appliance != null)
                            Text(
                              plug.appliance!.title,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Trigger reading button (demo)
                    if (plug.isSimulated)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(smartPlugListProvider.notifier)
                              .triggerReading(plug.id);
                          ref
                              .read(telemetryProvider(plug.id).notifier)
                              .fetch();
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: Text('Trigger',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E60F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart
                Text(
                  'Wattage History',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),

                if (telemetryState.isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1E60F2)),
                    ),
                  )
                else
                  TelemetryChart(
                    readings: telemetryState.readings,
                    baselineWattage: plug.baselineWattage > 0
                        ? plug.baselineWattage
                        : plug.appliance?.wattage,
                  ),

                const SizedBox(height: 20),

                // Anomaly log
                if (telemetryState.anomalyCount > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${telemetryState.anomalyCount} anomalies detected',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...telemetryState.anomalies
                      .take(5)
                      .map((r) => _AnomalyRow(reading: r)),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnomalyRow extends StatelessWidget {
  final TelemetryReading reading;
  const _AnomalyRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading.wattage.toStringAsFixed(1)} W',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                if (reading.anomalyReason != null)
                  Text(
                    reading.anomalyReason!,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF7F1D1D)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(reading.timestamp),
            style: GoogleFonts.poppins(
                fontSize: 10, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────
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
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
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
              'Connect a smart plug to start tracking real-time power usage and get anomaly alerts.',
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

// ─── Error state ──────────────────────────────────────────────────────────────
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
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 40),
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

// ─── Add plug FAB ─────────────────────────────────────────────────────────────
class _AddPlugFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showRegisterSheet(context, ref),
      backgroundColor: const Color(0xFF1E60F2),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'Add Plug',
        style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showRegisterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterPlugSheet(ref: ref),
    );
  }
}

// ─── Register plug sheet ─────────────────────────────────────────────────────
class _RegisterPlugSheet extends StatefulWidget {
  final WidgetRef ref;
  const _RegisterPlugSheet({required this.ref});

  @override
  State<_RegisterPlugSheet> createState() => _RegisterPlugSheetState();
}

class _RegisterPlugSheetState extends State<_RegisterPlugSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    final result = await widget.ref.read(smartPlugListProvider.notifier).registerPlug(
          name: name,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          isSimulated: true,
          vendor: 'simulator',
        );
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Smart plug "${result.name}" registered!',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Register Smart Plug',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a simulated or real smart plug to track energy usage.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Name field
            _buildField(
              controller: _nameController,
              label: 'Plug name',
              hint: 'e.g. Air Conditioner',
              icon: Icons.electrical_services_rounded,
            ),
            const SizedBox(height: 14),

            // Location field
            _buildField(
              controller: _locationController,
              label: 'Location (optional)',
              hint: 'e.g. Living Room',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E60F2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
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
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText:    hint,
            hintStyle:   GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
            prefixIcon:  Icon(icon, color: const Color(0xFF6B7280), size: 20),
            filled:      true,
            fillColor:   const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide:
                  const BorderSide(color: Color(0xFF1E60F2), width: 1.5),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ],
    );
  }
}
