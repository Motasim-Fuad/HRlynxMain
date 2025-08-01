import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';

class VoiceMessageBubble extends StatelessWidget {
  final String? voiceUrl;
  final String? transcript;
  final bool isUser;
  final String timestamp;
  final VoiceService voiceService;

  const VoiceMessageBubble({
    Key? key,
    required this.voiceUrl,
    this.transcript,
    required this.isUser,
    required this.timestamp,
    required this.voiceService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice player row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              Obx(() => GestureDetector(
                onTap: () {
                  if (voiceUrl != null && voiceUrl!.isNotEmpty) {
                    print('🎵 Attempting to play: $voiceUrl');
                    voiceService.playVoiceMessage(voiceUrl!);
                  } else {
                    print('❌ No voice URL available');
                    Get.snackbar("Error", "Voice file not available");
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Check if this specific voice is playing
                    (voiceUrl != null && voiceService.isPlayingUrl(voiceUrl!))
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )),

              SizedBox(width: 8),

              // Waveform visualization (simplified)
              Expanded(
                child: Container(
                  height: 30,
                  child: Row(
                    children: List.generate(15, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          height: (index % 4 + 1) * 6.0, // Random heights for wave effect
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade300
                                : Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Duration display
              Obx(() {
                final duration = voiceService.totalDuration.value;
                final position = voiceService.playbackPosition.value;

                String timeText = "0:00";
                if (voiceUrl != null && voiceService.isPlayingUrl(voiceUrl!) && duration.inSeconds > 0) {
                  final remaining = duration - position;
                  final minutes = remaining.inMinutes;
                  final seconds = remaining.inSeconds % 60;
                  timeText = "$minutes:${seconds.toString().padLeft(2, '0')}";
                } else {
                  // Default duration for voice messages
                  timeText = "0:15";
                }

                return Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              }),
            ],
          ),

          // Transcript text (if available)
          if (transcript != null && transcript!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transcript!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],

          // Timestamp
          SizedBox(height: 4),
          Text(
            timestamp,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}