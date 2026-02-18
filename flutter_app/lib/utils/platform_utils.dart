import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PlatformUtils {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Show platform-aware alert dialog
  static Future<bool?> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Tamam',
    String? cancelText,
  }) async {
    if (isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDefaultAction: true,
              child: Text(confirmText),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
  }

  /// Show platform-aware action sheet
  static Future<int?> showActionSheet(
    BuildContext context, {
    required String title,
    String? message,
    required List<String> actions,
    String? cancelText = 'İptal',
  }) async {
    if (isIOS) {
      return showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          message: message != null ? Text(message) : null,
          actions: List.generate(
            actions.length,
            (index) => CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(index),
              child: Text(actions[index]),
            ),
          ),
          cancelButton: cancelText != null
              ? CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(),
                  isDestructiveAction: true,
                  child: Text(cancelText),
                )
              : null,
        ),
      );
    } else {
      return showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ...List.generate(
                actions.length,
                (index) => ListTile(
                  title: Text(actions[index]),
                  onTap: () => Navigator.of(context).pop(index),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Show platform-aware loading indicator
  static Widget loadingIndicator({Color? color}) {
    if (isIOS) {
      return CupertinoActivityIndicator(color: color);
    } else {
      return CircularProgressIndicator(color: color);
    }
  }

  /// Show platform-aware switch
  static Widget switchWidget({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }
}
