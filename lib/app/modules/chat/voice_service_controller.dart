import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart' show ApiConstants;
import 'package:hr/app/api_servies/token.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import your existing files
// import '../api_servies/api_Constant.dart';
// import '../api_servies/token.dart';

class VoiceService extends GetxController {
  final AudioRecorder _recorder = AudioRecorder();
  var isRecording = false.obs;
  var isProcessing = false.obs;
  String? _recordingPath;

  // Check and request microphone permission
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      if (!await _checkPermission()) {
        Get.snackbar("Permission Denied", "Microphone permission is required");
        return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/voice_message_$timestamp.m4a';

      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Null check for recording path
      final recordingPath = _recordingPath;
      if (recordingPath != null) {
        await _recorder.start(config, path: recordingPath);
        isRecording.value = true;
        return true;
      } else {
        print('❌ Recording path is null');
        return false;
      }
    } catch (e) {
      print('❌ Error starting recording: $e');
      return false;
    }
  }

  // Stop recording and send to backend
  Future<String?> stopRecordingAndProcess() async {
    try {
      if (!isRecording.value) return null;

      await _recorder.stop();
      isRecording.value = false;
      isProcessing.value = true;

      final recordingPath = _recordingPath;
      if (recordingPath == null || !File(recordingPath).existsSync()) {
        Get.snackbar("Error", "Recording file not found");
        isProcessing.value = false;
        return null;
      }

      // Send to backend API
      final convertedText = await _sendVoiceToBackend(recordingPath);

      // Clean up the temp file
      try {
        await File(recordingPath).delete();
      } catch (e) {
        print('Warning: Could not delete temp file: $e');
      }

      isProcessing.value = false;
      return convertedText;

    } catch (e) {
      print('❌ Error stopping recording: $e');
      isProcessing.value = false;
      return null;
    }
  }

  // Send voice file to backend API
  Future<String?> _sendVoiceToBackend(String filePath) async {
    try {
      final token = await TokenStorage.getLoginAccessToken();
      final uri = Uri.parse("${ApiConstants.baseUrl}/api/chat/voice-to-text/");

      if (token == null) {
        Get.snackbar("Error", "Authentication token not found");
        return null;
      }

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add audio file with proper content type
      final audioFile = await http.MultipartFile.fromPath(
        'voice_file',  // Try this field name first
        filePath,
        filename: 'voice_message.m4a',
      );
      request.files.add(audioFile);

      // Debug: Check file exists and size
      final file = File(filePath);
      print('🔍 File exists: ${file.existsSync()}');
      print('🔍 File size: ${file.lengthSync()} bytes');
      print('🔍 File path: $filePath');

      print('🎤 Sending voice file to backend...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Voice API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true &&
            jsonResponse['data'] != null &&
            jsonResponse['data']['converted_text'] != null) {

          final convertedText = jsonResponse['data']['converted_text'] as String;
          print('✅ Voice converted successfully: $convertedText');
          return convertedText;
        } else {
          Get.snackbar("Error", "Failed to convert voice to text");
          return null;
        }
      } else {
        Get.snackbar("Error", "Server error: ${response.statusCode}");
        return null;
      }

    } catch (e) {
      print('❌ Error sending voice to backend: $e');
      Get.snackbar("Error", "Failed to process voice: $e");
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      if (isRecording.value) {
        await _recorder.stop();
        isRecording.value = false;

        // Delete the temp file
        final recordingPath = _recordingPath;
        if (recordingPath != null && File(recordingPath).existsSync()) {
          await File(recordingPath).delete();
        }
      }
    } catch (e) {
      print('❌ Error canceling recording: $e');
    }
  }

  @override
  void onClose() {
    _recorder.dispose();
    super.onClose();
  }
}