import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onSearch;

  const SearchBarWidget({super.key, this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onSubmitted: onSearch,
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          hintText: 'Hutbe, konu veya yıl ara...',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}
