import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';

class HutbeContent extends StatelessWidget {
  final Hutbe hutbe;
  final int? currentReadingParagraph;

  const HutbeContent({
    super.key,
    required this.hutbe,
    this.currentReadingParagraph,
  });

  @override
  Widget build(BuildContext context) {
    // Split content into paragraphs — handles both \n and \n\n separators
    final paragraphs = hutbe.content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta information
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and reading time
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(hutbe.date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  if (hutbe.readingTimeMinutes != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.menu_book_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${hutbe.readingTimeMinutes} dk',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Category badge
              if (hutbe.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hutbe.category!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Divider(
          color: AppColors.textMuted,
          height: 1,
          thickness: 0.5,
        ),
        const SizedBox(height: 4),

        // Content — all paragraphs use the same uniform style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraphs.asMap().entries.map((entry) {
              final index = entry.key;
              final paragraph = entry.value;
              final isHighlighted = currentReadingParagraph == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: isHighlighted
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _paragraph(paragraph),
                      )
                    : _paragraph(paragraph),
              );
            }).toList(),
          ),
        ),

        // Source info
        if (hutbe.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, color: AppColors.gold, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kaynak: Diyanet İşleri Başkanlığı',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Amiri',
        fontSize: 17,
        height: 1.85,
        color: AppColors.textLight,
        letterSpacing: 0.1,
      ),
    );
  }
}
