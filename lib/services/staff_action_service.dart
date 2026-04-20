// lib/services/staff_action_service.dart - FULLY FIXED VERSION

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';

class StaffActionService {

  // =====================================================
  // 1. GET STAFF DASHBOARD (UPDATED TO MATCH BACKEND)
  // =====================================================

  /// Get staff dashboard data (matches backend /staff/{id}/dashboard)
  Future<Map<String, dynamic>> getStaffDashboard(String staffId) async {
    try {
      print('📡 Fetching staff dashboard from: ${ApiConfig.baseUrl}/staff/$staffId/dashboard');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/dashboard'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading staff dashboard: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get my assignments (active/completed) - UPDATED to use dashboard endpoint
  Future<Map<String, dynamic>> getMyAssignments(String staffId, {String status = 'active'}) async {
    try {
      // Use the dashboard endpoint which returns assignments
      final dashboard = await getStaffDashboard(staffId);

      // Extract assignments based on status
      List<dynamic> assignments = [];
      if (status == 'active') {
        assignments = dashboard['ActiveAssignments'] ?? [];
      } else {
        assignments = dashboard['RecentCompleted'] ?? [];
      }

      // Extract staff info from dashboard
      final staff = dashboard['Staff'] ?? {};
      final stats = dashboard['Statistics'] ?? {};

      return {
        'StaffName': staff['FullName'],
        'DepartmentName': staff['DepartmentName'],
        'Role': staff['Role'],
        'EmployeeId': staff['EmployeeId'],
        'PerformanceScore': stats['PerformanceScore'],
        'Statistics': {
          'Total': stats['TotalAssigned'] ?? 0,
          'Completed': stats['Completed'] ?? 0,
          'Pending': stats['Pending'] ?? 0,
          'CompletionRate': stats['CompletionRate'] ?? 0,
        },
        'Assignments': assignments,
      };
    } catch (e) {
      print('❌ Error getting assignments: $e');
      return {
        'StaffName': null,
        'DepartmentName': null,
        'Role': null,
        'Statistics': {'Total': 0, 'Completed': 0, 'Pending': 0},
        'Assignments': [],
      };
    }
  }

  /// Get staff assignments (legacy method)
  Future<List<dynamic>> getStaffAssignments(String staffId) async {
    try {
      final dashboard = await getStaffDashboard(staffId);
      return dashboard['ActiveAssignments'] ?? [];
    } catch (e) {
      print('❌ Error loading assignments: $e');
      return [];
    }
  }

  // =====================================================
  // 2. TASK WORKFLOW (Accept → Start → Resolve)
  // =====================================================

  /// Accept assignment (simple version)
  Future<Map<String, dynamic>> acceptAssignment(String assignmentId, String staffId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff-actions/assignments/$assignmentId/accept?staffId=$staffId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': response.body};
      } else {
        throw Exception('Failed to accept assignment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Accept assignment with GPS location verification
  Future<void> acceptAssignmentWithLocation(
      String assignmentId,
      String staffId,
      double lat,
      double lng,
      double accuracy,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff-actions/$assignmentId/accept?staffId=$staffId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
          'accuracy': accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['Message'] ?? 'Failed to accept assignment');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Start work on assignment
  Future<Map<String, dynamic>> startWork(String assignmentId, String staffId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff-actions/assignments/$assignmentId/start?staffId=$staffId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'message': response.body};
      } else {
        throw Exception('Failed to start work');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Resolve complaint with resolution notes
  Future<void> resolveComplaint(
      String assignmentId,
      String staffId,
      String resolutionNotes, {
        String? afterPhotoUrl,
      }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff-actions/$assignmentId/resolve?staffId=$staffId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'resolutionNotes': resolutionNotes,
          'afterPhotoUrl': afterPhotoUrl,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['Message'] ?? 'Failed to resolve complaint');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 3. PHOTO UPLOAD
  // =====================================================

  /// Upload resolution photo
  Future<void> uploadResolutionPhoto(String assignmentId, String staffId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/complaint-media/assignment/$assignmentId/resolution/upload?staffId=$staffId'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // =====================================================
  // 4. LOCATION TRACKING - FIXED ENDPOINTS
  // =====================================================

  /// Update staff GPS location - FIXED: using /staff/ not /staff-actions/
  Future<void> updateLocation(
      String staffId,
      double lat,
      double lng,
      double accuracy,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/location'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
          'accuracy': accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get nearby complaints for staff - FIXED: requires lat, lng parameters
  Future<Map<String, dynamic>> getNearbyComplaints(
      String staffId,
      double lat,
      double lng,
      double radiusKm,
      ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/nearby-complaints?lat=$lat&lng=$lng&radiusKm=$radiusKm'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch nearby complaints');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get staff current location - NEW METHOD
  Future<Map<String, dynamic>?> getStaffLocation(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/location'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting staff location: $e');
      return null;
    }
  }

  // =====================================================
  // 5. STAFF PERFORMANCE
  // =====================================================

  /// Get staff performance metrics
  Future<Map<String, dynamic>> getStaffPerformance(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/performance'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load performance data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}