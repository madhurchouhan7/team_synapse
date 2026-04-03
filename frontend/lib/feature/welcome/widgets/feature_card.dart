import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.svgIcon,
  });

  final String title;
  final String description;
  final String svgIcon;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth / 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            // icon
            SvgPicture.asset(svgIcon),

            SizedBox(width: screenWidth * 0.07),

            //text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // text1
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 22 * fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // text2
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 18 * fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
