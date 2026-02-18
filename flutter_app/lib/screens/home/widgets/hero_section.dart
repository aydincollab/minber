import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/app_colors.dart';
import '../../../widgets/animated_orb.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Stack(
        children: [
          // Animated Orbs
          const AnimatedOrb(
            size: 300,
            color: AppColors.gold,
            offset: Offset(-50, 100),
            duration: Duration(seconds: 4),
          ),
          const AnimatedOrb(
            size: 200,
            color: AppColors.emeraldLight,
            offset: Offset(250, 50),
            duration: Duration(seconds: 6),
          ),
          
          // Diagonal pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: DiagonalPatternPainter(),
            ),
          ),
          
          // Header row
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '🕌',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                        children: [
                          TextSpan(text: 'min'),
                          TextSpan(
                            text: 'ber',
                            style: TextStyle(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Icon buttons
                Row(
                  children: [
                    _buildIconButton(Icons.notifications_outlined),
                    const SizedBox(width: 12),
                    _buildIconButton(Icons.settings_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.textLight.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}

class DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withOpacity(0.07)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
