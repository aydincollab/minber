import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../models/hutbe.dart';
import '../../../services/tts_service.dart';

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

class _HutbeContentState extends State<HutbeContent>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final List<String> _paragraphs;
  int _currentPage = 0;
  final TtsService _ttsService = TtsService();
  final ScreenshotController _screenshotController = ScreenshotController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _paragraphs = _parseParagraphs(widget.hutbe.content);
    _pageController = PageController();
    _ttsService.addListener(_onTtsUpdate);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ttsService.removeListener(_onTtsUpdate);
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Split content into clean paragraphs, filtering out date/metadata lines.
  List<String> _parseParagraphs(String content) {
    final dateRe = RegExp(r'^\d{2}[.\-/]\d{2}[.\-/]\d{4}$');
    return content
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) =>
            p.isNotEmpty &&
            !p.startsWith('Tarih:') &&
            !p.startsWith('tarih:') &&
            !dateRe.hasMatch(p))
        .toList();
  }

  void _onTtsUpdate() {
    if (!mounted) return;
    final idx = _ttsService.currentParagraphIndex;
    if (idx >= 0 && idx < _paragraphs.length && idx != _currentPage) {
      _goToPage(idx, animate: true);
    }
    setState(() {});
  }

  void _goToPage(int index, {bool animate = false}) {
    if (index < 0 || index >= _paragraphs.length) return;
    setState(() => _currentPage = index);
    if (animate) {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // If TTS is active, jump to the new paragraph
    if (_ttsService.isPlaying || _ttsService.isPaused) {
      _ttsService.jumpTo(index);
    }
  }

  /// Adaptive font size based on paragraph length.
  double _fontSize(String text) {
    final len = text.length;
    if (len < 150) return 22;
    if (len < 300) return 19;
    if (len < 500) return 17;
    return 15;
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image_outlined, color: AppColors.gold),
              ),
              title: const Text('Görsel kart olarak paylaş',
                  style: TextStyle(
                      color: AppColors.textLight, fontWeight: FontWeight.w600)),
              subtitle: const Text('WhatsApp, Instagram, Twitter...',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareCurrentCard();
              },
            ),
          ],
        ),
      ),
    );
  }

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
            color: const Color(0xFF0A1F14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 28, height: 3,
                      decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('❝',
                      style:
                          TextStyle(color: AppColors.gold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 16),
              Text(paragraph,
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: _fontSize(paragraph),
                      height: 1.85,
                      color: Colors.white)),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1D4A2A), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const Text('Minber — Diyanet',
                      style:
                          TextStyle(color: Color(0xFF5A8F6A), fontSize: 11)),
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
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Compact meta row ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.gold),
              const SizedBox(width: 5),
              Text(
                DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.hutbe.date),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              if (widget.hutbe.readingTimeMinutes != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.menu_book_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${widget.hutbe.readingTimeMinutes} dk',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
              const Spacer(),
              if (widget.hutbe.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    widget.hutbe.category!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Progress bar (thin golden line) ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _paragraphs.isEmpty
                  ? 0
                  : (_currentPage + 1) / _paragraphs.length,
              minHeight: 2,
              backgroundColor: AppColors.textMuted.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // ── Card counter ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentPage + 1} / ${_paragraphs.length}',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
              if (_ttsService.isPlaying)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Row(
                    children: [
                      Icon(Icons.volume_up_rounded,
                          size: 13,
                          color: AppColors.gold.withOpacity(
                              0.5 + 0.5 * _pulseController.value)),
                      const SizedBox(width: 4),
                      Text('Sesli okuma',
                          style: TextStyle(
                              color: AppColors.gold.withOpacity(
                                  0.5 + 0.5 * _pulseController.value),
                              fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Paragraph cards ──────────────────────────────────────────
        if (_paragraphs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('İçerik yükleniyor...',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          SizedBox(
            height: size.height * 0.60,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _paragraphs.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final isActive = index == _currentPage;
                final isTtsActive =
                    _ttsService.isPlaying &&
                    _ttsService.currentParagraphIndex == index;
                final text = _paragraphs[index];
                final fs = _fontSize(text);

                return GestureDetector(
                  onLongPress: _showShareMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.fromLTRB(
                        20, 0, 20, isActive ? 0 : 12),
                    decoration: BoxDecoration(
                      // Subtle radial gradient background
                      gradient: RadialGradient(
                        center: const Alignment(-0.6, -0.6),
                        radius: 1.4,
                        colors: [
                          const Color(0xFF1A3A26),
                          const Color(0xFF0D1F16),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isTtsActive
                            ? AppColors.gold
                            : isActive
                                ? AppColors.gold.withOpacity(0.35)
                                : AppColors.textMuted.withOpacity(0.08),
                        width: isTtsActive ? 1.5 : isActive ? 1.0 : 0.6,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(
                                    isTtsActive ? 0.15 : 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        // Decorative quote mark top-left
                        Positioned(
                          top: 16,
                          left: 20,
                          child: Text('❝',
                              style: TextStyle(
                                  color: AppColors.gold.withOpacity(0.25),
                                  fontSize: 48,
                                  height: 1)),
                        ),

                        // Decorative bottom-right flourish
                        Positioned(
                          bottom: 16,
                          right: 20,
                          child: Text('❞',
                              style: TextStyle(
                                  color: AppColors.gold.withOpacity(0.15),
                                  fontSize: 36,
                                  height: 1)),
                        ),

                        // Main text — fills card, no scrolling
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 52, 24, 52),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: size.width - 88,
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: fs,
                                    height: 1.85,
                                    color: Colors.white.withOpacity(0.93),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // TTS active indicator strip at bottom
                        if (isTtsActive)
                          Positioned(
                            bottom: 0,
                            left: 24,
                            right: 24,
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(colors: [
                                  Colors.transparent,
                                  AppColors.gold,
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // ── Navigation arrows ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_rounded,
                enabled: _currentPage > 0,
                onTap: () => _goToPage(_currentPage - 1),
              ),
              // Dot indicators (max 7 visible)
              _DotIndicator(
                count: _paragraphs.length,
                current: _currentPage,
              ),
              _NavButton(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: _currentPage < _paragraphs.length - 1,
                onTap: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ),

        // ── Share hint on first visit ─────────────────────────────────
        // (only shown on last card as a subtle tip)
        if (_currentPage == _paragraphs.length - 1 && _paragraphs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Center(
              child: Text(
                '✦  Herhangi bir kartı uzun basılı tutarak paylaşabilirsin  ✦',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

        if (widget.hutbe.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.08)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, color: AppColors.gold, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kaynak: Diyanet İşleri Başkanlığı',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 120),
      ],
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.gold.withOpacity(0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.gold.withOpacity(0.45)
                : AppColors.textMuted.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled
                ? AppColors.gold
                : AppColors.textMuted.withOpacity(0.25)),
      ),
    );
  }
}

// ── Dot indicator (max 7) ─────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    const maxDots = 7;
    if (count <= 0) return const SizedBox.shrink();

    // Compute visible range centered around current
    int start = 0;
    if (count > maxDots) {
      start = (current - maxDots ~/ 2).clamp(0, count - maxDots);
    }
    final end = (start + maxDots).clamp(0, count);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(end - start, (i) {
        final idx = start + i;
        final isActive = idx == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold
                : AppColors.textMuted.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
