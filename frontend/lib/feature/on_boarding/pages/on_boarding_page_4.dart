import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/on_boarding/provider/selected_appliance_notifier.dart';
import 'package:watt_sense/feature/on_boarding/widget/onboarding_top_bar.dart';
import 'package:watt_sense/feature/on_boarding/widget/select_appliances.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class OnBoardingPage4 extends ConsumerWidget {
  final PageController pageController;
  const OnBoardingPage4({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(
      selectedAppliancesProvider.select((list) => list.length),
    );

    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width * 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // ── Top bar ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: width * 0.03,
              ),
              child: OnboardingTopBar(
                currentStep: 4,
                onBack: () => pageController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                ),
                trailing: OnboardingSkipButton(
                  onSkip: () {
                    ref.read(selectedAppliancesProvider.notifier).clearAll();
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

            // ── Scrollable content ───────────────────────────────
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
                          Text(
                            'Step 4 of 5',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize * 0.65,
                              letterSpacing: 0.5,
                            ),
                          ),

                          SizedBox(height: width * 0.04),

                          Text(
                            'Select Your Appliances',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: fontSize * 1.3,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),

                          SizedBox(height: width * 0.015),

                          Text(
                            'Check the ones you have at home — this helps us\nidentify where you can save the most.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontSize: fontSize * 0.72,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: width * 0.06),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryLabel(
                                label: 'COOLING',
                                constraints: constraints,
                              ),
                              SelectAppliances(
                                title: 'Air Conditioner',
                                description: 'Split AC, Window AC, Inverter',
                                svgPath: SvgAssets.ac_icon,
                                category: 'COOLING',
                              ),
                              SelectAppliances(
                                title: 'Air Cooler',
                                description: 'Desert, Personal, Tower',
                                svgPath: SvgAssets.wind_icon,
                                category: 'COOLING',
                              ),

                              SizedBox(height: width * 0.03),
                              _CategoryLabel(
                                label: 'HEATING',
                                constraints: constraints,
                              ),
                              SelectAppliances(
                                title: 'Geyser',
                                description: 'Electric, Gas, Instant',
                                svgPath: SvgAssets.geyser_icon,
                                category: 'HEATING',
                              ),
                              SelectAppliances(
                                title: 'Room Heater',
                                description: 'Fan, Oil, Halogen',
                                svgPath: SvgAssets.room_heater_icon,
                                category: 'HEATING',
                              ),

                              SizedBox(height: width * 0.03),
                              _CategoryLabel(
                                label: 'ALWAYS ON',
                                constraints: constraints,
                              ),
                              SelectAppliances(
                                title: 'Refridgerator',
                                description: 'Single, Double Door',
                                svgPath: SvgAssets.fridge_icon,
                                category: 'ALWAYS ON',
                              ),
                              SelectAppliances(
                                title: 'Television',
                                description: 'LCD, LED, Smart TV',
                                svgPath: SvgAssets.tv_icon,
                                category: 'ALWAYS ON',
                              ),
                              SelectAppliances(
                                title: 'Wi-Fi Router',
                                description: 'Modem, Extender',
                                svgPath: SvgAssets.wifi_router_icon,
                                category: 'ALWAYS ON',
                              ),

                              SizedBox(height: width * 0.03),
                              _CategoryLabel(
                                label: 'OCCASIONAL USE',
                                constraints: constraints,
                              ),
                              SelectAppliances(
                                title: 'Washing Machine',
                                description: 'Front Load, Top Load',
                                svgPath: SvgAssets.washing_machine_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Microwave Oven',
                                description: 'Solo, Grill, Convection',
                                svgPath: SvgAssets.microwave_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Water Purifier',
                                description: 'RO, UV',
                                svgPath: SvgAssets.water_purifier_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Computer',
                                description: 'Desktop, Workstation',
                                svgPath: SvgAssets.computer_icon,
                                category: 'OCCASIONAL USE',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sticky CTA ────────────────────────────────
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
                        text: selectedCount > 0
                            ? 'Continue  ($selectedCount selected)'
                            : 'Select at least one',
                        onPressed: selectedCount > 0
                            ? () => pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  final String label;
  final BoxConstraints constraints;

  const _CategoryLabel({required this.label, required this.constraints});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: constraints.maxWidth * 0.03,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
