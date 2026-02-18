import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/app_colors.dart';
import '../../../services/tts_service.dart';

class TtsMiniPlayer extends StatelessWidget {
  final TtsService ttsService;
  final VoidCallback onClose;

  const TtsMiniPlayer({
    super.key,
    required this.ttsService,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ttsService,
      builder: (context, child) {
        if (ttsService.isStopped) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.darkMid.withOpacity(0.95),
            border: Border(
              top: BorderSide(
                color: AppColors.textMuted.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: ttsService.currentPosition,
                      backgroundColor: AppColors.textMuted.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      minHeight: 2,
                    ),
                    const SizedBox(height: 12),
                    
                    // Controls
                    Row(
                      children: [
                        // Play/Pause button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              ttsService.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.dark,
                            ),
                            onPressed: () {
                              if (ttsService.isPlaying) {
                                ttsService.pause();
                              } else if (ttsService.isPaused) {
                                ttsService.resume();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Sesli Okuma',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(ttsService.currentPosition * 100).toInt()}% tamamlandı',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Speed control
                        _buildSpeedButton(context),
                        const SizedBox(width: 8),
                        
                        // Stop button
                        IconButton(
                          icon: const Icon(
                            Icons.stop,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            ttsService.stop();
                            onClose();
                          },
                        ),
                        
                        // Close button
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                          ),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSpeedSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.speed,
              size: 16,
              color: AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              '${ttsService.speed}x',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Okuma Hızı',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                final isSelected = ttsService.speed == speed;
                return ListTile(
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.textLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.gold)
                      : null,
                  onTap: () {
                    ttsService.setSpeed(speed);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
