import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ReadingProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const ReadingProgress({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.textMuted.withOpacity(0.1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold],
            ),
          ),
        ),
      ),
    );
  }
}
