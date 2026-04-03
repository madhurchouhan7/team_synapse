import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/widgets/primary_button.dart';

/// A single step in the "unlock insights" funnel.
class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isDone;

  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isActive = false,
    this.isDone = false,
  });
}

/// Full-screen empty state shown on the Insights tab when the user
/// has not yet added any electricity bill.
///
/// Design:
/// - Gradient hero card with an AI-robot icon
/// - Bold headline + subtitle
/// - Vertical step list (Log Bill → Generate Plan → View Insights)
///   with connector lines and a "Next Step" badge on the active item
/// - Full-width "Start by Adding Bill" CTA pinned to the bottom
class NoInsightsEmptyState extends StatelessWidget {
  final VoidCallback onAddBill;

  const NoInsightsEmptyState({super.key, required this.onAddBill});

  static const _steps = [
    _Step(
      icon: Icons.receipt_long_rounded,
      title: 'Log your Bill',
      subtitle: 'Upload your latest utility statement to establish a baseline.',
      isActive: true,
      isDone: false,
    ),
    _Step(
      icon: Icons.tips_and_updates_rounded,
      title: 'Generate Plan',
      subtitle: 'AI analyzes your consumption patterns.',
    ),
    _Step(
      icon: Icons.show_chart_rounded,
      title: 'View Detailed Insights',
      subtitle: 'Access personalized charts and cost-saving tips.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Scrollable body ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.058,
              vertical: width * 0.03,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero gradient card
                _HeroCard(size: width),

                SizedBox(height: height * 0.035),

                // Headline
                Text(
                  'Unlock Energy\nIntelligence',
                  style: GoogleFonts.poppins(
                    fontSize: width * 0.072,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),

                SizedBox(height: width * 0.028),

                // Subtitle
                Text(
                  'Complete these steps to access detailed breakdowns and AI-powered savings recommendations.',
                  style: GoogleFonts.poppins(
                    fontSize: width * 0.037,
                    color: const Color(0xFF64748B),
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: height * 0.038),

                // Step list
                _StepList(steps: _steps, width: width),

                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),

        // ── Sticky CTA ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            width * 0.058,
            12,
            width * 0.058,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: PrimaryButton(
            label: 'Start by Adding Bill',
            icon: Icons.add_circle_outline_rounded,
            onPressed: onAddBill,
            height: 56,
          ),
        ),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double size;
  const _HeroCard({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: size * 0.46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD6E4FF), Color(0xFFEEF4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(child: _RobotIcon(size: size * 0.22)),
    );
  }
}

class _RobotIcon extends StatelessWidget {
  final double size;
  const _RobotIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        size: size * 0.58,
        color: const Color(0xFF2563EB),
      ),
    );
  }
}

// ─── Step list ────────────────────────────────────────────────────────────────

class _StepList extends StatelessWidget {
  final List<_Step> steps;
  final double width;

  const _StepList({required this.steps, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        return _StepRow(
          step: steps[i],
          isLast: i == steps.length - 1,
          width: width,
        );
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isLast;
  final double width;

  const _StepRow({
    required this.step,
    required this.isLast,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final active = step.isActive;
    final locked = !active && !step.isDone;

    final iconBg = active ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9);
    final iconColor = active
        ? const Color(0xFF2563EB)
        : const Color(0xFFCBD5E1);
    final titleColor = active
        ? const Color(0xFF0F172A)
        : const Color(0xFFCBD5E1);
    final subColor = active ? const Color(0xFF64748B) : const Color(0xFFCBD5E1);

    const lineColor = Color(0xFFE2E8F0);
    final iconSize = width * 0.1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: icon + vertical connector ──────────────────
          SizedBox(
            width: iconSize + 8,
            child: Column(
              children: [
                // Circle icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    step.icon,
                    color: iconColor,
                    size: iconSize * 0.46,
                  ),
                ),

                // Vertical connector (not on last)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── Right: text + badge ───────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : width * 0.05,
                top: iconSize * 0.08,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.poppins(
                            fontSize: width * 0.041,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: width * 0.033,
                            color: subColor,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // "Next Step" badge / lock icon
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Next Step',
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    )
                  else if (locked)
                    Icon(
                      Icons.lock_outline_rounded,
                      size: width * 0.045,
                      color: const Color(0xFFCBD5E1),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
