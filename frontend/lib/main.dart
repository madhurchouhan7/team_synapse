import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/core/app_theme.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/core/notifications/notification_service.dart';
import 'package:watt_sense/core/router/app_router.dart';
import 'package:watt_sense/feature/dashboard/services/streak_local_service.dart';
import 'package:watt_sense/feature/insights/services/heatmap_local_service.dart';
import 'package:watt_sense/firebase_options.dart';

late SharedPreferences sharedPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialise the Dio API client (sets base URL, interceptors, etc.)
  ApiClient.instance.init();

  // Initialise FCM + device token registration
  await NotificationService.instance.init();

  sharedPrefs = await SharedPreferences.getInstance();

  // Initialise Hive (local database) and open the streak + heatmap cache boxes
  await Hive.initFlutter();
  await StreakLocalService.instance.init();
  await HeatmapLocalService.instance.init();

  Future<void> logFCMToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log('FCM Token: $token');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      title: 'WattWise',
      home: const AppRouter(),
    );
  }
}
