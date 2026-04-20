// lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';
import 'api_config.dart';
import 'AuthService.dart'; // ADD THIS IMPORT

class DashboardService {
  final AuthService _authService = AuthService(); // ADD THIS

  // ========== CITIZEN DASHBOARD ==========
  Future<Map<String, dynamic>> getCitizenDashboard(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/citizen/$userId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ========== STAFF DASHBOARD ==========
  Future<Map<String, dynamic>> getStaffDashboard(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/staff/$staffId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load staff dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ========== ADMIN DASHBOARD ==========
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/admin'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load admin dashboard');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ========== DEPARTMENT DASHBOARD ==========
  // FIXED: Added userId parameter to match backend requirement
  Future<Map<String, dynamic>> getDepartmentDashboard(String departmentId) async {
    try {
      // Get the current user ID
      final userId = await _authService.getUserId();

      if (userId == null || userId.isEmpty) {
        throw Exception('User not logged in. Please login again.');
      }

      // Build URL with userId parameter
      final url = '${ApiConfig.baseUrl}/dashboard/department/$departmentId?userId=$userId';
      print('📡 Fetching department dashboard from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Department dashboard loaded successfully');

        // Validate response structure
        if (data.containsKey('Department') && data.containsKey('Statistics')) {
          return data;
        } else {
          print('⚠️ Unexpected response format: $data');
          // Return a default structure
          return {
            'Department': data['Department'] ?? {},
            'Statistics': data['Statistics'] ?? {
              'TotalComplaints': 0,
              'ActiveComplaints': 0,
              'PendingApprovals': 0,
              'ResolvedThisMonth': 0,
              'PerformanceScore': 0,
              'AverageResolutionTimeDays': 0
            },
            'TopStaff': data['TopStaff'] ?? [],
            'RecentComplaints': data['RecentComplaints'] ?? []
          };
        }
      } else {
        print('❌ Failed to load department dashboard: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
        throw Exception('Failed to load department dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getDepartmentDashboard: $e');
      throw Exception('Network error: $e');
    }
  }

  // ========== CONTRACTOR DASHBOARD ==========
  Future<Map<String, dynamic>> getContractorDashboard(String contractorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/contractor/$contractorId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Contractor not found');
      } else {
        throw Exception('Failed to load contractor dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading contractor dashboard: $e');
      throw Exception('Network error: $e');
    }
  }

  // ========== RAW RESPONSE METHOD FOR DEBUGGING ==========
  Future<http.Response> getDepartmentDashboardRaw(String departmentId) async {
    try {
      final userId = await _authService.getUserId();
      final url = '${ApiConfig.baseUrl}/dashboard/department/$departmentId?userId=$userId';
      print('📍 GET: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response;
    } catch (e) {
      print('❌ Error in getDepartmentDashboardRaw: $e');
      rethrow;
    }
  }
  // Add contractor dashboard method
//   Future<Map<String, dynamic>> getContractorDashboard(String contractorId) async {
//     final response = await http.get(
//       Uri.parse('${ApiConfig.baseUrl}/dashboard/contractor/$contractorId'),
//       headers: ApiConfig.getHeaders(),
//     );
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     }
//     throw Exception('Failed to load contractor dashboard');
//   }
}