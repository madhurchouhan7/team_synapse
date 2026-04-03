import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/on_boarding/widget/onboarding_top_bar.dart';
import 'package:watt_sense/feature/welcome/widgets/feature_card.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class OnBoardingPage1 extends StatelessWidget {
  final PageController pageController;

  const OnBoardingPage1({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width * 0.05;

    return Column(
      children: [
        // ── Top bar ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: width * 0.03,
          ),
          child: OnboardingTopBar(
            currentStep: 1,
            trailing: OnboardingSkipButton(
              onSkip: () {
                // Skip directly to the home flow by jumping to page 5.
                pageController.animateToPage(
                  4,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),

        // ── Scrollable content ────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: width * 0.28),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: width * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Headline
                      Text(
                        'Step 1 of 5',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize * 0.65,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: width * 0.05),

                      Image.asset(
                        'assets/svg/onboarding_1.png',
                        width: width * 0.75,
                      ),

                      SizedBox(height: width * 0.06),

                      Text(
                        "Let's Set Up Your Profile",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: fontSize * 1.3,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),

                      SizedBox(height: width * 0.02),

                      Text(
                        'Answer a few quick questions so WattWise can give you\npersonalised energy-saving insights.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: fontSize * 0.72,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: width * 0.07),

                      // Feature cards
                      FeatureCard(
                        title: 'Your Location',
                        description: 'Accurate electricity rates for your area',
                        svgIcon: SvgAssets.location_icon,
                      ),
                      FeatureCard(
                        title: 'Household Size',
                        description: 'Estimate your typical usage',
                        svgIcon: SvgAssets.group_icon,
                      ),
                      FeatureCard(
                        title: 'Your Appliances',
                        description: 'Identify saving opportunities',
                        svgIcon: SvgAssets.shop_icon,
                      ),
                      FeatureCard(
                        title: 'Usage Patterns',
                        description: 'Personalised saving plans',
                        svgIcon: SvgAssets.insights_icon,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sticky CTA ─────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: CtaButton(
                    text: "Let's Go  →",
                    onPressed: () => pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
