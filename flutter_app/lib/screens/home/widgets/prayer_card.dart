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

    final nextPrayerTime = widget.prayerTimings!.nextPrayerTime;
    if (nextPrayerTime == null) return;

    try {
      final timeParts = nextPrayerTime.split(':');
      final now = DateTime.now();
      final nextPrayer = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      var difference = nextPrayer.difference(now);
      if (difference.isNegative) {
        difference = nextPrayer.add(const Duration(days: 1)).difference(now);
      }

      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      setState(() {
        _countdown = '${hours}s ${minutes}dk ${seconds}sn';
      });
    } catch (e) {
      setState(() {
        _countdown = 'Hesaplanıyor...';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prayerTimings == null) {
      return _buildLoadingCard();
    }

    final prayers = widget.prayerTimings!.allPrayers;
    final turkishNames = PrayerTimings.turkishNames;

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
                          'Sıradaki: ${turkishNames[widget.prayerTimings!.nextPrayerName] ?? ''}',
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
                final prayer = entry.value;
                final turkishName = turkishNames[prayer.name] ?? prayer.name;
                final isActive = prayer.name == widget.prayerTimings!.nextPrayerName;

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
                          turkishName,
                          style: TextStyle(
                            color: isActive ? AppColors.gold : AppColors.textLight,
                            fontSize: isActive ? 18 : 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          prayer.time.split(' ')[0], // Remove timezone
                          style: TextStyle(
                            color: isActive ? AppColors.gold : AppColors.textLight,
                            fontSize: isActive ? 18 : 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
                      '${turkishNames[widget.prayerTimings!.nextPrayerName]}\'ye: $_countdown kaldı',
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
