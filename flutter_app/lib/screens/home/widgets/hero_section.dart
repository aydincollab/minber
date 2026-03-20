import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/app_colors.dart';
import '../../../widgets/animated_orb.dart';
import '../../qibla/qibla_screen.dart';

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
                // Kıble button
                const QiblaButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular button that opens the Qibla compass screen.
class QiblaButton extends StatelessWidget {
  const QiblaButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QiblaScreen()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kıble',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
