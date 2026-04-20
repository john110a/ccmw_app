// lib/services/appeal_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appeal_model.dart';
import 'api_config.dart';

class AppealService {
  // File appeal
  Future<Map<String, dynamic>> fileAppeal(Map<String, dynamic> appealData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/appeals/file'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(appealData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to file appeal');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get my appeals
  Future<List<Appeal>> getMyAppeals(String citizenId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appeals/my/$citizenId'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Appeal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load appeals');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}