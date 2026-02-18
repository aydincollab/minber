import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/hutbe.dart';

class HutbeDetailScreen extends StatelessWidget {
  final String hutbeId;

  const HutbeDetailScreen({super.key, required this.hutbeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Hutbe Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Add to favorites
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share
            },
          ),
        ],
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }
}
