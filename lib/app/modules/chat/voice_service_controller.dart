import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart' show ApiConstants;
import 'package:hr/app/api_servies/token.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

class VoiceService extends GetxController {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  var isRecording = false.obs;
  var isProcessing = false.obs;
  var isPlaying = false.obs;
  var recordingDuration = 0.obs;
  var playbackPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;

  String? _currentlyPlayingUrl;
  String? _recordingPath;
  Timer? _recordingTimer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _playerDurationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayerListeners();
    _configureAudioPlayer();
  }

  // Configure audio player for better compatibility
  void _configureAudioPlayer() async {
    try {
      // Minimal configuration - remove if still causing issues
      await _player.setVolume(1.0);
      print('🎵 Audio player configured successfully');
    } catch (e) {
      print('⚠️ Error configuring audio player: $e');
      // Continue without audio context configuration if it fails
    }
  }

  // Set up audio player listeners once
  void _setupAudioPlayerListeners() {
    // Listen to player completion
    _playerCompleteSubscription = _player.onPlayerComplete.listen((_) {
      print('🎵 Audio playback completed');
      isPlaying.value = false;
      _currentlyPlayingUrl = null;
      playbackPosition.value = Duration.zero;
    });

    // Listen to player state changes
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      print('🎵 Player state changed: $state');
      switch (state) {
        case PlayerState.completed:
        case PlayerState.stopped:
          isPlaying.value = false;
          _currentlyPlayingUrl = null;
          playbackPosition.value = Duration.zero;
          break;
        case PlayerState.playing:
          isPlaying.value = true;
          break;
        case PlayerState.paused:
          isPlaying.value = false;
          break;
        default:
          break;
      }
    });

    // Listen to position changes
    _playerPositionSubscription = _player.onPositionChanged.listen((position) {
      playbackPosition.value = position;
    });

    // Listen to duration changes
    _playerDurationSubscription = _player.onDurationChanged.listen((duration) {
      totalDuration.value = duration;
      print('🎵 Audio duration: ${duration.inSeconds} seconds');
    });
  }

  // Check and request microphone permission
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Start recording with better format settings
  Future<bool> startRecording() async {
    try {
      if (!await _checkPermission()) {
        Get.snackbar("Permission Denied", "Microphone permission is required");
        return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Use .wav format for better compatibility, or .mp3 if supported
      _recordingPath = '${directory.path}/voice_message_$timestamp.wav';

      final config = RecordConfig(
        encoder: AudioEncoder.wav, // Changed from aacLc to wav for better compatibility
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // Mono recording
      );

      final recordingPath = _recordingPath;
      if (recordingPath != null) {
        await _recorder.start(config, path: recordingPath);
        isRecording.value = true;
        recordingDuration.value = 0;

        // Start timer
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          recordingDuration.value++;
        });

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

  // Stop recording and send to backend with session_id
  Future<Map<String, dynamic>?> stopRecordingAndSendToChat(String sessionId) async {
    try {
      if (!isRecording.value) return null;

      await _recorder.stop();
      _recordingTimer?.cancel();
      isRecording.value = false;
      isProcessing.value = true;

      final recordingPath = _recordingPath;
      if (recordingPath == null || !File(recordingPath).existsSync()) {
        Get.snackbar("Error", "Recording file not found");
        isProcessing.value = false;
        return null;
      }

      // Send to backend API with session_id
      final response = await _sendVoiceToBackend(recordingPath, sessionId);

      isProcessing.value = false;
      return response;

    } catch (e) {
      print('❌ Error stopping recording: $e');
      isProcessing.value = false;
      return null;
    }
  }

  // Send voice file to backend API with session_id
  Future<Map<String, dynamic>?> _sendVoiceToBackend(String filePath, String sessionId) async {
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

      // Add session_id as form field
      request.fields['session_id'] = sessionId;

      // Add audio file with proper filename
      final audioFile = await http.MultipartFile.fromPath(
        'voice_file',
        filePath,
        filename: 'voice_message.wav', // Changed to match the new format
      );
      request.files.add(audioFile);

      print('🎤 Sending voice file to backend with session_id: $sessionId');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Voice API Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return jsonResponse;
        } else {
          Get.snackbar("Error", "Failed to send voice message");
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

  // Enhanced play voice message with better error handling and caching
  Future<void> playVoiceMessage(String voiceUrl) async {
    try {
      print('🎵 Attempting to play voice: $voiceUrl');

      // If already playing this URL, pause it
      if (_currentlyPlayingUrl == voiceUrl && isPlaying.value) {
        print('🎵 Pausing current audio');
        await _player.pause();
        return;
      }

      // If playing different URL, stop it first
      if (isPlaying.value && _currentlyPlayingUrl != voiceUrl) {
        print('🎵 Stopping different audio');
        await _player.stop();
        await Future.delayed(Duration(milliseconds: 100)); // Brief delay
      }

      // Set the currently playing URL
      _currentlyPlayingUrl = voiceUrl;

      // Make sure the URL is properly formatted
      String playUrl = voiceUrl;
      if (!voiceUrl.startsWith('http')) {
        playUrl = '${ApiConstants.baseUrl}$voiceUrl';
      }

      print('🎵 Final play URL: $playUrl');

      // Method 1: Try direct URL play first
      await _playFromUrl(playUrl);

    } catch (e) {
      print('❌ Direct URL play failed: $e');
      // Method 2: Try downloading and playing locally
      await _downloadAndPlay(voiceUrl);
    }
  }

  // Method 1: Play directly from URL
  Future<void> _playFromUrl(String url) async {
    try {
      // Stop any current playback
      await _player.stop();

      // Add headers for authentication if needed
      final token = await TokenStorage.getLoginAccessToken();
      Map<String, String>? headers;
      if (token != null) {
        headers = {'Authorization': 'Bearer $token'};
      }

      // Try to play with headers
      await _player.play(
        UrlSource(url),
        // Note: audioplayers may not support custom headers in all versions
        // If this doesn't work, we'll fall back to download method
      );

      print('🎵 Audio play command sent via URL');
    } catch (e) {
      print('❌ URL play method failed: $e');
      throw e; // Re-throw to trigger fallback method
    }
  }

  // Method 2: Download file and play locally (fallback)
  Future<void> _downloadAndPlay(String voiceUrl) async {
    try {
      print('🎵 Attempting to download and play locally');

      // Make sure the URL is properly formatted
      String downloadUrl = voiceUrl;
      if (!voiceUrl.startsWith('http')) {
        downloadUrl = '${ApiConstants.baseUrl}$voiceUrl';
      }

      final token = await TokenStorage.getLoginAccessToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

      // Download the file
      final response = await http.get(Uri.parse(downloadUrl), headers: headers);

      if (response.statusCode == 200) {
        // Save to temporary file
        final directory = await getTemporaryDirectory();
        final fileName = voiceUrl.split('/').last;
        final localPath = '${directory.path}/temp_$fileName';

        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);

        print('🎵 File downloaded to: $localPath');

        // Play from local file
        await _player.play(DeviceFileSource(localPath));
        print('🎵 Playing from local file');

        // Clean up file after a delay
        Future.delayed(Duration(seconds: 30), () {
          if (file.existsSync()) {
            file.delete().catchError((e) => print('⚠️ Could not delete temp file: $e'));
          }
        });

      } else {
        throw Exception('Failed to download audio file: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Download and play method failed: $e');

      // Final fallback - show error to user
      isPlaying.value = false;
      _currentlyPlayingUrl = null;

      Get.snackbar(
        "Audio Error",
        "Could not play voice message. The audio file may be corrupted or unavailable.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  // Add method to stop current playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      isPlaying.value = false;
      _currentlyPlayingUrl = null;
      playbackPosition.value = Duration.zero;
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }

  // Add this method to check if specific URL is playing
  bool isPlayingUrl(String url) {
    return isPlaying.value && _currentlyPlayingUrl == url;
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      if (isRecording.value) {
        await _recorder.stop();
        _recordingTimer?.cancel();
        isRecording.value = false;
        recordingDuration.value = 0;

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

  // Format duration for display
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    _playerStateSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _recordingTimer?.cancel();

    // Dispose of resources
    _recorder.dispose();
    _player.dispose();
    super.onClose();
  }
}