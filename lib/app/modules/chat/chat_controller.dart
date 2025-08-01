import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart' show VoiceService;
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/webSocketServices.dart';
import '../../api_servies/token.dart';
import '../../model/chat/sessionHistoryModel.dart';
import '../../model/chat/session_chat_model.dart';
import '../../model/chat/suggesions_Model.dart';

class ChatController extends GetxController with GetTickerProviderStateMixin{
  final WebSocketService wsService;
  final String sessionId;
  final int personaId;
  var isTyping = false.obs;
  var messages = <Messages>[].obs;
  var session = Rxn<Session>();
  StreamSubscription? _streamSubscription;
  final suggestions = <String>[].obs;
  var isLoadingSuggestions = false.obs;
  var showSuggestions = true.obs;
  var isFirstTime = true.obs;
  final isReloadingHistory = false.obs;
  late AnimationController historyAnimationController;
  final bool isNewSession;
  var sessionHistory = <SessionHistory>[].obs;


  final ScrollController scrollController = ScrollController();

  ChatController({
    required this.wsService,
    required this.sessionId,
    required this.personaId,
    this.isNewSession = false,
  });

  @override
  void onInit() {
    super.onInit();

    // Initialize animation controller
    historyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    print('🔄 Initializing ChatController for persona: $personaId, session: $sessionId');
    fetchSessionDetails();
    fetchSuggestions(personaId);
    // Setup WebSocket stream listener with proper error handling
    _setupWebSocketListener();
  }


// Add this method to your ChatController
  Future<void> reloadHistory() async {
    try {
      // Force refresh the history by calling the API again
      final response = await AuthRepository().fetchPersonaChatHistory(personaId);

      if (response != null && response['success'] == true) {
        // You can process the response here if needed
        print('History reloaded successfully');
      } else {
        Get.snackbar('Error', 'Failed to reload history');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error reloading history: $e');
      print('Error reloading history: $e');
    }
  }

  // Add method to refresh session history
  Future<void> refreshSessionHistory() async {
    try {
      final response = await AuthRepository().fetchPersonaChatHistory(personaId);
      if (response != null && response['success'] == true) {
        final sessions = (response['sessions'] as List)
            .map((e) => SessionHistory.fromJson(e))
            .toList();
        sessionHistory.assignAll(sessions);
      }
    } catch (e) {
      print('Error refreshing session history: $e');
    }
  }


  void _setupWebSocketListener() {
    // Cancel any existing subscription
    _streamSubscription?.cancel();

    // Wait a bit to ensure WebSocket is connected
    Future.delayed(const Duration(milliseconds: 500), () {
      _streamSubscription = wsService.stream.listen(
            (event) {
          _handleWebSocketMessage(event);
        },
        onError: (error) {
          print('❌ WebSocket stream error: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('✅ WebSocket stream closed');
          _handleConnectionClosed();
        },
      );

      print('📡 WebSocket stream listener setup complete');
    });
  }

  void _handleWebSocketMessage(dynamic event) {
    try {
      print('🔍 Processing WebSocket event: $event');

      // Handle both string and already parsed JSON
      Map<String, dynamic> data;
      if (event is String) {
        data = jsonDecode(event);
      } else if (event is Map<String, dynamic>) {
        data = event;
      } else {
        print('❌ Unexpected event type: ${event.runtimeType}');
        return;
      }

      print('📋 Parsed data: $data');

      // Handle different message types
      switch (data['type']) {
        case 'connection':
          print('✅ WebSocket connection confirmed: ${data['message']}');
          break;

        case 'error':
          print('❌ WebSocket error received: ${data['message']}');
          Get.snackbar(
            "Connection Error",
            data['message'] ?? "WebSocket error occurred",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          break;

        case 'typing':
          isTyping.value = (data['is_typing'] == true);
          print('⌨️ Typing status: ${isTyping.value}');
          break;

        case 'chat_message':
        case 'message':
        // Check if it's a voice message
          final messageType = data['message_type'] ?? 'text';
          if (messageType == 'voice') {
            _handleIncomingVoiceMessage(data);
          } else {
            _handleIncomingMessage(data);
          }
          break;

        default:
          print('❓ Unknown message type: ${data['type']}');
      }
    } catch (e) {
      print("❌ Error parsing websocket event: $e");
      print("❌ Raw event: $event");
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      // Stop typing indicator
      isTyping.value = false;

      // Extract message content with multiple fallbacks
      String content = '';
      if (data.containsKey('content') && data['content'] != null) {
        content = data['content'].toString();
      } else if (data.containsKey('message') && data['message'] != null) {
        content = data['message'].toString();
      }

      if (content.isEmpty) {
        print('❌ No content found in message data: $data');
        return;
      }

      // Fix: Convert string message_id to int
      int? messageId;
      final rawMessageId = data['message_id'] ?? data['id'];
      if (rawMessageId != null) {
        if (rawMessageId is String) {
          messageId = int.tryParse(rawMessageId);
        } else if (rawMessageId is int) {
          messageId = rawMessageId;
        }
      }

      final timestamp = data['timestamp'] ?? data['created_at'] ?? DateTime.now().toIso8601String();

      print('💬 Adding new AI message (${content.length} chars): ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

      // Create new message object
      final newMessage = Messages(
        id: messageId, // Now properly converted to int?
        content: content,
        isUser: false,
        createdAt: timestamp,
      );

      // Add to messages list and force update
      messages.add(newMessage);
      print('📝 Message added to UI. Total messages: ${messages.length}');

      // Force UI refresh
      update(); // This triggers GetX rebuild
      messages.refresh(); // This also triggers observable update

      // Scroll to bottom after UI update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

    } catch (e) {
      print('❌ Error handling incoming message: $e');
      print('❌ Message data: $data');
    }
  }

  void _handleConnectionError() {
    isTyping.value = false;
    // Try to reconnect after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!wsService.isConnected) {
        _attemptReconnect();
      }
    });
  }

  void _handleConnectionClosed() {
    isTyping.value = false;
  }

  int? get sessionIdAsInt {
    if (sessionId is int) return sessionId as int;
    if (sessionId is String) return int.tryParse(sessionId as String);
    return null;
  }

  Future<void> fetchSessionDetails() async {
    try {
      final sessionIdInt = sessionIdAsInt;
      if (sessionIdInt == null) {
        print("❌ Invalid session ID: cannot convert '$sessionId' to integer");
        return;
      }

      print("📋 Fetching session details for ID: $sessionIdInt");
      final response = await AuthRepository().fetchSessionsDetails(sessionIdInt);
      final model = SessonChatHistoryModel.fromJson(response);
      session.value = model.session;

      // Clear existing messages and add fetched ones
      messages.clear();
      if (model.messages != null && model.messages!.isNotEmpty) {
        messages.assignAll(model.messages!);
        print('📥 Loaded ${model.messages!.length} existing messages');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    } catch (e) {
      print("❌ Failed to fetch session details: $e");
    }
  }
  Future<void> fetchSuggestions(int personaId) async {
    try {
      // Only fetch suggestions for new sessions
      if (!isNewSession) {
        showSuggestions.value = false;
        return;
      }

      isLoadingSuggestions.value = true;
      final response = await AuthRepository().AiSuggestions(personaId);

      if (response != null) {
        final model = SuggesionsModel.fromJson(response);

        if (model.success) {
          suggestions.assignAll(model.suggestions);
          showSuggestions.value = suggestions.isNotEmpty;
        } else {
          suggestions.clear();
          showSuggestions.value = false;
        }
      } else {
        suggestions.clear();
        showSuggestions.value = false;
      }
    } catch (e) {
      print('❌ Failed to fetch suggestions: $e');
      suggestions.clear();
      showSuggestions.value = false;
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  void onSuggestionTap(String suggestion, TextEditingController textController) {
    textController.text = suggestion;
    showSuggestions.value = false;
  }

  void send(String msg) {
    showSuggestions.value = false;

    // Add user message to UI immediately for better UX
    final userMessage = Messages(
      id: null,
      content: msg,
      isUser: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    messages.add(userMessage);
    print('📤 Added user message to UI: $msg');

    // Force UI update
    update();
    messages.refresh();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    // Check WebSocket connection before sending
    if (!wsService.isConnected) {
      print('❌ WebSocket not connected, attempting to reconnect...');

      // Try to reconnect
      _attemptReconnect().then((_) {
        if (wsService.isConnected) {
          wsService.sendMessage(msg);
          print('📤 Message sent after reconnection: $msg');
        } else {
          Get.snackbar(
            "Connection Error",
            "Unable to send message. Please try again.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });
    } else {
      wsService.sendMessage(msg);
      print('📤 Message sent: $msg');
    }
  }

  Future<void> _attemptReconnect() async {
    try {
      print('🔄 Attempting to reconnect WebSocket...');
      final token = await TokenStorage.getLoginAccessToken();
      if (token != null) {
        await wsService.connect(sessionId, token, personaId: personaId);

        // Re-setup the stream listener after reconnection
        _setupWebSocketListener();

        print('🔄 Reconnected to WebSocket');
      }
    } catch (e) {
      print('❌ Reconnection failed: $e');
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  // Add these methods to your existing ChatController class

// Replace your sendVoiceMessage method in ChatController with this:

  Future<void> sendVoiceMessage(String sessionId) async {
    final voiceService = Get.find<VoiceService>();

    try {
      final response = await voiceService.stopRecordingAndSendToChat(sessionId);

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Fix: Convert string message_id to int
        int? messageId;
        if (data['message_id'] != null) {
          if (data['message_id'] is String) {
            messageId = int.tryParse(data['message_id']);
          } else if (data['message_id'] is int) {
            messageId = data['message_id'];
          }
        }

        // Add voice message to UI
        final voiceMessage = Messages(
          id: messageId,
          content: data['transcript'], // The converted text
          isUser: true,
          createdAt: DateTime.now().toIso8601String(),
          messageType: 'voice', // This will make isVoice return true
          voiceUrl: data['voice_url'],
          transcript: data['transcript'],
        );

        messages.add(voiceMessage);
        print('🎤 Added voice message to UI');

        // Force UI update
        update();
        messages.refresh();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });

        // IMPORTANT: Send the transcript to WebSocket to get AI response
        if (wsService.isConnected && data['transcript'] != null) {
          wsService.sendMessage(data['transcript']);
          print('📤 Sent transcript to AI: ${data['transcript']}');
        }

        Get.snackbar("Success", "Voice message sent successfully");
      } else {
        Get.snackbar("Error", "Failed to send voice message");
      }
    } catch (e) {
      print('❌ Error sending voice message: $e');
      Get.snackbar("Error", "Error sending voice message: $e");
    }
  }

// Replace your _handleIncomingVoiceMessage method with this:

  void _handleIncomingVoiceMessage(Map<String, dynamic> data) {
    try {
      // Stop typing indicator
      isTyping.value = false;

      final messageType = data['message_type'] ?? 'text';

      if (messageType == 'voice') {
        // Fix: Convert string message_id to int
        int? messageId;
        final rawMessageId = data['message_id'] ?? data['id'];
        if (rawMessageId != null) {
          if (rawMessageId is String) {
            messageId = int.tryParse(rawMessageId);
          } else if (rawMessageId is int) {
            messageId = rawMessageId;
          }
        }

        // Handle voice message
        final voiceMessage = Messages(
          id: messageId,
          content: data['transcript'] ?? data['content'],
          isUser: false,
          createdAt: data['timestamp'] ?? data['created_at'] ?? DateTime.now().toIso8601String(),
          messageType: 'voice', // This will make isVoice return true
          voiceUrl: data['voice_url'],
          transcript: data['transcript'],
        );

        messages.add(voiceMessage);
        print('🎤 Added incoming voice message to UI');
      } else {
        // Handle regular text message (your existing logic)
        _handleIncomingMessage(data);
        return; // Early return to avoid duplicate UI updates
      }

      // Force UI update
      update();
      messages.refresh();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

    } catch (e) {
      print('❌ Error handling incoming voice message: $e');
    }
  }

  @override
  void onClose() {
    print('🧹 Cleaning up ChatController for persona: $personaId, session: $sessionId');

    // Cancel stream subscription first
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Disconnect WebSocket - don't await in onClose as it's void
    wsService.disconnect().catchError((e) {
      print('❌ Error disconnecting WebSocket in onClose: $e');
    });

    // Dispose scroll controller if it hasn't been disposed yet

    historyAnimationController.dispose();
    try {
      if (scrollController.hasClients) {
        scrollController.dispose();
      }
    } catch (e) {
      print('❌ ScrollController already disposed or error disposing: $e');
    }

    super.onClose();
  }

  void navigateToOldSession() {
    // Implementation for navigating to old session
  }
}