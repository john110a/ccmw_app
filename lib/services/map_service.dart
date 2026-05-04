// lib/services/map_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';
import 'api_config.dart';

class MapService {
  // Get complaints for map
  Future<List<Map<String, dynamic>>> getMapComplaints({
    String? zoneId,
    String? categoryId,
    String? status,
    double? lat,
    double? lng,
    double radiusKm = 5.0,
  }) async {
    try {
      // Build query parameters
      List<String> queryParams = [];

      if (zoneId != null) queryParams.add('zoneId=$zoneId');
      if (categoryId != null) queryParams.add('categoryId=$categoryId');
      if (status != null) queryParams.add('status=$status');
      if (lat != null) queryParams.add('lat=$lat');
      if (lng != null) queryParams.add('lng=$lng');
      if (radiusKm != null) queryParams.add('radiusKm=$radiusKm');

      String url = '${ApiConfig.baseUrl}/map/complaints';
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('📡 Fetching map complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> complaints = data['data'] ?? [];
          print('✅ Found ${complaints.length} complaints on map');
          return complaints.cast<Map<String, dynamic>>();
        } else {
          print('❌ API returned error: ${data['error']}');
          return [];
        }
      } else {
        throw Exception('Failed to load map complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading map complaints: $e');
      return [];
    }
  }

  // Get nearby complaints
  Future<List<Map<String, dynamic>>> getNearbyComplaints(
      double lat,
      double lng, {
        double radiusKm = 2.0,
        int limit = 20,
      }) async {
    try {
      final url = '${ApiConfig.baseUrl}/map/nearby?lat=$lat&lng=$lng&radiusKm=$radiusKm&limit=$limit';
      print('📡 Fetching nearby complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> complaints = data['data'] ?? [];
          print('✅ Found ${complaints.length} nearby complaints within ${radiusKm}km');
          return complaints.cast<Map<String, dynamic>>();
        } else {
          print('❌ API returned error: ${data['error']}');
          return [];
        }
      } else {
        throw Exception('Failed to load nearby complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading nearby complaints: $e');
      return [];
    }
  }

  // Get zones with boundaries
  Future<List<Map<String, dynamic>>> getZonesWithBoundaries() async {
    try {
      final url = '${ApiConfig.baseUrl}/map/zones';
      print('📡 Fetching zones from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> zones = data['data'] ?? [];
          print('✅ Found ${zones.length} zones with boundaries');
          return zones.cast<Map<String, dynamic>>();
        } else {
          print('❌ API returned error: ${data['error']}');
          return [];
        }
      } else {
        throw Exception('Failed to load zones: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading zones: $e');
      return [];
    }
  }

  // Get complaint density by zone
  Future<List<Map<String, dynamic>>> getComplaintDensity() async {
    try {
      final url = '${ApiConfig.baseUrl}/map/density';
      print('📡 Fetching complaint density from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> density = data['data'] ?? [];
          print('✅ Loaded density for ${density.length} zones');
          return density.cast<Map<String, dynamic>>();
        } else {
          print('❌ API returned error: ${data['error']}');
          return [];
        }
      } else {
        throw Exception('Failed to load complaint density: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading complaint density: $e');
      return [];
    }
  }

  // Get zone statistics
  Future<Map<String, dynamic>> getZoneStats() async {
    try {
      final url = '${ApiConfig.baseUrl}/map/zone-stats';
      print('📡 Fetching zone stats from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          print('✅ Loaded zone statistics');
          return data;
        } else {
          print('❌ API returned error: ${data['error']}');
          return {'data': [], 'summary': {}};
        }
      } else {
        throw Exception('Failed to load zone stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading zone stats: $e');
      return {'data': [], 'summary': {}};
    }
  }

  // Get heatmap data
  Future<List<Map<String, dynamic>>> getHeatmapData({
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) async {
    try {
      List<String> queryParams = [];
      if (minLat != null) queryParams.add('minLat=$minLat');
      if (maxLat != null) queryParams.add('maxLat=$maxLat');
      if (minLng != null) queryParams.add('minLng=$minLng');
      if (maxLng != null) queryParams.add('maxLng=$maxLng');

      String url = '${ApiConfig.baseUrl}/map/heatmap';
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('📡 Fetching heatmap data from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> heatmapData = data['data'] ?? [];
          print('✅ Loaded ${heatmapData.length} heatmap points');
          return heatmapData.cast<Map<String, dynamic>>();
        } else {
          print('❌ API returned error: ${data['error']}');
          return [];
        }
      } else {
        throw Exception('Failed to load heatmap data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading heatmap data: $e');
      return [];
    }
  }
}