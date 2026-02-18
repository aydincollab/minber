import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_colors.dart';
import '../../models/hutbe.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_database.dart';
import '../../widgets/offline_banner.dart';
import '../hutbe_detail/hutbe_detail_screen.dart';

class HutbeListScreen extends StatefulWidget {
  const HutbeListScreen({super.key});

  @override
  State<HutbeListScreen> createState() => _HutbeListScreenState();
}

class _HutbeListScreenState extends State<HutbeListScreen> {
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalDatabase _localDb = LocalDatabase();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<HutbeListItem> _hutbeler = [];
  List<Hutbe> _offlineHutbeler = [];
  List<String> _categories = ['Tümü', 'İman', 'Aile', 'Ahlak', 'İbadet', 'Toplum'];
  List<int> _years = [];
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _selectedCategory = 'Tümü';
  int? _selectedYear;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _connectivityService.addListener(_onConnectivityChanged);
    _loadYears();
    _loadHutbeler();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {});
      if (_connectivityService.isOnline) {
        _refresh();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _connectivityService.isOnline) {
      _loadMore();
    }
  }

  Future<void> _loadYears() async {
    try {
      final stats = await _apiService.getYearsStats();
      setState(() {
        _years = stats.map((s) => s['year'] as int).toList();
        _years.sort((a, b) => b.compareTo(a));
      });
    } catch (e) {
      debugPrint('Error loading years: $e');
    }
  }

  Future<void> _loadHutbeler() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      if (_connectivityService.isOnline) {
        final hutbeler = await _apiService.getHutbeler(
          page: _currentPage,
          pageSize: 20,
          year: _selectedYear,
          category: _selectedCategory != 'Tümü' ? _selectedCategory : null,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        setState(() {
          _hutbeler = hutbeler;
          _isLoading = false;
          _hasMore = hutbeler.length >= 20;
        });
      } else {
        // Load offline hutbeler
        final savedHutbeler = await _localDb.getSavedHutbes();
        setState(() {
          _offlineHutbeler = savedHutbeler;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hutbeler: $e');
      // Try loading offline hutbeler as fallback
      try {
        final savedHutbeler = await _localDb.getSavedHutbes();
        setState(() {
          _offlineHutbeler = savedHutbeler;
          _isLoading = false;
        });
      } catch (e2) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreHutbeler = await _apiService.getHutbeler(
        page: _currentPage + 1,
        pageSize: 20,
        year: _selectedYear,
        category: _selectedCategory != 'Tümü' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _hutbeler.addAll(moreHutbeler);
        _currentPage++;
        _isLoadingMore = false;
        _hasMore = moreHutbeler.length >= 20;
      });
    } catch (e) {
      debugPrint('Error loading more: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadHutbeler();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadHutbeler();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadHutbeler();
  }

  void _onYearSelected(int? year) {
    setState(() {
      _selectedYear = year;
    });
    _loadHutbeler();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = _connectivityService.isOffline;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Column(
        children: [
          // Offline banner
          OfflineBanner(isVisible: isOffline),

          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'Hutbe ara...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkMid,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearch,
            ),
          ),

          // Category tags
          if (!isOffline)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) => _onCategorySelected(category),
                      backgroundColor: AppColors.darkMid,
                      selectedColor: AppColors.gold,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.dark : AppColors.textLight,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.gold : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Year selector
          if (!isOffline && _years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Yıl: ',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.darkMid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.textMuted.withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButton<int?>(
                        value: _selectedYear,
                        isExpanded: true,
                        dropdownColor: AppColors.darkMid,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        style: const TextStyle(color: AppColors.textLight),
                        hint: const Text(
                          'Tüm Yıllar',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tüm Yıllar'),
                          ),
                          ..._years.map((year) {
                            return DropdownMenuItem<int?>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                        ],
                        onChanged: _onYearSelected,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Hutbe list
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : isOffline
                    ? _buildOfflineList()
                    : _buildOnlineList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineList() {
    if (_hutbeler.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.gold,
      backgroundColor: AppColors.darkMid,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _hutbeler.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _hutbeler.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                ),
              ),
            );
          }

          final hutbe = _hutbeler[index];
          return _buildHutbeItem(hutbe, index);
        },
      ),
    );
  }

  Widget _buildOfflineList() {
    if (_offlineHutbeler.isEmpty) {
      return _buildEmptyState(isOffline: true);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _offlineHutbeler.length,
      itemBuilder: (context, index) {
        final hutbe = _offlineHutbeler[index];
        return _buildOfflineHutbeItem(hutbe, index);
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
        ),
        child: Row(
          children: [
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

  Widget _buildOfflineHutbeItem(Hutbe hutbe, int index) {
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
        ),
        child: Row(
          children: [
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
                      const Icon(
                        Icons.download_done,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
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

  Widget _buildEmptyState({bool isOffline = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOffline ? Icons.cloud_off : Icons.search_off,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isOffline ? 'Çevrimdışı Mod' : 'Hutbe Bulunamadı',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isOffline
                  ? 'Çevrimdışı okumak için hutbeleri kaydetmelisiniz'
                  : 'Arama kriterlerinize uygun hutbe bulunamadı',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.darkMid,
          highlightColor: AppColors.textMuted.withOpacity(0.1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkMid,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
