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
    // Split content into paragraphs
    final paragraphs = hutbe.content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta information
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and reading time
              Row(
                children: [
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(hutbe.date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  if (hutbe.readingTimeMinutes != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '• ${hutbe.readingTimeMinutes} dk okuma',
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

        const Divider(
          color: AppColors.textMuted,
          height: 1,
          thickness: 0.5,
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: paragraphs.asMap().entries.map((entry) {
              final index = entry.key;
              final paragraph = entry.value;
              final isFirstParagraph = index == 0;
              final isHighlighted = currentReadingParagraph == index;
              final isQuote = _isQuote(paragraph);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildParagraph(
                  paragraph,
                  isFirstParagraph: isFirstParagraph,
                  isHighlighted: isHighlighted,
                  isQuote: isQuote,
                ),
              );
            }).toList(),
          ),
        ),

        // Source info
        if (hutbe.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
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

        const SizedBox(height: 100), // Space for bottom actions bar
      ],
    );
  }

  Widget _buildParagraph(
    String text, {
    required bool isFirstParagraph,
    required bool isHighlighted,
    required bool isQuote,
  }) {
    if (isQuote) {
      return Container(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.08),
          border: const Border(
            left: BorderSide(
              color: AppColors.gold,
              width: 3,
            ),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: AppColors.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (isHighlighted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildTextWithDropCap(text, isFirstParagraph),
      );
    }

    return _buildTextWithDropCap(text, isFirstParagraph);
  }

  Widget _buildTextWithDropCap(String text, bool isFirstParagraph) {
    if (!isFirstParagraph || text.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 16,
          height: 1.8,
          color: AppColors.textLight,
        ),
      );
    }

    // Drop cap effect for first paragraph
    final firstChar = text[0];
    final restOfText = text.substring(1);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: firstChar,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 48,
              height: 1,
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: restOfText,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              height: 1.8,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  bool _isQuote(String text) {
    // Simple heuristic: check if text contains quotes or starts with certain indicators
    return text.contains('"') ||
        text.contains('"') ||
        text.contains('"') ||
        text.toLowerCase().startsWith('allah') ||
        text.toLowerCase().startsWith('peygamber') ||
        text.toLowerCase().contains('hadis') ||
        text.toLowerCase().contains('ayet');
  }
}
