import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isNetworkError;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.isNetworkError = false,
  });

  factory ErrorScreen.noInternet({VoidCallback? onRetry}) {
    return ErrorScreen(
      title: 'İnternet Bağlantısı Yok',
      message: 'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
      onRetry: onRetry,
      isNetworkError: true,
    );
  }

  factory ErrorScreen.serverError({VoidCallback? onRetry}) {
    return ErrorScreen(
      title: 'Sunucu Hatası',
      message: 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
      onRetry: onRetry,
      isNetworkError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                isNetworkError
                    ? 'assets/animations/no_internet.json'
                    : 'assets/animations/empty_state.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isDark ? AppColors.textLight : AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textDarkMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.dark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
