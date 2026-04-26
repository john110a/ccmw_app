// lib/services/leaderboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class LeaderboardService {
  // Get citizen leaderboard
  Future<List<dynamic>> getCitizenLeaderboard({String period = 'all', int top = 20}) async {
    try {
      final url = '${ApiConfig.baseUrl}/leaderboard/citizens?period=$period&top=$top';
      print('📡 Fetching leaderboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Leaderboard loaded, found ${data['Leaderboard']?.length ?? 0} entries');
        return data['Leaderboard'] ?? [];
      } else {
        print('❌ Failed to load leaderboard: ${response.statusCode}');
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Failed to connect to server');
    }
  }

  // Get user rank
  Future<Map<String, dynamic>> getUserRank(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}/leaderboard/citizens/$userId/rank';
      print('📡 Fetching user rank from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ User rank loaded - Rank: ${data['Rank']}, Badge: ${data['Badge']}');
        return data;
      } else if (response.statusCode == 404) {
        print('⚠️ User not found for rank');
        throw Exception('User not found');
      } else {
        print('❌ Failed to load user rank: ${response.statusCode}');
        throw Exception('Failed to load user rank: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Failed to connect to server');
    }
  }

  // Get department leaderboard
  Future<List<dynamic>> getDepartmentLeaderboard() async {
    try {
      final url = '${ApiConfig.baseUrl}/leaderboard/departments';
      print('📡 Fetching department leaderboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Department leaderboard loaded');
        return data;
      } else {
        throw Exception('Failed to load department leaderboard');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get zone leaderboard
  Future<List<dynamic>> getZoneLeaderboard() async {
    try {
      final url = '${ApiConfig.baseUrl}/leaderboard/zones';
      print('📡 Fetching zone leaderboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Zone leaderboard loaded');
        return data;
      } else {
        throw Exception('Failed to load zone leaderboard');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get staff leaderboard
  Future<List<dynamic>> getStaffLeaderboard({String? departmentId}) async {
    try {
      String url = '${ApiConfig.baseUrl}/leaderboard/staff';
      if (departmentId != null && departmentId.isNotEmpty) {
        url += '?departmentId=$departmentId';
      }
      print('📡 Fetching staff leaderboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Staff leaderboard loaded');
        return data;
      } else {
        throw Exception('Failed to load staff leaderboard');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: $e');
    }
  }
}