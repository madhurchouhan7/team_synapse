import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/on_boarding/widget/select_appliances.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class AddApplianceScreen extends ConsumerWidget {
  const AddApplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the selected count

    // final selectedCount = ref.watch(
    //   selectedAppliancesProvider.select((appliances) => appliances.length),
    // );
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Appliances',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: width * 0.25),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: width * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check any new appliances you want to add to your profile.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: fontSize * 0.75,
                                ),
                              ),
                              SizedBox(height: width * 0.05),

                              // cooling
                              Text(
                                'COOLING',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectAppliances(
                                title: 'Air Conditioner',
                                description: 'Split AC, Window AC, Inverter',
                                svgPath: SvgAssets.ac_icon,
                                category: 'COOLING',
                              ),
                              SelectAppliances(
                                title: 'Air Cooler',
                                description: 'Desert, Personal, Tower',
                                svgPath: SvgAssets.wind_icon,
                                category: 'COOLING',
                              ),

                              // HEATING
                              Text(
                                'HEATING',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectAppliances(
                                title: 'Geyser',
                                description: 'Electric, Gas, Instant',
                                svgPath: SvgAssets.geyser_icon,
                                category: 'HEATING',
                              ),
                              SelectAppliances(
                                title: 'Room Heater',
                                description: 'Fan, Oil, Halogen',
                                svgPath: SvgAssets.room_heater_icon,
                                category: 'HEATING',
                              ),

                              // always on
                              Text(
                                'ALWAYS ON',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectAppliances(
                                title: 'Refridgerator',
                                description: 'Single, Double Door',
                                svgPath: SvgAssets.fridge_icon,
                                category: 'ALWAYS ON',
                              ),
                              SelectAppliances(
                                title: 'Television',
                                description: 'LCD, LED, Smart',
                                svgPath: SvgAssets.tv_icon,
                                category: 'ALWAYS ON',
                              ),
                              SelectAppliances(
                                title: 'Wi-Fi Router',
                                description: 'Modem, Extender',
                                svgPath: SvgAssets.wifi_router_icon,
                                category: 'ALWAYS ON',
                              ),

                              // OCCASIONAL USE
                              Text(
                                'OCCASIONAL USE',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: constraints.maxWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectAppliances(
                                title: 'Washing Machine',
                                description: 'Front Load, Top Load',
                                svgPath: SvgAssets.washing_machine_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Microwave Oven',
                                description: 'Solo, Grill, Convection',
                                svgPath: SvgAssets.microwave_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Water Purifier',
                                description: 'RO, UV',
                                svgPath: SvgAssets.water_purifier_icon,
                                category: 'OCCASIONAL USE',
                              ),
                              SelectAppliances(
                                title: 'Computer',
                                description: 'Desktop, Workstation',
                                svgPath: SvgAssets.computer_icon,
                                category: 'OCCASIONAL USE',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: CtaButton(
                            text: 'Done',
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
