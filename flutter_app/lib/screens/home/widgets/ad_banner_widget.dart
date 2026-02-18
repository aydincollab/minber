import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '📢 REKLAM ALANI — AdMob Banner (320×50)',
          style: TextStyle(
            color: AppColors.textMuted.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
