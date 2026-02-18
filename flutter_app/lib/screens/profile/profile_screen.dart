import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Profil'),
      ),
      body: const Center(
        child: Text(
          'Profil & Ayarlar',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
