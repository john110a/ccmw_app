// lib/services/escalation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/escalation_model.dart';
import 'api_config.dart';

class EscalationService {
  Future<List<Escalation>> getActiveEscalations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/escalations'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Escalations response status: ${response.statusCode}');
      print('📦 Escalations response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // FIXED: Handle the response properly
        List<dynamic> escalationsList = [];

        // Check if data is a Map with 'Data' key
        if (data is Map<String, dynamic>) {
          if (data.containsKey('Data') && data['Data'] is List) {
            escalationsList = data['Data'] as List<dynamic>;
            print('✅ Found ${escalationsList.length} escalations in "Data"');
          } else if (data.containsKey('data') && data['data'] is List) {
            escalationsList = data['data'] as List<dynamic>;
            print('✅ Found ${escalationsList.length} escalations in "data"');
          } else {
            print('⚠️ Unknown response format: ${data.keys}');
          }
        } else if (data is List) {
          escalationsList = data;
          print('✅ Found ${escalationsList.length} escalations (direct list)');
        }

        return escalationsList.map((json) => Escalation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading escalations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEscalationRules() async {
    return [
      {'level': 'Level 1', 'time': '24 hours', 'action': 'Notify Zone Manager', 'description': 'Auto-notification sent when complaint pending for 24h'},
      {'level': 'Level 2', 'time': '48 hours', 'action': 'Escalate to Dept. Head', 'description': 'Department head intervention required'},
      {'level': 'Level 3', 'time': '72 hours', 'action': 'Executive Escalation', 'description': 'City administration notification'},
    ];
  }

  Future<void> resolveEscalation(String escalationId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/escalations/$escalationId/resolve'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));
      print('✅ Escalation resolved successfully');
    } catch (e) {
      print('❌ Error resolving escalation: $e');
    }
  }
}