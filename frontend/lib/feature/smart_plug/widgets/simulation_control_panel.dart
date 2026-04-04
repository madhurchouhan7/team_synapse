// lib/feature/smart_plug/widgets/simulation_control_panel.dart
// Bottom sheet control panel for switching simulation scenarios and
// triggering manual readings/spikes on individual plugs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/smart_plug/providers/smart_plug_provider.dart';

// ── Scenario metadata ─────────────────────────────────────────────────────────
const _scenarios = [
  {
    'id':          'normal',
    'label':       'Normal Day',
    'description': 'Typical usage patterns',
    'icon':        Icons.home_outlined,
    'color':       Color(0xFF10B981),
  },
  {
    'id':          'peak_hour',
    'label':       'Peak Hour',
    'description': 'High loads — AC + cooking + entertainment',
    'icon':        Icons.bolt_outlined,
    'color':       Color(0xFFF59E0B),
  },
  {
    'id':          'night',
    'label':       'Night Mode',
    'description': 'Minimal usage, AC & kitchen suspended',
    'icon':        Icons.nights_stay_outlined,
    'color':       Color(0xFF6366F1),
  },
  {
    'id':          'fault',
    'label':       'Device Fault',
    'description': 'Forces abnormal spikes — triggers alerts',
    'icon':        Icons.warning_amber_rounded,
    'color':       Color(0xFFEF4444),
  },
  {
    'id':          'vacation',
    'label':       'Vacation / Away',
    'description': 'Only fridge + minimal lighting',
    'icon':        Icons.flight_outlined,
    'color':       Color(0xFF64748B),
  },
];

// Provider for current scenario
final _scenarioProvider = StateProvider<String>((ref) => 'normal');

class SimulationControlPanel extends ConsumerStatefulWidget {
  const SimulationControlPanel({super.key});

  @override
  ConsumerState<SimulationControlPanel> createState() =>
      _SimulationControlPanelState();
}

class _SimulationControlPanelState
    extends ConsumerState<SimulationControlPanel> {
  bool _setting = false;
  String? _error;

  Future<void> _setScenario(String id) async {
    setState(() { _setting = true; _error = null; });
    try {
      await ApiClient.instance.post(
        '/simulation/scenario',
        data: {'scenario': id},
      );
      ref.read(_scenarioProvider.notifier).state = id;
      // Refresh plug list so cards reflect updated state
      ref.read(smartPlugListProvider.notifier).refresh();
    } catch (e) {
      setState(() => _error = 'Failed to switch scenario');
    } finally {
      setState(() => _setting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(_scenarioProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize:     0.9,
      minChildSize:     0.4,
      expand:           false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science_outlined,
                        color: Color(0xFF1E60F2), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Simulation Scenarios',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how the smart plug simulator behaves. Changes apply to all plugs in real-time.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF64748B)),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFDC2626), fontSize: 12)),
                ),
              ],

              const SizedBox(height: 20),

              // Scenario cards
              ..._scenarios.map((s) {
                final isActive = current == s['id'];
                final color    = s['color'] as Color;
                return GestureDetector(
                  onTap: _setting ? null : () => _setScenario(s['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? color : const Color(0xFFE2E8F0),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isActive ? color : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            s['icon'] as IconData,
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['label'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? color : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                s['description'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.check_circle_rounded, color: color, size: 20),
                        if (_setting && isActive)
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Current status info
              _StatusInfoRow(
                label:       'Active scenario',
                value:       current.replaceAll('_', ' ').toUpperCase(),
                valueColor:  const Color(0xFF1E60F2),
              ),
              const SizedBox(height: 6),
              _StatusInfoRow(
                label:       'Readings every',
                value:       '5 seconds',
                valueColor:  const Color(0xFF10B981),
              ),
              const SizedBox(height: 6),
              _StatusInfoRow(
                label:       'Anomaly threshold',
                value:       'Z-score > 2.5σ',
                valueColor:  const Color(0xFFEF4444),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatusInfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF64748B))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ),
      ],
    );
  }
}
