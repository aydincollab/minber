import 'package:flutter/material.dart';
import 'lottie_empty_state.dart';

class NoResults extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onActionPressed;
  final String? actionText;

  const NoResults({
    super.key,
    this.title = 'Hutbe Bulunamadı',
    this.description,
    this.onActionPressed,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return LottieEmptyState(
      animationPath: 'assets/animations/empty_state.json',
      title: title,
      description: description ?? 'Aradığınız kriterlere uygun hutbe bulunamadı.',
      onActionPressed: onActionPressed,
      actionText: actionText,
    );
  }
}
