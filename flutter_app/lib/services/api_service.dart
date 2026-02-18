import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/hutbe.dart';
import '../models/prayer_time.dart';

class ApiService {
  // TODO: Update _prodUrl after Railway deploy
  // After deploying to Railway, replace this with your actual Railway URL
  // Example: 'https://minber-production.up.railway.app/api/v1'
  static const String _prodUrl = 'https://minber-production.up.railway.app/api/v1';
  static const String _devUrl = 'http://10.0.2.2:8000/api/v1';
  
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
  
  // Prayer times endpoints
  Future<PrayerTimings> getPrayerTimes({
    double? lat,
    double? lng,
    String? city,
    String country = 'TR',
  }) async {
    final queryParams = <String, String>{
      'country': country,
    };
    
    if (lat != null && lng != null) {
      queryParams['lat'] = lat.toString();
      queryParams['lng'] = lng.toString();
    } else if (city != null) {
      queryParams['city'] = city;
    }
    
    final uri = Uri.parse('$baseUrl/namaz-vakitleri').replace(
      queryParameters: queryParams,
    );
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PrayerTimings.fromJson(data);
    } else {
      throw Exception('Failed to load prayer times');
    }
  }
}
