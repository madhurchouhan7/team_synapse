import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInWithGoogle extends StatelessWidget {
  const SignInWithGoogle({super.key, required this.svgAssets, this.onPressed});

  final String svgAssets;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth / 600;
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.055,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // svg
              SvgPicture.asset(
                svgAssets,
                height: fontSize * 40,
                width: fontSize * 40,
              ),

              SizedBox(width: fontSize * 20),

              // text
              Text(
                'Continue with Google',
                style: GoogleFonts.poppins(
                  fontSize: fontSize * 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
