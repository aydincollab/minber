import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';

class FeaturedHutbeCard extends StatelessWidget {
  final Hutbe? hutbe;
  final VoidCallback? onTap;

  const FeaturedHutbeCard({
    super.key,
    this.hutbe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hutbe == null) {
      return _buildPlaceholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 200,
          decoration: BoxDecoration(
            gradient: AppColors.featuredCardGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Mosque emoji background
              const Positioned(
                right: 20,
                bottom: 20,
                child: Text(
                  '🕌',
                  style: TextStyle(
                    fontSize: 100,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).withOpacity(0.08),
              
              // Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✦', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 6),
                      Text(
                        'GÜNCEL',
                        style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meta info
                      Row(
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy', 'tr_TR').format(hutbe!.date),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '• ${hutbe!.readingTimeMinutes ?? 5} dk okuma',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Text(
                        hutbe!.title,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.darkMid.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }
}

extension OpacityExtension on Widget {
  Widget withOpacity(double opacity) {
    return Opacity(
      opacity: opacity,
      child: this,
    );
  }
}
