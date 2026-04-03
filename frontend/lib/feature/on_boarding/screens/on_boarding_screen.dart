import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/on_boarding/pages/on_boarding_page_1.dart';
import 'package:watt_sense/feature/on_boarding/pages/on_boarding_page_2.dart'
    show OnBoardingPage2;
import 'package:watt_sense/feature/on_boarding/pages/on_boarding_page_3.dart';
import 'package:watt_sense/feature/on_boarding/pages/on_boarding_page_4.dart';
import 'package:watt_sense/feature/on_boarding/pages/on_boarding_page_5.dart';

class OnBoardingScreen extends ConsumerStatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  ConsumerState<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends ConsumerState<OnBoardingScreen> {
  final PageController pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                physics:
                    NeverScrollableScrollPhysics(), // Disable swipe navigation
                children: [
                  OnBoardingPage1(pageController: pageController),
                  OnBoardingPage2(pageController: pageController),
                  OnBoardingPage3(pageController: pageController),
                  OnBoardingPage4(pageController: pageController),
                  OnBoardingPage5(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
