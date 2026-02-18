import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Platform-aware utilities for iOS/Android compatibility
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Show a platform-adaptive dialog
  static Future<bool?> showAdaptiveDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Tamam',
    String cancelText = 'İptal',
    bool isDestructive = false,
  }) async {
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            content,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmText,
                style: TextStyle(
                  color: isDestructive ? Colors.red : AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Show a platform-adaptive action sheet / bottom sheet
  static Future<T?> showAdaptiveActionSheet<T>({
    required BuildContext context,
    required String title,
    required List<_AdaptiveAction<T>> actions,
    String cancelText = 'İptal',
  }) async {
    if (isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          actions: actions
              .map((action) => CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context, action.value),
                    isDestructiveAction: action.isDestructive,
                    child: Text(action.label),
                  ))
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...actions.map((action) => ListTile(
                      leading: action.icon != null
                          ? Icon(action.icon,
                              color: action.isDestructive
                                  ? Colors.red
                                  : AppColors.gold)
                          : null,
                      title: Text(
                        action.label,
                        style: TextStyle(
                          color: action.isDestructive
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, action.value),
                    )),
              ],
            ),
          );
        },
      );
    }
  }
}

/// Represents an action for adaptive action sheets
class _AdaptiveAction<T> {
  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;

  const _AdaptiveAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });
}
