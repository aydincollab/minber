import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/hutbe.dart';
import '../../services/favorites_service.dart';
import '../hutbe_detail/hutbe_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  String _sortBy = 'date'; // 'date' or 'saved'

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _favoritesService.refresh();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _sortFavorites() {
    setState(() {
      if (_sortBy == 'date') {
        _favoritesService.sortByDate(ascending: false);
      } else {
        _favoritesService.sortBySavedDate(ascending: false);
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sıralama',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text(
                  'Hutbe Tarihine Göre',
                  style: TextStyle(color: AppColors.textLight),
                ),
                trailing: _sortBy == 'date'
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'date';
                  });
                  _sortFavorites();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text(
                  'Kaydetme Tarihine Göre',
                  style: TextStyle(color: AppColors.textLight),
                ),
                trailing: _sortBy == 'saved'
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'saved';
                  });
                  _sortFavorites();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Favorilerim'),
        actions: [
          if (_favoritesService.favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
        ],
      ),
      body: _favoritesService.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            )
          : _favoritesService.favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz favori hutbeniz yok',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Beğendiğiniz hutbeleri favorilere ekleyerek\nburadan kolayca erişebilirsiniz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _favoritesService.refresh();
      },
      color: AppColors.gold,
      backgroundColor: AppColors.darkMid,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _favoritesService.favorites.length,
        itemBuilder: (context, index) {
          final hutbe = _favoritesService.favorites[index];
          return _buildDismissibleHutbeItem(hutbe, index);
        },
      ),
    );
  }

  Widget _buildDismissibleHutbeItem(Hutbe hutbe, int index) {
    return Dismissible(
      key: Key(hutbe.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.darkMid,
              title: const Text(
                'Favorilerden Çıkar',
                style: TextStyle(color: AppColors.textLight),
              ),
              content: const Text(
                'Bu hutbeyi favorilerden çıkarmak istediğinize emin misiniz?',
                style: TextStyle(color: AppColors.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Çıkar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _favoritesService.removeFavorite(hutbe.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Favorilerden çıkarıldı'),
              backgroundColor: AppColors.emerald,
              action: SnackBarAction(
                label: 'Geri Al',
                textColor: AppColors.gold,
                onPressed: () {
                  _favoritesService.toggleFavorite(hutbe);
                },
              ),
            ),
          );
        }
      },
      child: _buildHutbeItem(hutbe, index),
    );
  }

  Widget _buildHutbeItem(Hutbe hutbe, int index) {
    final colors = [
      AppColors.emerald,
      AppColors.gold,
      AppColors.emeraldMid,
      const Color(0xFF8B6914),
      AppColors.emeraldLight,
    ];

    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HutbeDetailScreen(hutbeId: hutbe.id),
          ),
        );
      },
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
                    maxLines: 2,
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

            // Favorite indicator
            const Icon(
              Icons.favorite,
              color: Colors.red,
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
