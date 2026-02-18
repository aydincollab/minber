import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../../theme/app_colors.dart';
import '../../../models/prayer_time.dart';

class PrayerCard extends StatefulWidget {
  final PrayerTimings? prayerTimings;
  final String? city;

  const PrayerCard({
    super.key,
    this.prayerTimings,
    this.city,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  Timer? _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (widget.prayerTimings == null) return;
    
    final now = DateTime.now();
    final nextPrayerTime = widget.prayerTimings!.nextPrayerTime;
    
    // Parse next prayer time
    final parts = nextPrayerTime.split(':');
    if (parts.length != 2) {
      setState(() {
        _countdown = '';
      });
      return;
    }
    
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    
    var nextPrayer = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the prayer time has passed today, it's tomorrow
    if (nextPrayer.isBefore(now)) {
      nextPrayer = nextPrayer.add(const Duration(days: 1));
    }
    
    final difference = nextPrayer.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    setState(() {
      _countdown = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prayerTimings == null) {
      return _buildLoadingCard();
    }

    final prayers = widget.prayerTimings!.allPrayers;
    final turkishNames = PrayerTimings.turkishNames;
    
    // Prayer names in order for comparison
    const prayerNamesOrder = ['Imsak', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📍',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.city ?? 'Konum Tespit Ediliyor...',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('⏱', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          'Sıradaki: ${turkishNames[widget.prayerTimings!.nextPrayerName] ?? widget.prayerTimings!.nextPrayerName}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Prayer times
              ...prayers.asMap().entries.map((entry) {
                final index = entry.key;
                final prayerTime = entry.value;
                final prayerName = prayerTime.name;
                final prayerTimeStr = prayerTime.time;
                
                // Determine if this is the next prayer
                final isNext = widget.prayerTimings!.nextPrayerName == prayerNamesOrder[index];
                
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        color: AppColors.textMuted.withOpacity(0.2),
                        height: 20,
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prayerName,
                          style: TextStyle(
                            color: isNext ? AppColors.gold : AppColors.textLight,
                            fontSize: isNext ? 18 : 16,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          prayerTimeStr,
                          style: TextStyle(
                            color: isNext ? AppColors.gold : AppColors.textLight,
                            fontSize: isNext ? 18 : 16,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
              
              const SizedBox(height: 32),
              
              // Countdown pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      _countdown.isNotEmpty ? _countdown : 'Hesaplanıyor...',
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
        ),
      ),
    );
  }
}
