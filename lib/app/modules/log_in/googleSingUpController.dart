// Updated GoogleSignUpController
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hr/app/api_servies/notification_services.dart';
import 'package:hr/app/modules/log_in/user_controller.dart' show UserController;
import '../../api_servies/repository/auth_repo.dart';
import '../main_screen/main_screen_view.dart';

class GoogleSignUpController extends GetxController {
  final userController = Get.put(UserController());
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;
  final selectedPersonaId = 1.obs;

  Future<void> handleGoogleSignUp() async {
    try {
      isLoading.value = true;

      // Step 1: Sign in with Google via Firebase
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        Get.snackbar("Error", "Google sign-in failed: No user data.");
        return;
      }

      final email = user.email!;
      final name = user.displayName ?? 'Google User';

      // Step 2: Send to backend social login API
      final personaBody = {
        "persona": selectedPersonaId.value,
      };

      final success = await authRepo.googleSignUpAndSetPersona(
        email: email,
        name: name,
        provider: 'google',
        personaBody: personaBody,
      );

      userController.setUserEmail(user.email ?? 'No Email Found');

      // Step 3: Handle success or failure
      if (success) {
        // Initialize notification service after successful Google login
        await initializeNotificationService();

        Get.snackbar("Success", "Google sign-in complete and persona set.");
        print("Google signin successful");
        Get.to(MainScreen());
      } else {
        Get.snackbar("Error", "Failed to set persona after Google login.");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print("GoogleSignUp Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize notification service
  Future<void> initializeNotificationService() async {
    try {
      // Register notification service if not already registered
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }

      // Get instance and enable connection
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }
}