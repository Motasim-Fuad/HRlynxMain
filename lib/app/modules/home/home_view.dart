import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/home/user_isSubcriptionController.dart' show UserIsSubcribedController;
import 'package:hr/app/modules/onboarding/onboarding_controller.dart';
import 'package:hr/app/modules/profile/profile_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_images.dart';
import '../../modules/news/news_view.dart';
import 'chat_al_ai_persona_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {


    final ProfileController profileController = Get.put(ProfileController());
    final UserIsSubcribedController is_SubcribedController = Get.put(UserIsSubcribedController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      is_SubcribedController.fetchIsSubcriptionData();
    });
    final controller = Get.put(ChatAllAiPersona());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Obx(() => Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            clipBehavior: Clip.antiAlias, // Ensures the child is clipped to the circle
            alignment: Alignment.center,
            child: _buildProfilePicture(profileController),
          )),
        ),
        title: const Text(
          'HRlynx Home',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        centerTitle: true,
        actions: [
          // Add any action buttons here if needed
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Breaking HR News Card ---
                Container(
                  height: size.height * 0.30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AppImages.home_container,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.6),
                            colorBlendMode: BlendMode.darken,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Breaking HR News',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Stay updated with the latest HR insights, trends and policy changes.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => Get.to(() => const NewsView()),
                                child: Container(
                                  width: 120,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF013D3B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'View Feed',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Chat with your AI HR Assistants:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet ? 28 : 24,
                    color: AppColors.primarycolor,
                  ),
                ),
                const SizedBox(height: 10),

                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.personaList.isEmpty) {
                    return const Center(child: Text('No personas available'));
                  }
                  print("subcription value :::::::::::${is_SubcribedController.isSubscribed.value}");
                  print("subcription value :::::::::::${is_SubcribedController.selectedPersona.value?.id}");


                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: controller.personaList.length,
                    itemBuilder: (context, index) {
                      final persona = controller.personaList[index];

                      // Determine if persona is active based on subscription logic
                      bool isPersonaActive;
                      if(is_SubcribedController.isSubscribed.value == true) {
                        // sob gula active thakba
                        isPersonaActive = true;
                      } else {
                        // sudu jaita selected oi ta active thakba, baki gula de active thakba
                        isPersonaActive = is_SubcribedController.selectedPersona.value?.id == persona.id;
                      }

                      return GestureDetector(
                        onTap: () async {
                          if (isPersonaActive) {
                            await controller.startChatSession(persona);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isPersonaActive ? Colors.teal : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1, // Keeps image square like in screenshot
                                  child: Stack(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: "${persona.avatar}",
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                      ),
                                      if (!isPersonaActive)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black54,
                                            child: const Center(
                                              child: Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                                child: Text(
                                  persona.title ?? 'No Title',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isPersonaActive ? Colors.white : Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build Profile Picture Widget
  Widget _buildProfilePicture(ProfileController profileController) {
    if (profileController.userProfilePicture.value.isEmpty) {
      // No profile picture - show default avatar
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.person,
          size: 24,
          color: Colors.white,
        ),
      );
    }

    // Has profile picture URL - use CachedNetworkImage
    return CachedNetworkImage(
      imageUrl: profileController.userProfilePicture.value,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ Failed to load profile image in HomeView: $error');
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
          ),
          child: Icon(
            Icons.person,
            size: 24,
            color: Colors.red.shade400,
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}