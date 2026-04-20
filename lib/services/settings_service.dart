// lib/services/settings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SettingsService {
  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/settings'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'notificationsEnabled': true,
        'autoAssignmentEnabled': false,
        'maintenanceMode': false,
        'escalationHours': 48,
        'defaultPriority': 'Medium',
      };
    } catch (e) {
      print('Error loading settings: $e');
      return {
        'notificationsEnabled': true,
        'autoAssignmentEnabled': false,
        'maintenanceMode': false,
        'escalationHours': 48,
        'defaultPriority': 'Medium',
      };
    }
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/settings'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(settings),
      );
    } catch (e) {
      print('Error updating settings: $e');
    }
  }
}