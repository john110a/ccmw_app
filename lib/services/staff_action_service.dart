// lib/services/staff_action_service.dart - COMPLETE VERSION

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';

class StaffActionService {

  // =====================================================
  // 1. STAFF DASHBOARD & PERFORMANCE
  // =====================================================

  /// Get staff dashboard data
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

  /// Get staff performance metrics
  Future<Map<String, dynamic>> getStaffPerformance(String staffId) async {
    try {
      print('📡 Fetching staff performance from: ${ApiConfig.baseUrl}/staff/$staffId/performance');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/performance'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load performance: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading staff performance: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get staff current location
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
  // 2. GET ASSIGNMENTS
  // =====================================================

  /// Get my assignments using the correct backend endpoint
  Future<Map<String, dynamic>> getMyAssignments(String staffId, {String status = 'active'}) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/my-assignments/$staffId?status=$status';
      print('📡 Fetching assignments from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to load assignments: ${response.statusCode}');
        return {'Statistics': {}, 'Assignments': []};
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      return {'Statistics': {}, 'Assignments': []};
    }
  }

  /// Get staff assignments (alternative method using dashboard)
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
  // 3. TASK WORKFLOW (Accept → Start → Resolve)
  // =====================================================

  /// Accept assignment with GPS location verification
  Future<Map<String, dynamic>> acceptAssignmentWithLocation(
      String assignmentId,
      String staffId,
      double lat,
      double lng,
      double accuracy,
      ) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/$assignmentId/accept?staffId=$staffId';
      print('📡 Accepting assignment at: $url');
      print('📦 Location: lat=$lat, lng=$lng');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
          'accuracy': accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['Message'] ?? 'Failed to accept assignment');
      }
    } catch (e) {
      print('❌ Error accepting assignment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Accept assignment (simple version without GPS)
  Future<Map<String, dynamic>> acceptAssignment(String assignmentId, String staffId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/$assignmentId/accept?staffId=$staffId';
      print('📡 Accepting assignment at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to accept assignment');
      }
    } catch (e) {
      print('❌ Error accepting assignment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Start work on assignment
  Future<Map<String, dynamic>> startWork(String assignmentId, String staffId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/$assignmentId/start?staffId=$staffId';
      print('📡 Starting work at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to start work');
      }
    } catch (e) {
      print('❌ Error starting work: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Resolve complaint with resolution notes
  Future<Map<String, dynamic>> resolveComplaint(
      String assignmentId,
      String staffId,
      String resolutionNotes, {
        String? afterPhotoUrl,
      }) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/$assignmentId/resolve?staffId=$staffId';
      print('📡 Resolving complaint at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'resolutionNotes': resolutionNotes,
          'afterPhotoUrl': afterPhotoUrl,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['Message'] ?? 'Failed to resolve complaint');
      }
    } catch (e) {
      print('❌ Error resolving complaint: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 4. GET ASSIGNMENT TIMELINE
  // =====================================================

  /// Get assignment timeline
  Future<Map<String, dynamic>> getAssignmentTimeline(String assignmentId) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/assignment/$assignmentId/timeline';
      print('📡 Fetching timeline from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load timeline');
      }
    } catch (e) {
      print('❌ Error loading timeline: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 5. PHOTO UPLOAD
  // =====================================================

  /// Upload resolution photo
  Future<Map<String, dynamic>> uploadResolutionPhoto(String assignmentId, String staffId, File imageFile) async {
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
      print('📡 Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return json.decode(responseData);
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // =====================================================
  // 6. LOCATION TRACKING - FIXED
  // =====================================================

  /// Update staff GPS location
  Future<void> updateLocation(String staffId, double lat, double lng, double accuracy) async {
    try {
      final url = '${ApiConfig.baseUrl}/staff-actions/$staffId/location';
      print('📡 Updating location at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'latitude': lat,
          'longitude': lng,
          'accuracy': accuracy,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Location updated successfully');
      } else {
        throw Exception('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating location: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get nearby complaints for staff - FIXED: Use GET with query parameters
  Future<Map<String, dynamic>> getNearbyComplaints(String staffId, double lat, double lng, double radiusKm) async {
    try {
      // FIXED: Use GET with query parameters instead of POST
      final url = '${ApiConfig.baseUrl}/staff-actions/$staffId/nearby-complaints?lat=$lat&lng=$lng&radiusKm=$radiusKm';
      print('📡 Fetching nearby complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Found ${data['TotalNearby'] ?? 0} nearby complaints');
        return data;
      } else {
        print('❌ Failed to fetch nearby complaints: ${response.statusCode}');
        throw Exception('Failed to fetch nearby complaints');
      }
    } catch (e) {
      print('❌ Error fetching nearby complaints: $e');
      throw Exception('Network error: $e');
    }
  }
}