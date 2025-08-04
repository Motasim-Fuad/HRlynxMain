import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/auth_repo.dart';
import 'package:hr/app/api_servies/token.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();

  // Observables
  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  // New observables for subscription status tracking
  final isCanceled = false.obs;
  final hasPremiumAccess = false.obs;
  final subscriptionStatus = ''.obs;
  final isActive = false.obs;
  final showReactivateButton = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check subscription status on initialization
    checkAndUpdateSubscriptionStatus();
  }

  // Combined method to check subscription status and update UI accordingly
  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;

      // First check the subscription status
      await checkSubscriptionStatus();

      // Then fetch the available personas based on subscription status
      await fetchIsSubcriptionData();

    } catch (e) {
      print("❌ Error in checkAndUpdateSubscriptionStatus: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Check subscription status from the API
  Future<void> checkSubscriptionStatus() async {
    try {
      print("🔄 Checking subscription status...");

      final response = await authRepo.checkSubscriptionStatus();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Update subscription status observables
        isActive.value = data['is_active'] ?? false;
        isCanceled.value = data['is_canceled'] ?? false;
        hasPremiumAccess.value = data['has_premium_access'] ?? false;
        subscriptionStatus.value = data['subscription_state'] ?? '';
        showReactivateButton.value = data['show_reactivate_button'] ?? false;

        // Update isSubscribed based on the correct logic:
        // isSubscribed = true when is_active = true AND is_canceled = false
        // This means user has full access to all personas
        isSubscribed.value = isActive.value && !isCanceled.value;

        print("📊 Subscription Status Update:");
        print("   is_active: ${isActive.value}");
        print("   is_canceled: ${isCanceled.value}");
        print("   has_premium_access: ${hasPremiumAccess.value}");
        print("   subscription_state: ${subscriptionStatus.value}");
        print("   show_reactivate_button: ${showReactivateButton.value}");
        print("   isSubscribed (calculated): ${isSubscribed.value}");

      } else {
        print("❌ Failed to get subscription status");
        // If API fails, assume not subscribed
        _resetSubscriptionState();
      }

    } catch (e) {
      print("❌ Error checking subscription status: $e");
      // On error, assume not subscribed
      _resetSubscriptionState();
    }
  }

  // Reset subscription state to default values
  void _resetSubscriptionState() {
    isSubscribed.value = false;
    isActive.value = false;
    isCanceled.value = false;
    hasPremiumAccess.value = false;
    showReactivateButton.value = false;
  }

  // Fetch subscription data from the personas endpoint
  Future<void> fetchIsSubcriptionData() async {
    try {
      print("🔄 Fetching subscription data...");

      final response = await authRepo.fetchUserIsSubcribed();
      final model = UserIsSubcribedModel.fromJson(response);

      if (model.data != null) {
        subcriptionData.assignAll(model.data?.personas ?? []);
        canSwitch.value = model.data?.canSwitch ?? false;
        selectedPersona.value = model.data?.userSelectedPersona;

        print("🔔 Subscription data updated:");
        print("   personas count: ${subcriptionData.length}");
        print("   canSwitch: ${canSwitch.value}");
        print("   selectedPersona: ${selectedPersona.value?.title}");
      }
    } catch (e) {
      print("❌ Error fetching subscription data: $e");
    }
  }

  // Cancel subscription method
  Future<void> cancelSubscription() async {
    try {
      print("🔄 Cancelling subscription...");

      final response = await authRepo.cancelSubscription();

      if (response != null && response['success'] == true) {
        print("✅ Subscription cancelled successfully");

        // Update local state immediately after successful cancellation
        isCanceled.value = true;
        isSubscribed.value = false; // User should now have limited access
        showReactivateButton.value = true;

        // Re-check subscription status to get the latest state
        await checkAndUpdateSubscriptionStatus();

        print("   isSubscribed after cancellation: ${isSubscribed.value}");
        print("   isCanceled: ${isCanceled.value}");
      }
    } catch (e) {
      print("❌ Error cancelling subscription: $e");
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Reactivate subscription method
  Future<void> reactivateSubscription() async {
    try {
      print("🔄 Reactivating subscription...");

      // Call your reactivation API endpoint here
      // final response = await authRepo.reactivateSubscription();

      // For now, just re-check the status
      await checkAndUpdateSubscriptionStatus();

    } catch (e) {
      print("❌ Error reactivating subscription: $e");
      rethrow;
    }
  }

  // Check if user can cancel subscription
  bool get canCancelSubscription {
    // User can cancel if subscription is active and not already canceled
    return isActive.value && !isCanceled.value;
  }

  // Check if user can reactivate subscription
  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  // Check if a specific persona is accessible - THIS IS THE KEY METHOD
  Future<bool> isPersonaAccessible(int personaId) async {
    // Case 1: is_active = true AND is_canceled = false
    // User has full subscription access - all personas available
    if (isActive.value && !isCanceled.value) {
      print("🟢 Full access: is_active=true, is_canceled=false - All personas accessible");
      return true;
    }

    // Case 2: is_active = true AND is_canceled = true
    // User canceled but still in trial/grace period - only selected persona accessible
    else if (isActive.value && isCanceled.value) {
      print("🟡 Limited access: is_active=true, is_canceled=true - Only selected persona accessible");

      // Get the selected persona ID from onboarding (stored in TokenStorage)
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        bool hasAccess = selectedPersonaId == personaId;
        print("   Selected persona ID: $selectedPersonaId, Checking persona ID: $personaId, Has access: $hasAccess");
        return hasAccess;
      } else {
        // Fallback to API selected persona if no onboarding selection found
        bool hasAccess = selectedPersona.value?.id == personaId;
        print("   Using API selected persona: ${selectedPersona.value?.id}, Checking persona ID: $personaId, Has access: $hasAccess");
        return hasAccess;
      }
    }

    // Case 3: is_active = false (no subscription or expired)
    // Only selected persona accessible
    else {
      print("🔴 No subscription: is_active=false - Only selected persona accessible");

      // Get the selected persona ID from onboarding (stored in TokenStorage)
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        bool hasAccess = selectedPersonaId == personaId;
        print("   Selected persona ID: $selectedPersonaId, Checking persona ID: $personaId, Has access: $hasAccess");
        return hasAccess;
      } else {
        // Fallback to API selected persona if no onboarding selection found
        bool hasAccess = selectedPersona.value?.id == personaId;
        print("   Using API selected persona: ${selectedPersona.value?.id}, Checking persona ID: $personaId, Has access: $hasAccess");
        return hasAccess;
      }
    }
  }

  // Get accessible personas based on subscription status
  Future<List<Personas>> getAccessiblePersonas() async {
    // If user has full subscription access
    if (isActive.value && !isCanceled.value) {
      return subcriptionData.toList();
    }
    // If user has limited access (canceled subscription or no subscription)
    else {
      // Get the selected persona ID from onboarding
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        // Find the persona by ID from the list
        final selectedPersonaFromList = subcriptionData.firstWhereOrNull(
                (persona) => persona.id == selectedPersonaId
        );

        if (selectedPersonaFromList != null) {
          return [selectedPersonaFromList];
        }
      }

      // Fallback to API selected persona
      if (selectedPersona.value != null) {
        return [selectedPersona.value!];
      }

      return [];
    }
  }

  // Switch selected persona (if allowed)
  void switchPersona(Personas persona) {
    if (canSwitch.isTrue) {
      selectedPersona.value = persona;
      // Save to TokenStorage as well
      TokenStorage.saveSelectedPersonaId(persona.id ?? 0);
      // Optional: API call to update selection can be placed here.
    }
  }

  // Get subscription display message
  String get subscriptionDisplayMessage {
    if (isActive.value && !isCanceled.value) {
      return "Active subscription - Full access";
    } else if (isActive.value && isCanceled.value) {
      return "Trial canceled - Limited access until expiry";
    } else {
      return "Free tier - Limited access";
    }
  }

  // Get subscription action message
  String get subscriptionActionMessage {
    if (canReactivateSubscription) {
      return "Reactivate subscription for full access";
    } else if (!isActive.value) {
      return "Subscribe for full access to all personas";
    }
    return "";
  }
}