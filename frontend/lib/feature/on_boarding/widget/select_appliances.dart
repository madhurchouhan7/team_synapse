import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';
import 'package:watt_sense/feature/on_boarding/provider/selected_appliance_notifier.dart';

class SelectAppliances extends ConsumerWidget {
  const SelectAppliances({
    super.key,
    required this.title,
    required this.description,
    required this.svgPath,
    required this.category,
  });
  final String title;
  final String description;
  final String svgPath;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Generate unique ID from title
    final applianceId = title.toLowerCase().replaceAll(' ', '_');

    // Watch if this appliance is selected
    final isSelected = ref.watch(
      selectedAppliancesProvider.select(
        (appliances) => appliances.any((item) => item.id == applianceId),
      ),
    );

    // Create appliance model using Freezed factory
    final appliance = ApplianceModel(
      id: applianceId,
      title: title,
      description: description,
      svgPath: svgPath,
      category: category,
    );

    return GestureDetector(
      onTap: () {
        // Toggle selection
        ref
            .read(selectedAppliancesProvider.notifier)
            .toggleAppliance(appliance);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fontSize = width * 0.04;

          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(
              vertical: constraints.maxWidth > 600 ? 12 : 8,
            ),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(width * 0.03),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    svgPath,
                    colorFilter: isSelected
                        ? ColorFilter.mode(
                            Theme.of(context).primaryColor,
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                ),

                SizedBox(width: width * 0.05),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize * 1.1,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize * 0.85,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox indicator
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: width * 0.05,
                  height: width * 0.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
