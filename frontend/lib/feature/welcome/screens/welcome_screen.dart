import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/screen/sign_in_page.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/welcome/widgets/feature_card.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: constraints.maxHeight * 0.03,
                  horizontal: constraints.maxWidth * 0.1,
                ),
                child: Column(
                  children: [
                    Image.asset('assets/svg/welcome_illustration.png'),

                    SizedBox(height: constraints.maxHeight * 0.03),

                    Text(
                      'Take Control of Your',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth * 0.07,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    Text(
                      'Electricity Bill',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).primaryColor,
                        fontSize: constraints.maxWidth * 0.07,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: constraints.maxHeight * 0.01),

                    Wrap(
                      children: [
                        Text(
                          'Understand wheer your Power goes. Get Personalized plan. Save money every Month.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.035),

                    // decode your bill
                    FeatureCard(
                      title: 'Decode Your Bill',
                      description: 'Simple Breakdown of costs',
                      svgIcon: SvgAssets.search_icon,
                    ),

                    FeatureCard(
                      title: 'Personalized Plans',
                      description: 'Tailored to your usage',
                      svgIcon: SvgAssets.lighning_icon,
                    ),

                    FeatureCard(
                      title: 'Track Savings',
                      description: 'See your Money Saved',
                      svgIcon: SvgAssets.piggy_bank_icon,
                    ),

                    SizedBox(height: constraints.maxHeight * 0.035),

                    CtaButton(
                      text: 'Get Started',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
