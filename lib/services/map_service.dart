// lib/services/map_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';
import 'api_config.dart';

class MapService {
  // Get complaints for map
  Future<List<Complaint>> getMapComplaints({
    String? zoneId,
    String? categoryId,
    String? status,
    double? lat,
    double? lng,
    double radiusKm = 5.0,
  }) async {
    String url = '${ApiConfig.baseUrl}/map/complaints?';
    if (zoneId != null) url += '&zoneId=$zoneId';
    if (categoryId != null) url += '&categoryId=$categoryId';
    if (status != null) url += '&status=$status';
    if (lat != null) url += '&lat=$lat';
    if (lng != null) url += '&lng=$lng';
    if (radiusKm != null) url += '&radiusKm=$radiusKm';

    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> complaints = data['data'] ?? [];
      return complaints.map((json) => Complaint.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load map complaints');
    }
  }

  // Get nearby complaints
  Future<List<dynamic>> getNearbyComplaints(double lat, double lng, {double radiusKm = 2.0}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/map/nearby?lat=$lat&lng=$lng&radiusKm=$radiusKm'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load nearby complaints');
    }
  }
}