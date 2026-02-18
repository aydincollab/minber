import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Kaydedilenler'),
      ),
      body: const Center(
        child: Text(
          'Kaydedilen Hutbeler',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
