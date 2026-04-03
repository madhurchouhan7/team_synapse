import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_2_notifier.dart';

class UseMyCurrentLocation extends ConsumerWidget {
  const UseMyCurrentLocation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onBoardingPage2Provider.notifier);
    final state = ref.watch(onBoardingPage2Provider);

    return InkWell(
      splashColor: Colors.transparent,
      onTap: () async {
        final result = await notifier.determineLocation();
        if (!context.mounted) return;

        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS Coordinates fetched and stored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.065,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.my_location_rounded,
                color: Theme.of(context).primaryColor,
                size: MediaQuery.of(context).size.width / 600 * 34,
              ),
              SizedBox(width: 12),
              // text
              state.isLoadingLocation
                  ? Shimmer.fromColors(
                      baseColor: Theme.of(context).primaryColor,
                      highlightColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.4),
                      child: Text(
                        'Fetching...',
                        style: GoogleFonts.poppins(
                          fontSize:
                              MediaQuery.of(context).size.width / 600 * 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Text(
                      'Use My Current Location',
                      style: GoogleFonts.poppins(
                        fontSize: MediaQuery.of(context).size.width / 600 * 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
