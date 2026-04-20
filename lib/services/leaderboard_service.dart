// lib/services/leaderboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class LeaderboardService {
  // Get citizen leaderboard
  Future<List<dynamic>> getCitizenLeaderboard({String period = 'all', int top = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leaderboard/citizens?period=$period&top=$top'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['Leaderboard'] ?? [];
      } else {
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get user rank
  Future<Map<String, dynamic>> getUserRank(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/leaderboard/citizens/$userId/rank'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user rank');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}