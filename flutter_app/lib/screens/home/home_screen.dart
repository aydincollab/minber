import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import 'package:provider/provider.dart';
import '../../providers/preferences_provider.dart';
import '../../models/hutbe.dart';
import '../../models/prayer_time.dart';
import 'widgets/hero_section.dart';
import 'widgets/prayer_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/ad_banner_widget.dart';
import 'widgets/featured_hutbe_card.dart';
import 'widgets/category_tags.dart';
import 'widgets/year_slide_cards.dart';
import 'widgets/recent_hutbe_list.dart';
import '../hutbe_list/hutbe_list_screen.dart';
import '../prayer_times/prayer_times_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../hutbe_detail/hutbe_detail_screen.dart';
import '../../services/notification_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final PageController _pageController = PageController();
  
  int _currentIndex = 0;
  PrayerTimings? _prayerTimings;
  String? _city;
  Hutbe? _featuredHutbe;
  List<HutbeListItem> _recentHutbeler = [];
  List<Map<String, dynamic>> _years = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Prayer times wil be loaded in didChangeDependencies
    _loadFeaturedHutbe();
    _loadRecentHutbeler();
    _loadYearsStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final preferences = Provider.of<PreferencesProvider>(context);
    if (_city != preferences.city && preferences.city != 'Konum alınıyor...') {
      _loadPrayerTimes(targetCity: preferences.city);
    } else if (_prayerTimings == null) {
      _loadPrayerTimes();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load prayer times
    _loadPrayerTimes();
    
    // Load featured hutbe
    _loadFeaturedHutbe();
    
    // Load recent hutbeler
    _loadRecentHutbeler();
    
    // Load years stats
    _loadYearsStats();
  }

  Future<void> _loadPrayerTimes({String? targetCity}) async {
    try {
      final preferences = Provider.of<PreferencesProvider>(context, listen: false);
      final cityToUse = targetCity ?? preferences.city;
      
      if (cityToUse != 'Konum alınıyor...' && cityToUse.isNotEmpty) {
        final timings = await _apiService.getPrayerTimes(
          city: cityToUse,
          country: 'TR',
        );
        
        if (mounted) {
          setState(() {
            _prayerTimings = timings;
            _city = cityToUse;
          });
          _scheduleEzanIfEnabled(timings);
        }
        return;

      }

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final city = await _locationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        final timings = await _apiService.getPrayerTimes(
          lat: position.latitude,
          lng: position.longitude,
        );
        
        if (mounted) {
          final resolvedCity = city ?? 'Türkiye';
          setState(() {
            _prayerTimings = timings;
            _city = resolvedCity;
          });
          _scheduleEzanIfEnabled(timings);
          
          if (preferences.city == 'Konum alınıyor...') {
            preferences.setCity(resolvedCity);
          }
        }

      } else {
        // Fallback if location not available
        final timings = await _apiService.getPrayerTimes(
          city: 'İstanbul', // Default fallback better than Ankara? Or keeping Ankara. Let's keep Ankara but only if GPS fails.
          country: 'Turkey',
        );
        
        if (mounted) {
          setState(() {
            _prayerTimings = timings;
            _city = 'Ankara';
          });
          _scheduleEzanIfEnabled(timings);
          
          if (preferences.city == 'Konum alınıyor...') {
            preferences.setCity('Ankara');
          }
        }

      }
    } catch (e) {
      // Using debugPrint for better log management in production
        debugPrint('Error loading prayer times: $e');
    }
  }

  /// Schedule ezan notifications if the user has enabled them.
  Future<void> _scheduleEzanIfEnabled(PrayerTimings timings) async {
    final notifService = NotificationService();
    final enabled = await notifService.isEnabled();
    if (!enabled) return;
    await notifService.schedulePrayerNotifications({
      'Fajr':    timings.imsak,
      'Sunrise': timings.sunrise,
      'Dhuhr':   timings.dhuhr,
      'Asr':     timings.asr,
      'Maghrib': timings.maghrib,
      'Isha':    timings.isha,
    });
  }


  Future<void> _loadFeaturedHutbe() async {
    try {
      final hutbe = await _apiService.getFeaturedHutbe();
      if (mounted && hutbe != null) {
        setState(() {
          _featuredHutbe = hutbe;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured hutbe: $e');
    }
  }

  Future<void> _loadRecentHutbeler() async {
    try {
      final hutbeler = await _apiService.getLatestHutbeler(limit: 10);
      if (!mounted) return;
      
      setState(() {
        _recentHutbeler = hutbeler;
        _isLoading = false;
      });
      
      // If no featured hutbe loaded yet, use the first recent hutbe as fallback
      if (_featuredHutbe == null && hutbeler.isNotEmpty) {
        try {
          final firstHutbe = await _apiService.getHutbeById(hutbeler.first.id);
          if (mounted && _featuredHutbe == null) {
            setState(() {
              _featuredHutbe = firstHutbe;
            });
          }
        } catch (e) {
          debugPrint('Error loading fallback featured hutbe: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading recent hutbeler: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadYearsStats() async {
    try {
      final stats = await _apiService.getYearsStats();
      setState(() {
        _years = stats;
      });
    } catch (e) {
      debugPrint('Error loading years stats: $e');
    }
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Ana Sayfa
          _buildHomeTab(),
          
          // Hutbeler
          const HutbeListScreen(),
          
          // Vakitler
          const PrayerTimesScreen(),
          
          // Kaydedilen
          const FavoritesScreen(),
          
          // Profil
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.gold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Prayer Card
            Stack(
              children: [
                const HeroSection(),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 120,
                  left: 0,
                  right: 0,
                  child: PrayerCard(
                    prayerTimings: _prayerTimings,
                    city: _city,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Search Bar
            SearchBarWidget(
              onSearch: (query) {
                // Navigate to hutbe list with search
                setState(() {
                  _currentIndex = 1;
                });
                _pageController.jumpToPage(1);
              },
            ),

            // Featured Hutbe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Bu Haftanın Hutbesi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            FeaturedHutbeCard(
              hutbe: _featuredHutbe,
              onTap: () {
                if (_featuredHutbe != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HutbeDetailScreen(
                        hutbeId: _featuredHutbe!.id,
                      ),
                    ),
                  );
                }
              },
            ),
          
          const SizedBox(height: 32),
          
          // Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Kategoriler',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          CategoryTags(
            onCategorySelected: (category) {
              // Navigate to hutbe list with category filter
              setState(() {
                _currentIndex = 1;
              });
              _pageController.jumpToPage(1);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Years
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Yıllara Göre',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          YearSlideCards(
            years: _years,
            onYearTap: (year) {
              // Navigate to hutbe list with year filter
              setState(() {
                _currentIndex = 1;
              });
              _pageController.jumpToPage(1);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Recent Hutbeler
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Son Hutbeler',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          RecentHutbeList(
            hutbeler: _recentHutbeler,
            onHutbeTap: (id) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HutbeDetailScreen(hutbeId: id),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20), // Alt boşluk
        ],
      ),
    ),
    );
  }
}
