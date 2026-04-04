// lib/feature/smart_plug/widgets/plug_card.dart
// Card widget showing live wattage and status for a single smart plug.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/smart_plug/models/smart_plug_model.dart';

class PlugCard extends StatelessWidget {
  final SmartPlugModel plug;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PlugCard({
    super.key,
    required this.plug,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAnomaly = plug.lastReading?.isAnomaly ?? false;
    final wattage   = plug.lastReading?.wattage;
    final isOnline  = plug.isOnline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAnomaly
                ? const Color(0xFFEF4444)
                : isOnline
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
            width: isAnomaly ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isAnomaly
                  ? const Color(0xFFEF4444).withOpacity(0.12)
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
              // ── Header row ───────────────────────────────────────────────
              Row(
                children: [
                  // Status dot + icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAnomaly
                          ? const Color(0xFFFEF2F2)
                          : isOnline
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAnomaly
                          ? Icons.warning_amber_rounded
                          : Icons.electrical_services_rounded,
                      color: isAnomaly
                          ? const Color(0xFFEF4444)
                          : isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plug.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (plug.location != null || plug.appliance != null)
                          Text(
                            plug.appliance?.title ??
                                plug.location ??
                                '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Wattage + status strip ─────────────────────────────────
              Row(
                children: [
                  // Wattage bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAnomaly
                            ? [
                                const Color(0xFFEF4444),
                                const Color(0xFFDC2626),
                              ]
                            : isOnline
                                ? [
                                    const Color(0xFF1E60F2),
                                    const Color(0xFF144CC7),
                                  ]
                                : [
                                    const Color(0xFF94A3B8),
                                    const Color(0xFF64748B),
                                  ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      wattage != null
                          ? '${wattage.toStringAsFixed(1)} W'
                          : '-- W',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Status chip
                  _StatusChip(
                    label: isAnomaly
                        ? 'ALERT'
                        : isOnline
                            ? 'ONLINE'
                            : 'OFFLINE',
                    color: isAnomaly
                        ? const Color(0xFFEF4444)
                        : isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                  ),

                  const Spacer(),

                  // Simulated badge
                  if (plug.isSimulated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFD0FF)),
                      ),
                      child: Text(
                        'SIM',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A6FE0),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Anomaly reason ──────────────────────────────────────────
              if (isAnomaly && plug.lastReading != null) ...[
                const SizedBox(height: 12),
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
                          'Abnormal consumption detected',
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
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
