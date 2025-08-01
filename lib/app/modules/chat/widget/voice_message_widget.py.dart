import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'dart:math' as math;
class VoiceMessageBubble extends StatefulWidget {
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
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize wave animation controller
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isUser ? Colors.blue[100] : Colors.grey[300],
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
              Obx(() {
                final isThisPlaying = widget.voiceUrl != null &&
                    widget.voiceService.isPlayingUrl(widget.voiceUrl!);

                // Control wave animation based on playing state
                if (isThisPlaying && !_waveAnimationController.isAnimating) {
                  _waveAnimationController.repeat();
                } else if (!isThisPlaying && _waveAnimationController.isAnimating) {
                  _waveAnimationController.stop();
                  _waveAnimationController.reset();
                }

                return GestureDetector(
                  onTap: () async {
                    if (widget.voiceUrl != null && widget.voiceUrl!.isNotEmpty) {
                      print('🎵 Attempting to play: ${widget.voiceUrl}');
                      try {
                        await widget.voiceService.playVoiceMessage(widget.voiceUrl!);
                      } catch (e) {
                        print('❌ Error playing voice: $e');
                        Get.snackbar("Error", "Could not play voice message");
                      }
                    } else {
                      print('❌ No voice URL available');
                      Get.snackbar("Error", "Voice file not available");
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isThisPlaying
                          ? (widget.isUser ? Colors.orange : Colors.green)
                          : (widget.isUser ? Colors.blue : Colors.grey.shade600),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isThisPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              }),

              SizedBox(width: 8),

              // Animated waveform visualization
              Expanded(
                child: Container(
                  height: 30,
                  child: Obx(() {
                    final isThisPlaying = widget.voiceUrl != null &&
                        widget.voiceService.isPlayingUrl(widget.voiceUrl!);

                    return AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(15, (index) {
                            // Calculate dynamic height based on animation and playing state
                            double baseHeight = (index % 4 + 1) * 6.0;
                            double animatedHeight = baseHeight;

                            if (isThisPlaying) {
                              // Create wave effect during playback
                              double waveOffset = (_waveAnimation.value * 2 * 3.14159) + (index * 0.5);
                              double multiplier = 1.0 + (0.8 * (1 + math.sin(waveOffset)) / 2);
                              animatedHeight = baseHeight * multiplier;
                            }

                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 1),
                                height: animatedHeight.clamp(4.0, 24.0), // Limit height range
                                decoration: BoxDecoration(
                                  color: isThisPlaying
                                      ? (widget.isUser
                                      ? Colors.orange.shade400
                                      : Colors.green.shade400)
                                      : (widget.isUser
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade500),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  }),
                ),
              ),

              SizedBox(width: 8),

              // Duration display
              Obx(() {
                final isThisPlaying = widget.voiceUrl != null &&
                    widget.voiceService.isPlayingUrl(widget.voiceUrl!);
                final duration = widget.voiceService.totalDuration.value;
                final position = widget.voiceService.playbackPosition.value;

                String timeText = "0:00";

                if (isThisPlaying && duration.inSeconds > 0) {
                  final remaining = duration - position;
                  final minutes = remaining.inMinutes;
                  final seconds = remaining.inSeconds % 60;
                  timeText = "$minutes:${seconds.toString().padLeft(2, '0')}";
                } else {
                  // Show default duration when not playing
                  timeText = "0:15";
                }

                return Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isThisPlaying
                        ? (widget.isUser ? Colors.orange.shade700 : Colors.green.shade700)
                        : Colors.grey.shade600,
                    fontWeight: isThisPlaying ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }),
            ],
          ),

          // Transcript text (if available)
          if (widget.transcript != null && widget.transcript!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.transcript!,
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
            widget.timestamp,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}


