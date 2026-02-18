import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  String _city = 'Ankara';
  String _prayerMethod = 'Diyanet';
  bool _notificationsEnabled = true;
  double _ttsSpeed = 1.0;

  String get city => _city;
  String get prayerMethod => _prayerMethod;
  bool get notificationsEnabled => _notificationsEnabled;
  double get ttsSpeed => _ttsSpeed;

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _city = prefs.getString('city') ?? 'Ankara';
      _prayerMethod = prefs.getString('prayer_method') ?? 'Diyanet';
      _notificationsEnabled = (prefs.getString('notifications') ?? 'true') == 'true';
      
      final speedStr = prefs.getString('tts_speed');
      if (speedStr != null) {
        _ttsSpeed = double.tryParse(speedStr) ?? 1.0;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> setCity(String city) async {
    if (_city == city) return;
    _city = city;
    notifyListeners();
    await _saveString('city', city);
  }

  Future<void> setPrayerMethod(String method) async {
    if (_prayerMethod == method) return;
    _prayerMethod = method;
    notifyListeners();
    await _saveString('prayer_method', method);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    await _saveString('notifications', enabled.toString());
  }

  Future<void> setTtsSpeed(double speed) async {
    if (_ttsSpeed == speed) return;
    _ttsSpeed = speed;
    notifyListeners();
    await _saveString('tts_speed', speed.toString());
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving preference $key: $e');
    }
  }
}
