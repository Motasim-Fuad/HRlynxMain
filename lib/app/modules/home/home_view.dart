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
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: _buildProfilePicture(profileController),
          )),
        ),
        title: const Text(
          'HRlynx Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1B1E28),
          ),
        ),
        centerTitle: true,
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
                              const SizedBox(height: 40),
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

                // Subscription status info (optional)
                Obx(() {
                  if (is_SubcribedController.subscriptionActionMessage.isNotEmpty) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: is_SubcribedController.canReactivateSubscription
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: is_SubcribedController.canReactivateSubscription
                              ? Colors.orange.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            is_SubcribedController.canReactivateSubscription
                                ? Icons.info_outline
                                : Icons.star_outline,
                            color: is_SubcribedController.canReactivateSubscription
                                ? Colors.orange.shade600
                                : Colors.blue.shade600,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              is_SubcribedController.subscriptionActionMessage,
                              style: TextStyle(
                                color: is_SubcribedController.canReactivateSubscription
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),

                // Persona Grid
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.personaList.isEmpty) {
                    return const Center(child: Text('No personas available'));
                  }

                  print("📊 Subscription status in HomeView:");
                  print("   isActive: ${is_SubcribedController.isActive.value}");
                  print("   isSubscribed: ${is_SubcribedController.isSubscribed.value}");
                  print("   isCanceled: ${is_SubcribedController.isCanceled.value}");
                  print("   hasPremiumAccess: ${is_SubcribedController.hasPremiumAccess.value}");
                  print("   selectedPersona: ${is_SubcribedController.selectedPersona.value?.id}");

                  return FutureBuilder<List<Widget>>(
                    future: _buildPersonaGrid(
                        controller,
                        is_SubcribedController,
                        isTablet
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading personas'));
                      }

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                        children: snapshot.data ?? [],
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

  // Build persona grid asynchronously to handle async persona accessibility check
  Future<List<Widget>> _buildPersonaGrid(
      ChatAllAiPersona controller,
      UserIsSubcribedController is_SubcribedController,
      bool isTablet,
      ) async {
    List<Widget> personaCards = [];

    for (int index = 0; index < controller.personaList.length; index++) {
      final persona = controller.personaList[index];

      // Check if this persona is accessible (await the async method)
      bool isPersonaActive = await is_SubcribedController.isPersonaAccessible(persona.id ?? 0);

      personaCards.add(
        GestureDetector(
          onTap: () async {
            if (isPersonaActive) {
              await controller.startChatSession(persona);
            } else {
              // Show different messages based on subscription status
              String title = 'Premium Required';
              String message = 'Subscribe to access all AI personas';
              Color backgroundColor = Colors.orange;

              if (is_SubcribedController.canReactivateSubscription) {
                title = 'Reactivate Subscription';
                message = 'Reactivate your subscription to access all personas';
                backgroundColor = Colors.blue;
              }

              Get.snackbar(
                title,
                message,
                snackPosition: SnackPosition.TOP,
                backgroundColor: backgroundColor,
                colorText: Colors.white,
                duration: Duration(seconds: 3),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isPersonaActive ? Colors.white : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPersonaActive ? Colors.grey.shade300 : Colors.grey.shade400,
              ),
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
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: "${persona.avatar}",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        if (!isPersonaActive)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      is_SubcribedController.canReactivateSubscription
                                          ? Icons.refresh
                                          : Icons.lock,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    if (is_SubcribedController.canReactivateSubscription)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Reactivate',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
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
                      color: isPersonaActive ? Colors.black : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return personaCards;
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