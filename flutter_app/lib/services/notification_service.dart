import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local ezan (prayer time) push notifications.
/// No backend needed — all scheduled locally on the device.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _enabledKey = 'ezan_notifications_enabled';

  // ── Init ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  // ── Permission ────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Enabled state ─────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      await cancelAll();
    }
  }

  // ── Schedule today's prayers ──────────────────────────────────────

  /// Schedule local notifications for today's prayer times.
  /// [prayerTimes] is a map like {'Fajr': '05:12', 'Dhuhr': '12:30', ...}
  Future<void> schedulePrayerNotifications(
      Map<String, String> prayerTimes) async {
    await initialize();
    await cancelAll(); // Clear old ones first

    final enabled = await isEnabled();
    if (!enabled) return;

    const prayerNames = {
      'Fajr': 'İmsak',
      'Sunrise': 'Güneş',
      'Dhuhr': 'Öğle',
      'Asr': 'İkindi',
      'Maghrib': 'Akşam',
      'Isha': 'Yatsı',
    };

    int id = 0;
    final now = DateTime.now();

    for (final entry in prayerTimes.entries) {
      final name = prayerNames[entry.key] ?? entry.key;
      final parts = entry.value.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final scheduledTime = DateTime(
          now.year, now.month, now.day, hour, minute);

      if (scheduledTime.isAfter(now)) {
        await _scheduleNotification(
          id: id++,
          title: '🕌 $name Vakti',
          body: 'Namaz vakti geldi. Allah kabul etsin.',
          scheduledTime: scheduledTime,
        );
      }
    }

    debugPrint('Scheduled ${id} prayer notifications for today');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ezan_channel',
          'Ezan Bildirimleri',
          channelDescription: 'Namaz vakti bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
