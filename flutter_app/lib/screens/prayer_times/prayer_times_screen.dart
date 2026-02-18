import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Namaz Vakitleri'),
      ),
      body: const Center(
        child: Text(
          'Namaz Vakitleri Ekranı',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
