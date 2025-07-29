import 'package:get/get.dart';
import '../../api_servies/token.dart';
import '../../api_servies/webSocketServices.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../model/home/chat_al_ai_persona.dart';
import '../chat/caht_view.dart';
import '../chat/chat_controller.dart';

class ChatAllAiPersona extends GetxController {
  var personaList = <Data>[].obs;
  final isLoading = true.obs;

  final authRepo = AuthRepository();

  /// Cache: personaId -> sessionId
  final Map<int, String> _sessionMap = {};

  @override
  void onInit() {
    fetchAllAiPersona();
    super.onInit();
  }

  Future<void> startChatSession(Data persona) async {
    try {
      final personaId = persona.id!;
      final tag = 'chat_$personaId';
      print('👉 Starting chat for persona: $personaId');

      final token = await TokenStorage.getLoginAccessToken();
      if (token == null) throw Exception('Token is null');

      // Step 1: Get existing sessionId if stored
      String? sessionIdNullable = await TokenStorage.getPersonaSessionId(personaId);
      late String sessionId;
      bool isNewSession = false;

      if (sessionIdNullable == null) {
        // This is a new session
        isNewSession = true;
        sessionId = await authRepo.createSession(personaId) ?? (throw Exception('Failed to create session'));
        await TokenStorage.savePersonaSessionId(personaId, sessionId);
      } else {
        // This is an existing session
        sessionId = sessionIdNullable;
      }

      final wsService = WebSocketService();
      wsService.connect(sessionId, token, personaId: personaId);

      if (!Get.isRegistered<ChatController>(tag: tag)) {
        Get.put(ChatController(
          wsService: wsService,
          sessionId: sessionId,
          personaId: personaId,
          isNewSession: isNewSession, // Pass the flag here
        ), tag: tag);
      }

      Get.to(() => ChatView(
        sessionId: sessionId,
        token: token,
        webSocketService: wsService,
        controllerTag: tag,
      ));

    } catch (e) {
      print('❌ Error in startChatSession: $e');
      Get.snackbar("Error", "Could not start chat session");
    }
  }

  Future<void> fetchAllAiPersona() async {
    try {
      isLoading.value = true;
      final response = await authRepo.getAllAiPersona();
      final model = AllAiPersonaChat.fromJson(response);
      personaList.value = model.data ?? [];
    } catch (e) {
      print("❌ Error fetching personas: $e");
    } finally {
      isLoading.value = false;
    }
  }

}



