import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pure splash screen — no navigation logic.
/// The [AppRouter] drives navigation reactively via [authStateProvider].
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Deep Navy
              Color(0xFF2563EB), // Electric Blue
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Animated mascot
            Image.asset('assets/icon/icon_foreground.png', height: 180)
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleXY(
                  begin: 1.0,
                  end: 1.1,
                  duration: 1.5.seconds,
                  curve: Curves.easeInOut,
                )
                .rotate(
                  begin: -0.05,
                  end: 0.05,
                  duration: 2.seconds,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 30),

            // App title
            const Text(
                  'WattWise',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .moveY(begin: 20, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Understand. Reduce. Save.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms),

            const Spacer(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
