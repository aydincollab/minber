import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/location_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      animation: 'assets/animations/onboarding_hutbe.json',
      title: 'Hutbeler',
      description: 'Diyanet İşleri Başkanlığı\'nın tüm hutbelerine kolayca erişin. Haftalık, bayram ve özel gün hutbelerini okuyun.',
    ),
    OnboardingPage(
      animation: 'assets/animations/onboarding_prayer.json',
      title: 'Namaz Vakitleri',
      description: 'Bulunduğunuz konuma göre günlük namaz vakitlerini görüntüleyin. Bildirim almak için izin verin.',
    ),
    OnboardingPage(
      animation: 'assets/animations/onboarding_location.json',
      title: 'Konum İzni',
      description: 'Namaz vakitlerini doğru hesaplamak için konum izni gereklidir. İstediğiniz zaman ayarlardan değiştirebilirsiniz.',
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _requestLocationAndFinish() async {
    // Show loading indicator usually, but for now simple await
    final locationService = LocationService(); // Instantiate directly or via GetIt
    
    // Request permission
    await locationService.requestPermission();
    
    // Get position and city
    final position = await locationService.getCurrentPosition();
    if (position != null) {
      final city = await locationService.getCityFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (city != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_city', city);
      }
    }
    
    // Complete onboarding regardless of success (if denied, default kicks in later or user sets manually)
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Atla',
                  style: TextStyle(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isDark);
                },
              ),
            ),
            
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDotIndicator(index, isDark),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next/Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == _pages.length - 1) {
                      // Son sayfada konum izni iste ve şehri bul
                      await _requestLocationAndFinish();
                    } else {
                      _nextPage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Konumu Paylaş ve Başla' : 'İleri',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Lottie.asset(
              page.animation,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isDark ? AppColors.textLight : AppColors.textDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.gold
            : (isDark ? AppColors.textMuted : AppColors.textDarkMuted).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String animation;
  final String title;
  final String description;

  const OnboardingPage({
    required this.animation,
    required this.title,
    required this.description,
  });
}
