import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_2_notifier.dart';
import 'package:watt_sense/feature/on_boarding/widget/onboarding_top_bar.dart';
import 'package:watt_sense/feature/on_boarding/widget/use_my_current_location.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class OnBoardingPage2 extends ConsumerWidget {
  final PageController pageController;

  const OnBoardingPage2({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onBoardingPage2Provider);
    final notifier = ref.read(onBoardingPage2Provider.notifier);

    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width * 0.05;
    final primary = Theme.of(context).primaryColor;

    // A state / city must be selected to proceed.
    final canContinue =
        state.selectedState != null && state.selectedCity != null;

    return Column(
      children: [
        // ── Top bar ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: width * 0.03,
          ),
          child: OnboardingTopBar(
            currentStep: 2,
            onBack: () => pageController.previousPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            ),
            trailing: OnboardingSkipButton(
              onSkip: () => pageController.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ),

        // ── Scrollable content ────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: width * 0.30,
                  left: width * 0.05,
                  right: width * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Step label
                    Text(
                      'Step 2 of 5',
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize * 0.65,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: width * 0.04),

                    Text(
                      'Where is your home?',
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
                      "We'll use this to fetch accurate electricity rates for your area.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: fontSize * 0.72,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: width * 0.05),

                    SvgPicture.asset(
                      SvgAssets.location_svg,
                      width: width * 0.38,
                    ),

                    SizedBox(height: width * 0.05),

                    // GPS button
                    const UseMyCurrentLocation(),

                    SizedBox(height: width * 0.06),

                    // — OR divider —
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR SELECT MANUALLY',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade200)),
                      ],
                    ),

                    SizedBox(height: width * 0.05),

                    // State dropdown
                    _FieldLabel(label: 'State'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedState,
                      items: notifier.states
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (value) => notifier.updateState(value),
                      hint: Text(
                        'Select your State',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                      decoration: _inputDecoration(width),
                    ),

                    SizedBox(height: width * 0.04),

                    // City dropdown
                    _FieldLabel(label: 'City'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedCity,
                      items: state.selectedState != null
                          ? notifier.availableCities
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList()
                          : [],
                      onChanged: state.selectedState == null
                          ? null
                          : (value) => notifier.updateCity(value),
                      hint: Text(
                        state.selectedState == null
                            ? 'Select a State first'
                            : 'Select your City',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                      decoration: _inputDecoration(width),
                    ),

                    SizedBox(height: width * 0.04),

                    // DISCOM dropdown
                    _FieldLabel(label: 'Electricity Provider (DISCOM)'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedDiscom,
                      items: availableDiscoms
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (value) => notifier.updateDiscom(value),
                      hint: Text(
                        'Select your Electricity Provider',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                      decoration: _inputDecoration(width),
                    ),

                    SizedBox(height: width * 0.04),

                    // Current location status badge
                    if (state.lat != null && state.lng != null)
                      _LocationBadge(lat: state.lat!, lng: state.lng!),
                  ],
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
                    text: 'Continue',
                    isLoading: state.isSaving,
                    onPressed: canContinue
                        ? () async {
                            await notifier.saveAddress();
                            if (!state.hasError) {
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(double width) => InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF5568FE), width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: width * 0.04,
      vertical: width * 0.035,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  final double lat, lng;
  const _LocationBadge({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Color(0xFF5568FE), size: 16),
          const SizedBox(width: 8),
          Text(
            'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF5568FE),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
