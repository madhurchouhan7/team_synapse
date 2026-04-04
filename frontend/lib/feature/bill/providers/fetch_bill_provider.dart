import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/main.dart';
import '../services/bbps_service.dart';

/// Provider for the [BbpsService] instance.
final bbpsServiceProvider = Provider<BbpsService>((ref) {
  return BbpsService();
});

/// AsyncNotifierProvider to manage the state of the Fetch Bill API call.
/// It yields a `Map<String, dynamic>?` representing the fetched bill data from Setu API.
final fetchBillProvider =
    AsyncNotifierProvider<FetchBillNotifier, Map<String, dynamic>?>(
      () => FetchBillNotifier(),
    );

/// Provider to store the saved/active bill locally for UI binding.
final savedBillProvider =
    StateNotifierProvider<SavedBillNotifier, Map<String, dynamic>?>((ref) {
      return SavedBillNotifier();
    });

class SavedBillNotifier extends StateNotifier<Map<String, dynamic>?> {
  static const _key = 'saved_bill_data';

  SavedBillNotifier() : super(_loadBill());

  static Map<String, dynamic>? _loadBill() {
    final str = sharedPrefs.getString(_key);
    if (str != null) {
      try {
        return json.decode(str) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  void saveBill(Map<String, dynamic> bill) {
    state = bill;
    sharedPrefs.setString(_key, json.encode(bill));
  }

  void clearBill() {
    state = null;
    sharedPrefs.remove(_key);
  }
}

class FetchBillNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  late final BbpsService _bbpsService;

  @override
  Future<Map<String, dynamic>?> build() async {
    _bbpsService = ref.watch(bbpsServiceProvider);
    return null; // Return null state initially indicating no bill is generated/fetched yet.
  }

  /// Triggers the fetch bill request and updates the state.
  Future<void> fetchBill({
    required String billerId,
    required String consumerNumber,
  }) async {
    // Set state to loading
    state = const AsyncValue.loading();

    try {
      // API call to fetch bill
      final billData = await _bbpsService.fetchBill(
        billerId: billerId,
        consumerNumber: consumerNumber,
      );

      // Update state with fetched data
      state = AsyncValue.data(billData);
    } catch (e, stackTrace) {
      // Update state to error case
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
