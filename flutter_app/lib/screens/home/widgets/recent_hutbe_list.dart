import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';

class RecentHutbeList extends StatelessWidget {
  final List<HutbeListItem> hutbeler;
  final Function(String)? onHutbeTap;

  const RecentHutbeList({
    super.key,
    required this.hutbeler,
    this.onHutbeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hutbeler.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: hutbeler.length,
      itemBuilder: (context, index) {
        final hutbe = hutbeler[index];
        return _buildHutbeItem(hutbe, index);
      },
    );
  }

  Widget _buildHutbeItem(HutbeListItem hutbe, int index) {
    final colors = [
      AppColors.emerald,
      AppColors.gold,
      AppColors.emeraldMid,
      const Color(0xFF8B6914),
      AppColors.emeraldLight,
    ];

    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => onHutbeTap?.call(hutbe.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getIconForCategory(hutbe.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hutbe.title,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy', 'tr_TR').format(hutbe.date),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '• ${hutbe.readingTimeMinutes ?? 5} dk',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'iman':
        return '✨';
      case 'aile':
        return '👨‍👩‍👧‍👦';
      case 'ahlak':
        return '💎';
      case 'ibadet':
        return '🤲';
      case 'toplum':
        return '🤝';
      case 'oruç':
        return '🌙';
      case 'hac':
        return '🕋';
      default:
        return '📖';
    }
  }
}
