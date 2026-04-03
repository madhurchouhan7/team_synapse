import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/plans/provider/ai_plan_provider.dart';
import 'package:watt_sense/feature/plans/screens/plan_ready_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CraftingPlanScreen extends ConsumerStatefulWidget {
  const CraftingPlanScreen({super.key});

  @override
  ConsumerState<CraftingPlanScreen> createState() => _CraftingPlanScreenState();
}

class _CraftingPlanScreenState extends ConsumerState<CraftingPlanScreen> {
  int _currentStep = 0;
  late Timer _animationTimer;

  final List<Map<String, dynamic>> _steps = [
    {
      "title": "Analysis complete",
      "subtitle": "Analyzing your historical usage...",
      "icon": Icons.lightbulb_outline,
      "color": Colors.green,
    },
    {
      "title": "Processing...",
      "subtitle": "Checking local weather forecast for the next 30 days...",
      "icon": Icons.data_usage, // or sync
      "color": AppColors.primaryBlue,
    },
    {
      "title": "Pending",
      "subtitle": "Optimizing appliance schedules...",
      "icon": Icons.circle_outlined,
      "color": Colors.grey.shade400,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationAndApiCall();
    });
  }

  Future<void> _startAnimationAndApiCall() async {
    // Start timing visual steps
    _animationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });

    // Fire API Call
    await ref.read(aiPlanProvider.notifier).generatePlan();

    // Ensure at least minimum animation time (e.g. 5 seconds) has elapsed
    // Usually the API takes ~3-4 seconds anyway.
    if (_currentStep < 2) {
      await Future.delayed(Duration(seconds: (2 - _currentStep) * 2));
    }

    // After everything, navigate to the Ready screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PlanReadyScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Step 2 ',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'of 3',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.66,
                  backgroundColor: Color(0xFFEFF1F5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                  minHeight: 4,
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // Main Animation Illustration
                    Center(
                      child:
                          Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.05,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryBlue,
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                duration: 1000.ms,
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.05, 1.05),
                              ),
                    ),

                    const SizedBox(height: 48),

                    // Headings
                    Column(
                      children: [
                        Text(
                          'Crafting Your\nSmart Strategy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            "Our AI is analyzing your data points to create the most efficient plan for your home.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Status List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: List.generate(3, (index) {
                          final stepInfo = _steps[index];

                          // Logic to decide styling based on current step
                          bool isCompleted = index < _currentStep;
                          bool isActive = index == _currentStep;

                          Color statusColor;
                          IconData iconData;

                          if (isCompleted) {
                            statusColor = Colors.green;
                            iconData = Icons.check_circle_outline;
                          } else if (isActive) {
                            statusColor = stepInfo["color"];
                            iconData = stepInfo["icon"];
                          } else {
                            statusColor = Colors.grey.shade400;
                            iconData = Icons.circle_outlined;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? statusColor.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? statusColor.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                                width: isActive ? 1.5 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: statusColor.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isActive)
                                  RotationTransition(
                                    turns: const AlwaysStoppedAnimation(
                                      0,
                                    ), // Would use AnimationController for real rotation
                                    child:
                                        Icon(
                                              iconData,
                                              color: statusColor,
                                              size: 22,
                                            )
                                            .animate(
                                              onPlay: (controller) =>
                                                  controller.repeat(),
                                            )
                                            .rotate(duration: 2000.ms),
                                  )
                                else
                                  Icon(iconData, color: statusColor, size: 22),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stepInfo["title"],
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: (isActive || isCompleted)
                                              ? AppColors.textPrimary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        stepInfo["subtitle"],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: (isActive || isCompleted)
                                              ? AppColors.textSecondary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
