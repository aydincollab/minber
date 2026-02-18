import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Snackbar helper for consistent notifications across the app
class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar (e.g., favorite added, action completed)
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.emerald,
      iconColor: AppColors.goldLight,
    );
  }

  /// Show an info snackbar (e.g., item shared, mode changed)
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.emeraldMid,
      iconColor: AppColors.goldLight,
    );
  }

  /// Show a warning snackbar (e.g., offline mode, limited functionality)
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.goldDark,
      iconColor: AppColors.cream,
    );
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFF8B2020),
      iconColor: const Color(0xFFFFCCCC),
    );
  }

  /// Show favorite added snackbar
  static void showFavoriteAdded(BuildContext context) {
    _show(
      context,
      message: 'Favorilere eklendi ❤️',
      icon: Icons.favorite_rounded,
      backgroundColor: AppColors.emerald,
      iconColor: AppColors.gold,
    );
  }

  /// Show favorite removed snackbar
  static void showFavoriteRemoved(BuildContext context) {
    _show(
      context,
      message: 'Favorilerden çıkarıldı',
      icon: Icons.favorite_border_rounded,
      backgroundColor: AppColors.darkMid,
      iconColor: AppColors.textMuted,
    );
  }

  /// Show shared snackbar
  static void showShared(BuildContext context) {
    _show(
      context,
      message: 'Paylaşıldı 📤',
      icon: Icons.share_rounded,
      backgroundColor: AppColors.emerald,
      iconColor: AppColors.goldLight,
    );
  }

  /// Show offline mode snackbar
  static void showOfflineMode(BuildContext context) {
    _show(
      context,
      message: 'Çevrimdışı mod — Kayıtlı içerikler gösteriliyor',
      icon: Icons.wifi_off_rounded,
      backgroundColor: AppColors.goldDark,
      iconColor: AppColors.cream,
      duration: const Duration(seconds: 4),
    );
  }

  /// Internal show method
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Dismiss any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        elevation: 6,
      ),
    );
  }
}
