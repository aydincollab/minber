import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/prayer_time.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  PrayerTimings? _prayerTimings;
  String? _city;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
    });

    try {
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

        setState(() {
          _prayerTimings = timings;
          _city = city ?? 'Türkiye';
          _isLoading = false;
        });
      } else {
        // Default to Ankara
        final timings = await _apiService.getPrayerTimes(
          city: 'Ankara',
          country: 'TR',
        );

        setState(() {
          _prayerTimings = timings;
          _city = 'Ankara, TR';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading prayer times: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCurrentPrayer() {
    if (_prayerTimings == null) return '';

    final now = TimeOfDay.now();
    final timings = _prayerTimings!;

    final prayers = [
      {'name': 'İmsak', 'time': timings.fajr},
      {'name': 'Güneş', 'time': timings.sunrise},
      {'name': 'Öğle', 'time': timings.dhuhr},
      {'name': 'İkindi', 'time': timings.asr},
      {'name': 'Akşam', 'time': timings.maghrib},
      {'name': 'Yatsı', 'time': timings.isha},
    ];

    for (int i = prayers.length - 1; i >= 0; i--) {
      final prayerTime = _parseTimeString(prayers[i]['time'] as String);
      if (prayerTime != null) {
        if (now.hour > prayerTime.hour ||
            (now.hour == prayerTime.hour && now.minute >= prayerTime.minute)) {
          return prayers[i]['name'] as String;
        }
      }
    }

    return 'İmsak';
  }

  String? _getNextPrayer() {
    if (_prayerTimings == null) return null;

    final now = TimeOfDay.now();
    final timings = _prayerTimings!;

    final prayers = [
      {'name': 'İmsak', 'time': timings.fajr},
      {'name': 'Güneş', 'time': timings.sunrise},
      {'name': 'Öğle', 'time': timings.dhuhr},
      {'name': 'İkindi', 'time': timings.asr},
      {'name': 'Akşam', 'time': timings.maghrib},
      {'name': 'Yatsı', 'time': timings.isha},
    ];

    for (var prayer in prayers) {
      final prayerTime = _parseTimeString(prayer['time'] as String);
      if (prayerTime != null) {
        if (now.hour < prayerTime.hour ||
            (now.hour == prayerTime.hour && now.minute < prayerTime.minute)) {
          return prayer['name'] as String;
        }
      }
    }

    return 'İmsak'; // Next day
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.darkMid,
        title: const Text('Namaz Vakitleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gold,
              ),
            )
          : _prayerTimings == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadPrayerTimes,
                  color: AppColors.gold,
                  backgroundColor: AppColors.darkMid,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Location card
                      _buildLocationCard(),
                      const SizedBox(height: 20),

                      // Current prayer
                      _buildCurrentPrayerCard(),
                      const SizedBox(height: 20),

                      // All prayer times
                      _buildPrayerTimesList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.gold,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _city ?? 'Konum Alınıyor...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('d MMMM yyyy EEEE', 'tr_TR').format(_selectedDate),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrayerCard() {
    final currentPrayer = _getCurrentPrayer();
    final nextPrayer = _getNextPrayer();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Şu Anki Vakit',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentPrayer,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Playfair Display',
            ),
          ),
          if (nextPrayer != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.textMuted, height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            Text(
              'Sıradaki: $nextPrayer',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    if (_prayerTimings == null) return const SizedBox.shrink();

    final prayers = [
      {'name': 'İmsak', 'time': _prayerTimings!.fajr, 'icon': '🌑'},
      {'name': 'Güneş', 'time': _prayerTimings!.sunrise, 'icon': '🌅'},
      {'name': 'Öğle', 'time': _prayerTimings!.dhuhr, 'icon': '☀️'},
      {'name': 'İkindi', 'time': _prayerTimings!.asr, 'icon': '🌤️'},
      {'name': 'Akşam', 'time': _prayerTimings!.maghrib, 'icon': '🌆'},
      {'name': 'Yatsı', 'time': _prayerTimings!.isha, 'icon': '🌙'},
    ];

    final currentPrayer = _getCurrentPrayer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tüm Vakitler',
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...prayers.map((prayer) {
          final isCurrent = prayer['name'] == currentPrayer;
          return _buildPrayerTimeItem(
            prayer['name'] as String,
            prayer['time'] as String,
            prayer['icon'] as String,
            isCurrent: isCurrent,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPrayerTimeItem(
    String name,
    String time,
    String icon, {
    bool isCurrent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.gold.withOpacity(0.2)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.gold
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gold.withOpacity(0.3)
                  : AppColors.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isCurrent ? AppColors.gold : AppColors.textLight,
                fontSize: 16,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isCurrent ? AppColors.gold : AppColors.textLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Namaz Vakitleri Yüklenemedi',
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
              'Lütfen internet bağlantınızı kontrol edin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPrayerTimes,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.dark,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }
}
