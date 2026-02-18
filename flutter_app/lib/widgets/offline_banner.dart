import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isVisible;

  const OfflineBanner({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isVisible ? 40 : 0,
      child: isVisible
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Çevrimdışı mod — kaydedilen hutbeler gösteriliyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
