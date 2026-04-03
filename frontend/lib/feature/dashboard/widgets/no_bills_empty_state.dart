import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/widgets/primary_button.dart';

/// Shown on the Home dashboard when the user has not yet added any electricity bills.
///
/// Displays a friendly illustration, a headline, a description, an
/// "Add Your First Bill" CTA, and a reassuring "Takes less than 2 minutes" hint.
class NoBillsEmptyState extends StatelessWidget {
  /// Called when the user taps the primary CTA button.
  final VoidCallback onAddBill;

  const NoBillsEmptyState({super.key, required this.onAddBill});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Illustration ─────────────────────────────────────────
        _InsightsIllustration(size: width * 0.46),

        SizedBox(height: width * 0.08),

        // ── Headline ─────────────────────────────────────────────
        Text(
          'Your Future\nInsights Await',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: width * 0.075,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),

        SizedBox(height: width * 0.04),

        // ── Subtitle ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Text(
            'See your monthly trends, peak usage times, and potential savings visualized here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: width * 0.038,
              color: const Color(0xFF64748B),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        SizedBox(height: width * 0.1),

        // ── Add Bill CTA ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: PrimaryButton(
            label: 'Add Your First Bill',
            icon: Icons.add_chart_rounded,
            onPressed: onAddBill,
            height: 58,
          ),
        ),

        SizedBox(height: width * 0.04),

        // ── Time hint ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              'Takes less than 2 minutes',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Private illustration widget ───────────────────────────────────────────────

class _InsightsIllustration extends StatelessWidget {
  final double size;
  const _InsightsIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    // We recreate the stacked "document + magnifier with trend" illustration
    // using only Flutter primitives — no extra asset needed.
    return SizedBox(
      width: size,
      height: size * 0.9,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Background document ───────────────────────────
          Positioned(
            top: 0,
            child: _DocumentCard(
              width: size * 0.55,
              height: size * 0.68,
              color: const Color(0xFFDEE7FF),
              borderRadius: 18,
            ),
          ),

          // ── Foreground document (slightly larger, offset left) ──
          Positioned(
            top: size * 0.06,
            left: 0,
            child: _DocumentCard(
              width: size * 0.55,
              height: size * 0.68,
              color: const Color(0xFFEEF2FF),
              borderRadius: 18,
            ),
          ),

          // ── Search / insights badge ───────────────────────
          Positioned(
            bottom: 0,
            right: size * 0.04,
            child: _InsightsBadge(badgeSize: size * 0.38),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final double width, height, borderRadius;
  final Color color;

  const _DocumentCard({
    required this.width,
    required this.height,
    required this.color,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(opacity: 0.35),
          const SizedBox(height: 6),
          _Line(opacity: 0.25, widthFactor: 0.7),
          const SizedBox(height: 12),
          _Line(opacity: 0.2),
          const SizedBox(height: 6),
          _Line(opacity: 0.15, widthFactor: 0.55),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double opacity;
  final double widthFactor;

  const _Line({this.opacity = 0.3, this.widthFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(opacity),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _InsightsBadge extends StatelessWidget {
  final double badgeSize;
  const _InsightsBadge({required this.badgeSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.query_stats_rounded,
          color: const Color(0xFF2563EB),
          size: badgeSize * 0.46,
        ),
      ),
    );
  }
}
