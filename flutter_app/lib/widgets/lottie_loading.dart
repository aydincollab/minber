import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoading extends StatelessWidget {
  final double size;
  final String? text;

  const LottieLoading({
    super.key,
    this.size = 100,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/animations/loading.json',
              fit: BoxFit.contain,
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
