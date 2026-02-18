import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieEmptyState extends StatelessWidget {
  final String animationPath;
  final String title;
  final String? description;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final double animationSize;

  const LottieEmptyState({
    super.key,
    required this.animationPath,
    required this.title,
    this.description,
    this.onActionPressed,
    this.actionText,
    this.animationSize = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: animationSize,
              height: animationSize,
              child: Lottie.asset(
                animationPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
