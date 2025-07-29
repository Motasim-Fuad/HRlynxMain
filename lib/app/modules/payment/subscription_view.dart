// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hr/app/common_widgets/privacy_policy.dart';
// import 'package:hr/app/modules/congratulaion_screen/congratulation_view.dart';
// import 'package:hr/app/modules/payment/subcription_controller.dart';
// import 'package:hr/app/modules/terms_of_use/terms_of_use.dart';
// import 'package:hr/app/utils/app_colors.dart';
// import 'package:hr/app/utils/app_images.dart' show AppImages;
//
// class Subscription extends StatelessWidget {
//   const Subscription({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(SubscriptionController());
//
//     return Scaffold(
//       backgroundColor: AppColors.primarycolor,
//       body: SafeArea(
//         child: Obx(() {
//           if (controller.isLoading.value && controller.plans.isEmpty) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!controller.hasPlans.value) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Text(
//                   'No subscription plans available at this time',
//                   style: TextStyle(color: Colors.white, fontSize: 18),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             );
//           }
//
//           final yearlyPlan = controller.plans.firstWhereOrNull(
//                   (plan) => plan.planType == 'explorer_yearly'
//           );
//           final monthlyPlan = controller.plans.firstWhereOrNull(
//                   (plan) => plan.planType == 'explorer_monthly'
//           );
//
//           return Stack(
//             children: [
//               SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       height: 150,
//                       child: Image.asset(AppImages.splash, fit: BoxFit.cover),
//                     ),
//                     Text(
//                       'Explore Pro',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 32,
//                       ),
//                     ),
//                     Text(
//                       'Start your 7-day free trial',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         fontSize: 20,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 80, right: 30),
//                       child: Column(
//                         children: [
//                           _buildFeatureRow('Unlimited AI Persona Access'),
//                           _buildFeatureRow('Unlimited Chat Assistance'),
//                           _buildFeatureRow('Save Conversations'),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 30),
//
//                     if (yearlyPlan != null)
//                       _buildPlanCard(
//                         context,
//                         controller,
//                         'yearly',
//                         '${yearlyPlan.name} \$${yearlyPlan.price}/${yearlyPlan.interval}',
//                         'Save 25% - Get 3 months Free',
//                         true,
//                       ),
//
//                     if (monthlyPlan != null) ...[
//                       const SizedBox(height: 20),
//                       _buildPlanCard(
//                         context,
//                         controller,
//                         'monthly',
//                         '${monthlyPlan.name} \$${monthlyPlan.price}/${monthlyPlan.interval}',
//                         'Less than a daily latte. A lot more satisfying.',
//                         false,
//                       ),
//                     ],
//
//                     const SizedBox(height: 20),
//                     _buildStartTrialButton(controller),
//                     const SizedBox(height: 20),
//                     _buildSkipTrialText(),
//                     const SizedBox(height: 15),
//                     _buildPolicyLinks(),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//               if (controller.paymentInProgress.value)
//                 Container(
//                   color: Colors.black.withOpacity(0.5),
//                   child: Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(),
//                         const SizedBox(height: 20),
//                         Text(
//                           'Processing Payment...',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
//
//   Widget _buildFeatureRow(String text) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Icon(Icons.check_outlined, color: Colors.white),
//         const SizedBox(width: 3),
//         Text(
//           text,
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w400,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPlanCard(
//       BuildContext context,
//       SubscriptionController controller,
//       String planType,
//       String title,
//       String subtitle,
//       bool isPopular,
//       ) {
//     final isSelected = controller.selectedPlan.value == planType;
//     final textColor = isSelected ? AppColors.primarycolor : Colors.white;
//     final bgColor = isSelected ? Colors.white : Colors.transparent;
//     final borderColor = isSelected ? AppColors.primarycolor : Colors.white;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       child: SizedBox(
//         height: MediaQuery.of(context).size.height * 0.14, // Slightly increased height
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Flexible(
//                     child: Text(
//                       title,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         fontSize: 22, // Slightly reduced font size
//                         color: textColor,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Flexible(
//                     child: Text(
//                       subtitle,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w400,
//                         fontSize: 13, // Slightly reduced font size
//                         color: textColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   width: isSelected ? 2 : 1,
//                   color: borderColor,
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 color: bgColor,
//               ),
//             ),
//             if (isPopular)
//               Positioned(
//                 top: -12,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Text(
//                       'Most Popular',
//                       style: TextStyle(
//                         color: AppColors.primarycolor,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStartTrialButton(SubscriptionController controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       child: SizedBox(
//         height: MediaQuery.of(Get.context!).size.height * 0.12, // Increased height
//         child: ElevatedButton(
//           onPressed: controller.isLoading.value ? null : controller.startFreeTrial,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.teal.shade700,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//           child: controller.isLoading.value
//               ? CircularProgressIndicator(color: AppColors.primarycolor)
//               : Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Start Free Trial',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 22, // Reduced font size
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'No commitment. Cancel anytime during trial period.',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w400,
//                   fontSize: 12,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSkipTrialText() {
//     return GestureDetector(
//       onTap: () => Get.to(() => CongratulationView()),
//       child: Text(
//         'Skip trial, continue with limited free access.',
//         style: TextStyle(
//           decoration: TextDecoration.underline,
//           decorationColor: Colors.white,
//           fontWeight: FontWeight.w400,
//           fontSize: 12,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPolicyLinks() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         GestureDetector(
//           onTap: () => Get.to(() => TermsOfUse()),
//           child: Text(
//             'Terms of Use',
//             style: TextStyle(
//               decoration: TextDecoration.underline,
//               decorationColor: Colors.white,
//               color: Colors.white,
//               fontWeight: FontWeight.w400,
//               fontSize: 14,
//             ),
//           ),
//         ),
//         Text(
//           ' and ',
//           style: TextStyle(
//             fontWeight: FontWeight.w400,
//             color: Colors.white,
//             fontSize: 14,
//           ),
//         ),
//         GestureDetector(
//           onTap: () => Get.to(() => PrivacyPolicy()),
//           child: Text(
//             'Privacy Policy.',
//             style: TextStyle(
//               decoration: TextDecoration.underline,
//               decorationColor: Colors.white,
//               color: Colors.white,
//               fontWeight: FontWeight.w400,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }