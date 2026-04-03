import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.svgAsset,
    this.isLoading = false,
    this.loadingText,
  });

  final String text;
  final VoidCallback? onPressed;
  final String? svgAsset;

  /// When true, the button is visually muted and taps are disabled.
  final bool isLoading;

  /// Optional text to show while loading. Defaults to [text].
  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // When loading: desaturated/muted colour so the button stays in place
    // but signals to the user that the action is in progress.
    final bgColor = isLoading ? const Color(0xFFAFC4F0) : primaryColor;
    final labelText = (isLoading && loadingText != null) ? loadingText! : text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.065,
      decoration: BoxDecoration(
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onPressed,
        child: Center(
          child: isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.white,
                  highlightColor: Colors.white60,
                  child: Text(
                    labelText,
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width / 600 * 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labelText,
                      style: GoogleFonts.poppins(
                        fontSize: MediaQuery.of(context).size.width / 600 * 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
