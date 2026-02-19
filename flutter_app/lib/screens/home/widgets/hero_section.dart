import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/app_colors.dart';
import '../../../widgets/animated_orb.dart';
import '../../../services/notification_service.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  
  const HeroSection({
    super.key,
    this.onNotificationsTap,
  });

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
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('⏱', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                            'Sıradaki Vakit', // Placeholder until logic restored
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Ezan notification bell
                const EzanBellButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// A bell button that toggles ezan push notifications on/off.
class EzanBellButton extends StatefulWidget {
  const EzanBellButton({super.key});

  @override
  State<EzanBellButton> createState() => _EzanBellButtonState();
}

class _EzanBellButtonState extends State<EzanBellButton> {
  final _notificationService = NotificationService();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _notificationService.isEnabled();
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _toggle() async {
    if (!_enabled) {
      // Request permission first
      await _notificationService.initialize();
      await _notificationService.requestPermission();
    }
    await _notificationService.setEnabled(!_enabled);
    setState(() => _enabled = !_enabled);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _enabled
              ? '🔔 Ezan bildirimleri açıldı'
              : '🔕 Ezan bildirimleri kapatıldı',
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _enabled
              ? AppColors.gold.withOpacity(0.25)
              : AppColors.textLight.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: _enabled
                ? AppColors.gold.withOpacity(0.7)
                : AppColors.textMuted.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: _enabled
              ? [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              _enabled ? Icons.notifications_active : Icons.notifications_outlined,
              size: 20,
              color: _enabled ? AppColors.gold : AppColors.textLight,
            ),
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
