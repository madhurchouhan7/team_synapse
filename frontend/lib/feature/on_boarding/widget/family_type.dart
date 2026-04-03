import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FamilyType extends StatelessWidget {
  const FamilyType({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      // onTap: () => print('Tapped on PeopleSelect'),
      child: Container(
        // minimum width
        width: MediaQuery.of(context).size.width * 0.3,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width / 600 * 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
