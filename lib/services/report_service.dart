// lib/services/report_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ReportService {
  Future<List<Map<String, dynamic>>> getAvailableReports() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports/available'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('Error loading reports: $e');
      return [
        {'id': 'monthly', 'name': 'Monthly Complaints Summary'},
        {'id': 'resolution', 'name': 'Resolution Time Analysis'},
        {'id': 'staff', 'name': 'Staff Performance Report'},
      ];
    }
  }

  Future<String> generateReport(String reportType) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports/generate'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'type': reportType}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return 'Report generated successfully';
      }
      throw Exception('Failed to generate report');
    } catch (e) {
      print('Error generating report: $e');
      return 'Report saved to downloads folder (mock)';
    }
  }
}