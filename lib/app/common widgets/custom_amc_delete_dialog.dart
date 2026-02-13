import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/common%20widgets/common_outline_button.dart';

class CustomAmcDeleteDialog extends StatelessWidget {
  const CustomAmcDeleteDialog({super.key, required this.onTapYes});
  final VoidCallback onTapYes;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: SizedBox(
                width: 300,
                child: Text(
                  "Are you sure you want to delete this AMC?.\n All the Pending call related to this AMC will be deleted too.",
                  style: GoogleFonts.publicSans(
                    color: const Color(0xff060809),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 100,
                    child: CommonFilledButton(
                      onPressed: onTapYes,
                      backgroundColor: AppColors.primary,
                      label: "Yes",
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: CommonOutlineButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      color: AppColors.primary,
                      label: "No",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
