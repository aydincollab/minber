import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HutbeListScreen extends StatelessWidget {
  const HutbeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Tüm Hutbeler'),
      ),
      body: const Center(
        child: Text(
          'Hutbeler Listesi',
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }
}
