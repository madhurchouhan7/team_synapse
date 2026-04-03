import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/bill/providers/fetch_bill_provider.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';

/// Tracks whether the user has added at least one bill or configured an active plan
final hasBillsProvider = Provider<bool>((ref) {
  final savedBill = ref.watch(savedBillProvider);
  final userAsync = ref.watch(authStateProvider);

  // Dynamically show the data dashboard if they have generated a local bill OR have an active plan stored remotely
  return savedBill != null || userAsync.valueOrNull?.activePlan != null;
});
