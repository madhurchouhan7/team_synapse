import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared top-bar used across all 5 onboarding pages.
///
/// Shows an animated dot-step indicator on the left and an optional
/// [trailing] widget (e.g., "Skip" button) on the right.
class OnboardingTopBar extends StatelessWidget {
  /// 1-based index of the current page (1 … [totalSteps]).
  final int currentStep;

  /// Total number of steps (defaults to 5).
  final int totalSteps;

  /// Widget shown on the right side (usually a TextButton "Skip").
  final Widget? trailing;

  /// Called when the user taps the back-arrow. If null, no back arrow is shown.
  final VoidCallback? onBack;

  const OnboardingTopBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Optional back arrow ──────────────────────────────────
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // ── Dot step indicator ───────────────────────────────────
        _StepDots(current: currentStep, total: totalSteps),

        const Spacer(),

        // ── Trailing widget (Skip button etc.) ───────────────────
        ?trailing,
      ],
    );
  }
}

// ── Internal animated dot row ─────────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int current;
  final int total;

  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i + 1 == current;
        final isDone = i + 1 < current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? primary.withOpacity(0.35)
                : isActive
                ? primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

/// A pre-built "Skip Setup" text button with standard styling.
class OnboardingSkipButton extends StatelessWidget {
  final VoidCallback onSkip;
  final String label;

  const OnboardingSkipButton({
    super.key,
    required this.onSkip,
    this.label = 'Skip',
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
