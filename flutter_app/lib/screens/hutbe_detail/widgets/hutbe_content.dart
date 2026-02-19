import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';
import '../../../services/tts_service.dart';

/// Tinder-style swipeable paragraph card reader for hutbe content.
class HutbeContent extends StatefulWidget {
  final Hutbe hutbe;
  final int? currentReadingParagraph;

  const HutbeContent({
    super.key,
    required this.hutbe,
    this.currentReadingParagraph,
  });

  @override
  State<HutbeContent> createState() => _HutbeContentState();
}

class _HutbeContentState extends State<HutbeContent> {
  late final PageController _pageController;
  late final List<String> _paragraphs;
  int _currentPage = 0;
  final TtsService _ttsService = TtsService();
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _paragraphs = widget.hutbe.content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    _pageController = PageController();
    _ttsService.addListener(_onTtsUpdate);
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsUpdate);
    _pageController.dispose();
    super.dispose();
  }

  void _onTtsUpdate() {
    if (!_ttsService.isPlaying) return;
    final idx = _ttsService.getCurrentParagraphIndex(_paragraphs);
    if (idx >= 0 && idx != _currentPage && mounted) {
      _goToPage(idx, animate: true);
    }
  }

  void _goToPage(int index, {bool animate = false}) {
    if (index < 0 || index >= _paragraphs.length) return;
    setState(() => _currentPage = index);
    if (animate) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.gold),
              title: const Text(
                'Bu paragrafı paylaş',
                style: TextStyle(color: AppColors.textLight),
              ),
              subtitle: const Text(
                'Görsel kart olarak paylaş (WhatsApp, Instagram...)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareCurrentCard();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Capture current paragraph as styled image and share it.
  Future<void> _shareCurrentCard() async {
    if (_paragraphs.isEmpty) return;
    final paragraph = _paragraphs[_currentPage];
    final title = widget.hutbe.title;

    final Uint8List? imageBytes =
        await _screenshotController.captureFromLongWidget(
      Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F291E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                paragraph,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  height: 1.9,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF2D5A3D), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Text(
                    'Minber — Diyanet',
                    style: TextStyle(color: Color(0xFF6B8F71), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      pixelRatio: 3.0,
    );

    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hutbe_paylasim.png');
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '"$paragraph"\n\n— $title\n#Minber #Hutbe #Diyanet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Meta header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.gold),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.hutbe.date),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
              if (widget.hutbe.readingTimeMinutes != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.menu_book_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${widget.hutbe.readingTimeMinutes} dk',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ],
              const Spacer(),
              if (widget.hutbe.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.hutbe.category!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Divider(color: AppColors.textMuted, height: 1, thickness: 0.4),

        // ── Paragraph card area ──────────────────────────────────────
        if (_paragraphs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'İçerik yükleniyor...',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: screenH * 0.58,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _paragraphs.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final isActive = index == _currentPage;
                    return GestureDetector(
                      onLongPress: () => _showShareMenu(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.fromLTRB(
                            20, 16, 20, isActive ? 4 : 16),
                        decoration: BoxDecoration(
                          color: AppColors.darkMid,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppColors.gold.withOpacity(0.45)
                                : AppColors.textMuted.withOpacity(0.12),
                            width: isActive ? 1.5 : 0.8,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _paragraphs[index],
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 18,
                                  height: 1.9,
                                  color: AppColors.textLight,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Long press hint on first card
                              if (index == 0)
                                const Text(
                                  '• Uzun basarak paragrafı paylaş',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Navigation controls ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ← prev
                    _NavButton(
                      icon: Icons.arrow_back_ios_rounded,
                      enabled: _currentPage > 0,
                      onTap: () => _goToPage(_currentPage - 1),
                    ),

                    // progress counter
                    Column(
                      children: [
                        Text(
                          '${_currentPage + 1} / ${_paragraphs.length}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 120,
                          child: LinearProgressIndicator(
                            value: _paragraphs.length > 1
                                ? _currentPage /
                                    (_paragraphs.length - 1)
                                : 1.0,
                            backgroundColor:
                                AppColors.textMuted.withOpacity(0.2),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    AppColors.gold),
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),

                    // → next
                    _NavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      enabled: _currentPage < _paragraphs.length - 1,
                      onTap: () => _goToPage(_currentPage + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // ── Source info ──────────────────────────────────────────────
        if (widget.hutbe.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, color: AppColors.gold, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kaynak: Diyanet İşleri Başkanlığı',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
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
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.gold.withOpacity(0.15)
              : AppColors.textMuted.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.gold.withOpacity(0.5)
                : AppColors.textMuted.withOpacity(0.1),
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.gold
              : AppColors.textMuted.withOpacity(0.3),
        ),
      ),
    );
  }
}
