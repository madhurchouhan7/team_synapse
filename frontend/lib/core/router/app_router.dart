import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/on_boarding/screens/on_boarding_screen.dart';
import 'package:watt_sense/feature/root/screens/root_screen.dart';
import 'package:watt_sense/feature/splash_screen/splash_screen.dart';
import 'package:watt_sense/feature/welcome/screens/welcome_screen.dart';

/// Central routing widget.
/// Listens to [authStateProvider] and decides which screen to render.
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      // While Firebase is initialising — show the splash.
      loading: () => const SplashScreen(),

      // Auth error (rare — e.g. network down at launch)
      error: (_, __) => const WelcomeScreen(),

      data: (user) {
        if (user == null) {
          // Not signed in → show Welcome → Auth flow
          return const WelcomeScreen();
        }

        // If not onboarded, show onboarding.
        if (!user.isOnboardingComplete) {
          return const OnBoardingScreen();
        }

        // Fully authenticated & onboarded → main app
        return const RootScreen();
      },
    );
  }
}
