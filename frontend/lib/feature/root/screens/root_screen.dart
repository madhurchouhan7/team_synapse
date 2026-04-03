import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:watt_sense/feature/bill/screen/bill_screen.dart';
import 'package:watt_sense/feature/dashboard/screens/dashboard_screen.dart';
import 'package:watt_sense/feature/insights/screens/insights_screen.dart';
import 'package:watt_sense/feature/plans/screens/plans_screen.dart';
import 'package:watt_sense/feature/profile/screens/profile_screen.dart';
import 'package:watt_sense/feature/root/providers/root_navigation_provider.dart';

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);

    final screens = [
      const DashboardScreen(),
      const PlansScreen(),
      const InsightsScreen(),
      const BillScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SalomonBottomBar(
          margin: const EdgeInsets.all(18),
          itemPadding: const EdgeInsets.all(14),
          curve: Curves.easeInOut,
          selectedItemColor: const Color(0xFF1E60F2),
          unselectedItemColor: const Color(0xFF94A3B8),
          currentIndex: currentIndex,
          onTap: (index) => ref.read(bottomNavProvider.notifier).state = index,
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              title: const Text("Home"),
              selectedColor: const Color(0xFF1E60F2),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.my_library_books_rounded),
              activeIcon: const Icon(Icons.my_library_books),
              title: const Text("Plan"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.insights_outlined),
              activeIcon: const Icon(Icons.insights),
              title: const Text("Insight"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              title: const Text("Bills"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              title: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
