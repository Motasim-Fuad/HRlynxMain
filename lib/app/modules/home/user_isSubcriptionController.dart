import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/auth_repo.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();

  // Observables
  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  // Fetch subscription status from API
  Future<void> fetchIsSubcriptionData() async {
    try {
      isLoading.value = true;

      final response = await authRepo.fetchUserIsSubcribed();
      final model = UserIsSubcribedModel.fromJson(response);

      if (model.data != null) {
        subcriptionData.assignAll(model.data?.personas ?? []);
        isSubscribed.value = model.data?.isSubscribed ?? false;
        canSwitch.value = model.data?.canSwitch ?? false;
        selectedPersona.value = model.data?.userSelectedPersona;
      }
    } catch (e) {
      print("❌ Error fetching subscription data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Optional: Switch selected persona
  void switchPersona(Personas persona) {
    if (canSwitch.isTrue) {
      selectedPersona.value = persona;
      // Optional: API call to update selection can be placed here.
    }
  }
}
