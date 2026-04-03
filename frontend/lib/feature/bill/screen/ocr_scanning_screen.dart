import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/ocr_provider.dart';

/// Full-screen animated scanning experience shown while OCR processes.
/// Automatically pops itself and returns to [AddBillScreen] when done.
class OcrScanningScreen extends ConsumerStatefulWidget {
  const OcrScanningScreen({super.key});

  @override
  ConsumerState<OcrScanningScreen> createState() => _OcrScanningScreenState();
}

class _OcrScanningScreenState extends ConsumerState<OcrScanningScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _dotsController;

  // Which step label to show
  int _stepIndex = 0;
  final List<String> _steps = [
    'Detecting document edges...',
    'Enhancing image quality...',
    'Recognising text...',
    'Extracting bill details...',
  ];

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    // Cycle through step labels every 1.1 seconds for a lively feel
    _cycleSteps();
  }

  void _cycleSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted) setState(() => _stepIndex = i);
    }
    // Keep last step visible until OCR finishes
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to OCR state changes — pop when done or error occurs
    ref.listen(ocrProvider, (previous, next) {
      if (next.isLoading) return; // still scanning
      if (!mounted) return;
      // Either got data or an error — go back to AddBillScreen either way
      Navigator.of(context).pop();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Scanning Bill',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // balance close button
                ],
              ),
            ),

            const Spacer(),

            // ── Central animated document scanner ────────────────────────
            Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulsing glow ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 240 + (_pulseController.value * 24),
                          height: 300 + (_pulseController.value * 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1E60F2).withOpacity(
                                0.15 + _pulseController.value * 0.2,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Document card
                      Container(
                        width: 220,
                        height: 280,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1E60F2).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E60F2).withOpacity(0.2),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              // Mock bill lines
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),

                                    // Title line
                                    Container(
                                      height: 10,
                                      width: 140,
                                      decoration: _lineDeco(0.9),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 7,
                                      width: 100,
                                      decoration: _lineDeco(0.5),
                                    ),
                                    const SizedBox(height: 24),

                                    // Amount
                                    Container(
                                      height: 18,
                                      width: 80,
                                      decoration: _lineDeco(0.8, hilite: true),
                                    ),
                                    const SizedBox(height: 20),

                                    // Info rows
                                    ...List.generate(
                                      5,
                                      (i) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 7,
                                              width: 60 + (i % 3) * 15.0,
                                              decoration: _lineDeco(0.4),
                                            ),
                                            const Spacer(),
                                            Container(
                                              height: 7,
                                              width: 40.0 + (i % 2) * 20,
                                              decoration: _lineDeco(0.25),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Footer
                                    Container(
                                      height: 6,
                                      decoration: _lineDeco(0.15),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 6,
                                      width: 120,
                                      decoration: _lineDeco(0.1),
                                    ),
                                  ],
                                ),
                              ),

                              // Animated neon scan line
                              AnimatedBuilder(
                                animation: _scanLineController,
                                builder: (_, __) {
                                  final y = _scanLineController.value * 260;
                                  return Positioned(
                                    top: y,
                                    left: 0,
                                    right: 0,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                const Color(
                                                  0xFF00CFFF,
                                                ).withOpacity(0.9),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                const Color(
                                                  0xFF00CFFF,
                                                ).withOpacity(0.12),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Four corner bracket indicators
                      ..._buildCornerBrackets(),
                    ],
                  ),
                )
                .animate()
                .fade(duration: 400.ms)
                .scale(begin: const Offset(0.92, 0.92)),

            const SizedBox(height: 48),

            // ── Rotating "processing" ring ────────────────────────────────
            AnimatedBuilder(
              animation: _rotateController,
              builder: (_, child) => Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: child,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(painter: _SpinnerPainter()),
              ),
            ),

            const SizedBox(height: 28),

            // ── Step text ─────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_stepIndex],
                key: ValueKey(_stepIndex),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Using AI to extract bill information',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 40),

            // ── Progress indicators (3 shimmering dots) ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    final delay = i * 0.33;
                    final value = (((_pulseController.value) + delay) % 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFF1E60F2).withOpacity(0.3),
                          const Color(0xFF00CFFF),
                          value,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  BoxDecoration _lineDeco(double opacity, {bool hilite = false}) =>
      BoxDecoration(
        color: hilite
            ? const Color(0xFF1E60F2).withOpacity(opacity)
            : Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(4),
      );

  List<Widget> _buildCornerBrackets() {
    const size = 220.0;
    const height = 280.0;
    const bracketLen = 20.0;
    const bracketThk = 2.5;
    final color = const Color(0xFF00CFFF);

    Widget bracket({
      required AlignmentGeometry alignment,
      required double top,
      required double left,
      required bool flipX,
      required bool flipY,
    }) => Positioned(
      top: top,
      left: left,
      child: Transform.scale(
        scaleX: flipX ? -1 : 1,
        scaleY: flipY ? -1 : 1,
        child: SizedBox(
          width: bracketLen,
          height: bracketLen,
          child: CustomPaint(
            painter: _CornerPainter(color: color, thickness: bracketThk),
          ),
        ),
      ),
    );

    return [
      bracket(
        alignment: Alignment.topLeft,
        top: -height / 2,
        left: -size / 2,
        flipX: false,
        flipY: false,
      ),
      bracket(
        alignment: Alignment.topRight,
        top: -height / 2,
        left: size / 2 - bracketLen,
        flipX: true,
        flipY: false,
      ),
      bracket(
        alignment: Alignment.bottomLeft,
        top: height / 2 - bracketLen,
        left: -size / 2,
        flipX: false,
        flipY: true,
      ),
      bracket(
        alignment: Alignment.bottomRight,
        top: height / 2 - bracketLen,
        left: size / 2 - bracketLen,
        flipX: true,
        flipY: true,
      ),
    ];
  }
}

// ── Custom corner bracket painter ────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;

  const _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Arc spinner painter ───────────────────────────────────────────────────────
class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.transparent, Color(0xFF00CFFF)],
        stops: [0.6, 1.0],
      ).createShader(rect)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 1.5, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
