import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../theme/app_colors.dart';
import '../../models/hutbe.dart';
import '../../services/api_service.dart';
import '../../services/tts_service.dart';
import '../../services/favorites_service.dart';
import '../../services/share_service.dart';
import '../../services/local_database.dart';
import '../../widgets/favorite_button.dart';
import 'widgets/hutbe_content.dart';
import 'widgets/reading_progress.dart';
import 'widgets/tts_mini_player.dart';

class HutbeDetailScreen extends StatefulWidget {
  final String hutbeId;

  const HutbeDetailScreen({super.key, required this.hutbeId});

  @override
  State<HutbeDetailScreen> createState() => _HutbeDetailScreenState();
}

class _HutbeDetailScreenState extends State<HutbeDetailScreen> {
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  final FavoritesService _favoritesService = FavoritesService();
  final ShareService _shareService = ShareService();
  final LocalDatabase _localDb = LocalDatabase();
  final ScrollController _scrollController = ScrollController();

  Hutbe? _hutbe;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isSaved = false;
  double _scrollProgress = 0.0;
  int? _currentReadingParagraph;

  @override
  void initState() {
    super.initState();
    _loadHutbe();
    _scrollController.addListener(_onScroll);
    _ttsService.addListener(_onTtsUpdate);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ttsService.removeListener(_onTtsUpdate);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll) : 0.0;
      });

      // Save reading progress
      if (_hutbe != null && maxScroll > 0) {
        _localDb.updateReadingProgress(widget.hutbeId, _scrollProgress);
      }
    }
  }

  void _onTtsUpdate() {
    if (_hutbe != null && _ttsService.isPlaying) {
      final paragraphs = _hutbe!.content
          .split('\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
      final currentParagraph = _ttsService.getCurrentParagraphIndex(paragraphs);
      
      if (currentParagraph != _currentReadingParagraph) {
        setState(() {
          _currentReadingParagraph = currentParagraph;
        });
      }
    }
  }

  Future<void> _loadHutbe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to load from local database first
      Hutbe? localHutbe = await _localDb.getHutbeById(widget.hutbeId);
      
      if (localHutbe != null) {
        setState(() {
          _hutbe = localHutbe;
          _isLoading = false;
        });
      }

      // Try to load from API
      try {
        final apiHutbe = await _apiService.getHutbeById(widget.hutbeId);
        setState(() {
          _hutbe = apiHutbe;
          _isLoading = false;
        });
      } catch (e) {
        // If API fails and we have local data, keep using it
        if (localHutbe == null) {
          rethrow;
        }
      }

      // Check favorite status
      if (_hutbe != null) {
        final isFav = await _favoritesService.isFavorite(widget.hutbeId);
        final isSaved = await _localDb.isHutbeSaved(widget.hutbeId);
        setState(() {
          _isFavorite = isFav;
          _isSaved = isSaved;
        });

        // Load saved reading progress
        final progress = await _localDb.getReadingProgress(widget.hutbeId);
        if (progress > 0 && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_scrollController.hasClients) {
              final maxScroll = _scrollController.position.maxScrollExtent;
              _scrollController.jumpTo(maxScroll * progress);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading hutbe: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_hutbe == null) return;

    await _favoritesService.toggleFavorite(_hutbe!);
    final isFav = await _favoritesService.isFavorite(widget.hutbeId);
    setState(() {
      _isFavorite = isFav;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveForOffline() async {
    if (_hutbe == null) return;

    if (_isSaved) {
      await _localDb.removeHutbe(widget.hutbeId);
      setState(() {
        _isSaved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kaydedilmiş hutbe kaldırıldı'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } else {
      await _localDb.saveHutbe(_hutbe!);
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hutbe çevrimdışı okuma için kaydedildi'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  void _startTts() {
    if (_hutbe == null) return;
    
    if (_ttsService.isPlaying) {
      _ttsService.pause();
    } else if (_ttsService.isPaused) {
      _ttsService.resume();
    } else {
      _ttsService.speak(_hutbe!.content);
    }
  }

  void _shareHutbe() {
    if (_hutbe == null) return;
    _shareService.shareHutbe(_hutbe!);
  }

  void _copyContent() {
    if (_hutbe == null) return;
    Clipboard.setData(ClipboardData(text: _hutbe!.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hutbe içeriği kopyalandı'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar with parallax effect
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.darkMid,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.dark.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Favorite button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FavoriteButton(
                      isFavorite: _isFavorite,
                      onTap: _toggleFavorite,
                      size: 24,
                      activeColor: Colors.red,
                    ),
                  ),
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareHutbe,
                  ),
                  // TTS button
                  IconButton(
                    icon: Icon(
                      _ttsService.isPlaying ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                    onPressed: _startTts,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.heroGradient,
                        ),
                      ),
                      
                      // Pattern overlay
                      Opacity(
                        opacity: 0.1,
                        child: CustomPaint(
                          painter: _PatternPainter(),
                        ),
                      ),

                      // Title overlay
                      if (_hutbe != null)
                        Positioned(
                          bottom: 60,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Text(
                              _hutbe!.title,
                              style: const TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                    ),
                  ),
                )
              else if (_hutbe != null)
                SliverToBoxAdapter(
                  child: HutbeContent(
                    hutbe: _hutbe!,
                    currentReadingParagraph: _currentReadingParagraph,
                  ),
                )
              else
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Hutbe yüklenemedi',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),

          // Reading progress bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ReadingProgress(progress: _scrollProgress),
            ),
          ),

          // Bottom actions bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.darkMid.withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: AppColors.textMuted.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                        label: 'Favori',
                        onTap: _toggleFavorite,
                        isActive: _isFavorite,
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Paylaş',
                        onTap: _shareHutbe,
                      ),
                      _buildActionButton(
                        icon: _ttsService.isPlaying ? Icons.pause : Icons.volume_up,
                        label: 'Sesli',
                        onTap: _startTts,
                        isActive: _ttsService.isPlaying,
                      ),
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Kopyala',
                        onTap: _copyContent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // TTS Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: TtsMiniPlayer(
              ttsService: _ttsService,
              onClose: () {
                _ttsService.stop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.gold : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.gold : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 10, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
