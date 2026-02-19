import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/hutbe.dart';
import '../models/prayer_time.dart';

class ApiService {
  // Production URL (Railway)
  static const String _prodUrl = 'https://minber-production.up.railway.app/api/v1';
  // Development URL (Android emulator localhost)
  static const String _devUrl = 'https://minber-production.up.railway.app/api/v1';
  
  static String get baseUrl => kReleaseMode ? _prodUrl : _devUrl;
  
  // Hutbe endpoints
  Future<List<HutbeListItem>> getHutbeler({
    int page = 1,
    int pageSize = 10,
    int? year,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    
    if (year != null) queryParams['year'] = year.toString();
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    
    final uri = Uri.parse('$baseUrl/hutbeler').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((item) => HutbeListItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load hutbeler');
    }
  }
  
  Future<Hutbe?> getFeaturedHutbe() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/hutbeler/featured'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Hutbe.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching featured hutbe: $e');
      return null;
    }
  }
  
  Future<List<HutbeListItem>> getLatestHutbeler({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/hutbeler/latest').replace(
      queryParameters: {'limit': limit.toString()},
    );
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final items = json.decode(response.body) as List;
      return items.map((item) => HutbeListItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load latest hutbeler');
    }
  }
  
  Future<Hutbe> getHutbeById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/hutbeler/$id'));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Hutbe.fromJson(data);
    } else {
      throw Exception('Failed to load hutbe');
    }
  }
  
  Future<List<Map<String, dynamic>>> getYearsStats() async {
    final response = await http.get(Uri.parse('$baseUrl/hutbeler/years'));
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load years stats');
    }
  }
  
  Future<List<Map<String, dynamic>>> getCategoriesStats() async {
    final response = await http.get(Uri.parse('$baseUrl/hutbeler/categories'));
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load categories stats');
    }
  }

  Future<PrayerTimings> getPrayerTimes({
    double? lat,
    double? lng,
    String? city,
    String? country,
  }) async {
    Uri uri;
    
    // Calculate date for API
    final now = DateTime.now();
    final dateStr = '${now.day}-${now.month}-${now.year}';
    
    if (lat != null && lng != null) {
      // Get by coordinates (Aladhan API)
      uri = Uri.parse('https://api.aladhan.com/v1/timings/$dateStr').replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'method': '13', // Diyanet method
          'school': '1',  // Hanafi Asr (matches Diyanet Turkey)
          'timezonestring': 'Europe/Istanbul',
        },
      );
    } else if (city != null) {
      // Get by city
      uri = Uri.parse('https://api.aladhan.com/v1/timingsByCity/$dateStr').replace(
        queryParameters: {
          'city': city,
          'country': country ?? 'Turkey',
          'method': '13', // Diyanet method
          'school': '1',  // Hanafi Asr (matches Diyanet Turkey)
          'timezonestring': 'Europe/Istanbul',
        },
      );
    } else {
      throw Exception('Either coordinates or city must be provided');
    }

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timingsRaw = data['data']['timings'];
        
        // Helper function to clean timezone suffix from time strings
        String cleanTime(String time) {
          // Remove timezone info like " (EET)" or " (EEST)"
          return time.split(' ')[0].trim();
        }
        
        // Aladhan API returns HH:mm format, but may include timezone
        return PrayerTimings(
          imsak: cleanTime(timingsRaw['Imsak'] ?? timingsRaw['Fajr'] ?? '05:00'),
          fajr: cleanTime(timingsRaw['Fajr'] ?? '05:00'),
          sunrise: cleanTime(timingsRaw['Sunrise'] ?? '06:30'),
          dhuhr: cleanTime(timingsRaw['Dhuhr'] ?? '13:00'),
          asr: cleanTime(timingsRaw['Asr'] ?? '16:30'),
          maghrib: cleanTime(timingsRaw['Maghrib'] ?? '19:30'),
          isha: cleanTime(timingsRaw['Isha'] ?? '21:00'),
          date: data['data']['date']?['readable'] as String?,
          hijriDate: data['data']['date']?['hijri']?['date'] as String?,
          location: city,
        );
      } else {
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      // Fallback data if API fails
      return PrayerTimings(
        imsak: '04:50',
        fajr: '05:00',
        sunrise: '06:30',
        dhuhr: '13:00',
        asr: '16:30',
        maghrib: '19:30',
        isha: '21:00',
      );
    }
  }
}

