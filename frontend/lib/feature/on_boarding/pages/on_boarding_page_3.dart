import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_3_notifier.dart';
import 'package:watt_sense/feature/on_boarding/widget/onboarding_top_bar.dart';
import 'package:watt_sense/feature/on_boarding/widget/people_select.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class OnBoardingPage3 extends ConsumerStatefulWidget {
  final PageController pageController;
  const OnBoardingPage3({super.key, required this.pageController});

  @override
  ConsumerState<OnBoardingPage3> createState() => _OnBoardingPage3State();
}

class _OnBoardingPage3State extends ConsumerState<OnBoardingPage3> {
  static const _familyOptions = [
    'Just Me',
    'Small Family',
    'Large Family',
    'Joint Family',
  ];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onBoardingPage3Provider);
    final notifier = ref.read(onBoardingPage3Provider.notifier);

    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width * 0.05;
    final primary = Theme.of(context).primaryColor;

    return Column(
      children: [
        // ── Top bar ───────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: width * 0.03,
          ),
          child: OnboardingTopBar(
            currentStep: 3,
            onBack: () => widget.pageController.previousPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            ),
            trailing: OnboardingSkipButton(
              onSkip: () => widget.pageController.nextPage(
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
                  bottom: width * 0.28,
                  left: width * 0.05,
                  right: width * 0.05,
                  top: width * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Step 3 of 5',
                      style: GoogleFonts.poppins(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: fontSize * 0.65,
                        letterSpacing: 0.5,
                      ),
                    ),

                    SizedBox(height: width * 0.04),

                    Text(
                      'Your Household',
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
                      'This helps us estimate electricity usage accurately for your home.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: fontSize * 0.72,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: width * 0.05),

                    SvgPicture.asset(
                      SvgAssets.people_home_svg,
                      width: width * 0.38,
                    ),

                    SizedBox(height: width * 0.05),

                    // ── People count picker ───────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PeopleSelect(
                            text: '−',
                            onTap: notifier.decrementPeople,
                          ),

                          Column(
                            children: [
                              Text(
                                '${state.peopleCount}',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 2.8,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              Text(
                                state.peopleCount == 1 ? 'Person' : 'People',
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize * 0.72,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),

                          PeopleSelect(
                            text: '+',
                            onTap: notifier.incrementPeople,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: width * 0.06),

                    // ── Family type chips ─────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Family Type',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _familyOptions.map((option) {
                        final isSelected = state.selectedFamilyType == option;
                        return GestureDetector(
                          onTap: () => notifier.updateFamilyType(
                            isSelected ? null : option,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary.withOpacity(0.09)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 1.8 : 1.2,
                              ),
                            ),
                            child: Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 0.74,
                                color: isSelected ? primary : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: width * 0.06),

                    // ── House type (optional) ─────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'House Type  (optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: state.selectedHouseType,
                      items: ['Apartment', 'Bungalow', 'Independent House']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => notifier.updateHouseType(value),
                      hint: Text(
                        'Select house type',
                        style: GoogleFonts.poppins(color: Colors.grey.shade500),
                      ),
                      decoration: InputDecoration(
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
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: width * 0.035,
                        ),
                      ),
                    ),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: CtaButton(
                    text: 'Continue',
                    isLoading: _isSaving,
                    onPressed: () async {
                      setState(() => _isSaving = true);
                      try {
                        await notifier.saveDetails();
                        widget.pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
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
