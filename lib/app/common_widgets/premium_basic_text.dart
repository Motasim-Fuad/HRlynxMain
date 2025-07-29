
import 'package:flutter/material.dart';
import 'package:hr/app/utils/app_colors.dart' show AppColors;

class PremiumBasicText extends StatelessWidget {
  const PremiumBasicText({super.key, required this.tittle});
  final String tittle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 88),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_outlined,
            color: AppColors.primarycolor,
            size: 24,
          ),
          Text(
            tittle,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF050505),
            ),
          ),
        ],
      ),
    );
  }
}
