

import 'package:flutter/material.dart';
import 'package:hr/app/common_widgets/premium_basic_text.dart' show PremiumBasicText;
import 'package:hr/app/utils/app_colors.dart' show AppColors;

class CongratulaionsText extends StatelessWidget {
  const CongratulaionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Benefits Unlocked',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Color(0xFF050505),
          ),
        ),
        SizedBox(height: 20),
        PremiumBasicText(tittle: 'Unlimited AI Persona Access'),
        SizedBox(height: 6),
        PremiumBasicText(tittle: 'Unlimited Chat Assistance'),
        SizedBox(height: 6),
        PremiumBasicText(tittle: 'Save Conversations'),
        SizedBox(height: 20),
        Text(
          textAlign: TextAlign.center,
          "Time to perk up your HR game, you're fully unlocked!",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.primarycolor,
          ),
        ),
      ],
    );
  }
}
