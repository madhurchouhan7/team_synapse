import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/router/app_router.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';
import 'package:watt_sense/feature/on_boarding/model/on_boarding_state.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_5_notifier.dart';
import 'package:watt_sense/feature/on_boarding/provider/selected_appliance_notifier.dart';

class OnBoardingPage5 extends ConsumerStatefulWidget {
  const OnBoardingPage5({super.key});

  @override
  ConsumerState<OnBoardingPage5> createState() => _OnBoardingPage5State();
}

class _OnBoardingPage5State extends ConsumerState<OnBoardingPage5> {
  late ConfettiController confettiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  Widget _buildLevelButton(
    WidgetRef ref,
    ApplianceModel app,
    LevelOption option,
    ApplianceLocalState state,
  ) {
    final isSelected = state.usageLevel == option.label;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref
            .read(onBoardingPage5Provider.notifier)
            .updateUsageLevel(app, option.label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                option.label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.duration,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAppliances = ref.watch(selectedAppliancesProvider);
    final width = MediaQuery.sizeOf(context).width;
    // pageState contains all localStates for appliances
    ref.watch(onBoardingPage5Provider);
    final notifier = ref.read(onBoardingPage5Provider.notifier);

    void playConfetti() {
      confettiController.play();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.06,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // shoot from centre top
                    Center(
                      child: ConfettiWidget(
                        blastDirection: -pi / 2,
                        confettiController: confettiController,
                        blastDirectionality: BlastDirectionality.directional,
                        shouldLoop: false,
                        particleDrag: 0.05,
                        numberOfParticles: 50,
                        colors: const [
                          Color(0xFF5568FE),
                          Color(0xFFFE5568),
                          Color(0xFF56FE55),
                          Color(0xFFFFC300),
                          Color(0xFF00BFFF),
                        ],
                      ),
                    ),
                    Text(
                      'ALMOST DONE! 🎉',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5568FE),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'How often do you use these?',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tell us about your daily usage for these key appliances. You can always update this later in your settings.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (selectedAppliances.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appliances selected.\nGo back to select some!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...selectedAppliances.map((app) {
                        final state = notifier.getOrInitState(app);
                        final options = notifier.getUsageOptions(app);
                        final dropdownConfigs = notifier.getDropdownConfigs(
                          app,
                        );
                        const primaryColor = Color(0xFF5568FE);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[40],
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF0FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: SvgPicture.asset(
                                      app.svgPath,
                                      colorFilter: const ColorFilter.mode(
                                        primaryColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      app.title,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: options
                                    .map(
                                      (opt) => _buildLevelButton(
                                        ref,
                                        app,
                                        opt,
                                        state,
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade200, height: 1),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => notifier.toggleExpanded(app),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'More details',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(
                                      state.isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey.shade500,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isExpanded) ...[
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Number of ${app.title}s'.replaceAll(
                                        'ss',
                                        's',
                                      ),
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => notifier.updateCount(
                                              app,
                                              state.count - 1,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '${state.count}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => notifier.updateCount(
                                              app,
                                              state.count + 1,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                color: primaryColor,
                                                borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(7),
                                                  bottomRight: Radius.circular(
                                                    7,
                                                  ),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (dropdownConfigs.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    children: dropdownConfigs.map((config) {
                                      final isLast =
                                          config == dropdownConfigs.last;
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: isLast ? 0 : 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                config.label,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    isExpanded: true,
                                                    value:
                                                        state
                                                            .selectedDropdowns[config
                                                            .label] ??
                                                        config.options.first,
                                                    icon: Icon(
                                                      Icons.unfold_more,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black87,
                                                      fontSize: 14,
                                                    ),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        notifier.updateDropdown(
                                                          app,
                                                          config.label,
                                                          val,
                                                        );
                                                      }
                                                    },
                                                    items: config.options.map((
                                                      opt,
                                                    ) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: opt,
                                                        child: Text(opt),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // add a confetti animation
                  onPressed: (_isLoading || selectedAppliances.isEmpty)
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // Run setup logic
                            await notifier.finishSetup(selectedAppliances);

                            // Persist the onboarding-complete flag
                            final authUserModel = ref
                                .read(authStateProvider)
                                .value;
                            if (authUserModel != null) {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .markOnboardingComplete(authUserModel.uid);
                            }

                            // Visual Confetti Celebration
                            playConfetti();
                            await Future.delayed(const Duration(seconds: 1));

                            // Invalidating triggers AppRouter to flip to RootScreen
                            if (context.mounted) {
                              ref.invalidate(authStateProvider);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const AppRouter(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to finish setup: $error',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Finish Setup 🎉',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
