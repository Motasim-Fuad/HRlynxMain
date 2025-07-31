
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/common_widgets/congratulaions_text.dart';
import 'package:hr/app/modules/main_screen/main_screen_view.dart';
import 'package:hr/app/utils/app_images.dart';

class CongratulationView extends StatelessWidget {
  const CongratulationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * .1),
            Image.asset(AppImages.coffee),
            Text(
              'Congratulations!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 34,
                color: Color(0xFF121212),
              ),
            ),
            SizedBox(height: Get.height * .05),
            CongratulaionsText(),
            SizedBox(height: Get.height * .19),
               Button(title: 'Home',onTap: () {
                Get.offAll(MainScreen());
              },
               ),
          ],
        ),
      ),
    );
  }
}
