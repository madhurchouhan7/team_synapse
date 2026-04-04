// lib/core/network/api_constants.dart
// Central place for all API base URLs and route paths.

import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────────────────────
  // Bound dynamically to your host machine's physical network IPv4 space
  // This allows BOTH Emulators and Real Devices on your Wi-Fi to hit the backend!
  // static const String _localHost = 'http://10.78.211.93:5000';

  // static const String _localHost =
  //     'http://10.0.2.2:5000'; // Android emulator ONLY

  //  Define your Production URL
  static const String _productionUrl =
      'https://wattwise-app-mono-repo.onrender.com';

  //  Define your Local URL (Choose one based on how you test)
  // Use 10.0.2.2 if testing on Android Emulator
  // Use your computer's IP (e.g., 192.168.1.X) if testing on a physical phone on the same WiFi
  //static const String _developmentUrl = 'http://10.0.2.2:5000';
  static const String _developmentUrl = 'http://192.168.52.219:5000';

  //  Automatically pick the base URL based on build mode!
  static String get _baseUrl {
    if (kReleaseMode) {
      // If we are building a release APK/AAB for the store, ALWAYS use production
      return _productionUrl;
    } else {
      // If we are just clicking "Run" or "Debug" in VS Code, ALWAYS use local development
      // NOTE: You can temporarily change this to _productionUrl if you specifically need to debug prod data.
      return _developmentUrl;
    }
  }

  // ── Final URLs ─────────────────────────────────────────────────────────────
  static String get baseUrl => '$_baseUrl/api/v1';
  static String get healthUrl => '$_baseUrl/health';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ── Auth Routes ───────────────────────────────────────────────────────────
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';

  // ── User Routes ───────────────────────────────────────────────────────────
  static const String userMe = '/users/me';
  static const String userProfile = userMe;

  // ── BBPS Routes ───────────────────────────────────────────────────────────
  static const String bbpsFetchBill = '/bbps/fetch-bill';

  // ── (Add more as you build features) ─────────────────────────────────────
}
