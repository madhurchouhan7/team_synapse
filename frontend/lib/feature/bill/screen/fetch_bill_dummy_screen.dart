import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fetch_bill_provider.dart';

/// Dummy Screen to test and verify the BBPS Fetch Bill flow using Setu sandbox API
class FetchBillDummyScreen extends ConsumerWidget {
  const FetchBillDummyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Riverpod provider state
    final fetchBillState = ref.watch(fetchBillProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fetch Bill (BBPS)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // State rendering logic
              Expanded(
                child: Center(
                  child: fetchBillState.when(
                    data: (data) {
                      if (data == null) {
                        return const Text(
                          'No bill fetched yet.\nPress the button below to fetch a dummy bill.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        );
                      }

                      // We can extract nested data gracefully
                      final amountDue =
                          data['data']?['amountExact'] ??
                          data['amountExact'] ??
                          'Unknown';

                      final billerName =
                          data['data']?['billerName'] ??
                          data['billerName'] ??
                          'TEST_BILLER';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bill Fetched Successfully!',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Biller: $billerName',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Amount Due: ₹$amountDue',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Raw Data:\n$data',
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Fetching Bill from Setu BBPS...'),
                      ],
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to Fetch Bill',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Button Trigger
              ElevatedButton(
                onPressed: fetchBillState.isLoading
                    ? null
                    : () {
                        // Call the AsyncNotifier to fetch bill
                        ref
                            .read(fetchBillProvider.notifier)
                            .fetchBill(
                              billerId: 'TEST_BILLER_ID',
                              consumerNumber: '1234567890',
                            );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: fetchBillState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Fetch Dummy Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
