import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../model/onbordingModel.dart';
import '../log_in/log_in_view.dart'; // <-- import your model

class HrRoleController extends GetxController {
  var selectedIndex = 0.obs;
  var personaList = <Data>[].obs; // List<Data>
  var isLoading = false.obs;

  final _authRepo = AuthRepository();

  void select(int index) {
    if (index >= 0 && index < personaList.length) {
      selectedIndex.value = index;
    }
  }


  Future<void> fetchPersonas() async {
    try {
      isLoading.value = true;
      final response = await _authRepo.getParsonaType();
      final model = OnbordingModel.fromJson(response);
      personaList.value = model.data ?? [];
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print("error is =====$e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    fetchPersonas();
    super.onInit();
  }
}
