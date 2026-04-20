// lib/services/staff_service.dart - FULLY UPDATED VERSION

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/staff_profile_model.dart';
import 'api_config.dart';

class StaffService {
  /// Get all staff
  Future<List<StaffProfile>> getAllStaff() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 getAllStaff response status: ${response.statusCode}');
      print('📦 getAllStaff response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> staffList = [];

        // Handle your backend response format { TotalStaff, Staff }
        if (data is Map) {
          // Your backend returns { "TotalStaff": 13, "Staff": [...] }
          if (data['Staff'] != null && data['Staff'] is List) {
            staffList = data['Staff'];
            print('✅ Found ${staffList.length} staff in "Staff" array');
          }
          // Alternative formats
          else if (data['data'] != null && data['data'] is List) {
            staffList = data['data'];
          } else if (data['staff'] != null && data['staff'] is List) {
            staffList = data['staff'];
          } else if (data['results'] != null && data['results'] is List) {
            staffList = data['results'];
          }
        } else if (data is List) {
          staffList = data;
        }

        return staffList.map((json) => StaffProfile.fromJson(json)).toList();
      } else {
        print('❌ getAllStaff failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading staff: $e');
      return [];
    }
  }

  /// Get staff by ID
  Future<StaffProfile?> getStaffById(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return StaffProfile.fromJson(json.decode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error loading staff: $e');
      return null;
    }
  }

  /// Add new staff
  Future<Map<String, dynamic>> addStaff(Map<String, dynamic> staffData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/staff'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(staffData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add staff');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update staff
  Future<Map<String, dynamic>> updateStaff(String staffId, Map<String, dynamic> staffData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(staffData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update staff');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Toggle staff availability
  Future<Map<String, dynamic>> toggleAvailability(String staffId, bool isAvailable) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/availability?isAvailable=$isAvailable'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update availability');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get available staff for assignment
  Future<List<StaffProfile>> getAvailableStaff([String? departmentId]) async {
    try {
      String url = '${ApiConfig.baseUrl}/staff/available';
      if (departmentId != null) {
        url += '?departmentId=$departmentId';
      }

      print('📡 Fetching available staff from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> staffList = [];

        if (data is Map) {
          // Your backend returns { "TotalAvailable": 11, "Staff": [...] }
          if (data['Staff'] != null && data['Staff'] is List) {
            staffList = data['Staff'];
            print('✅ Found ${staffList.length} staff in "Staff" array');
          }
          // Alternative formats
          else if (data['data'] != null && data['data'] is List) {
            staffList = data['data'];
            print('✅ Found ${staffList.length} staff in "data" array');
          } else if (data['staff'] != null && data['staff'] is List) {
            staffList = data['staff'];
            print('✅ Found ${staffList.length} staff in "staff" array');
          } else if (data['results'] != null && data['results'] is List) {
            staffList = data['results'];
            print('✅ Found ${staffList.length} staff in "results" array');
          }
        } else if (data is List) {
          staffList = data;
          print('✅ Found ${staffList.length} staff (direct list)');
        }

        return staffList.map((json) => StaffProfile.fromJson(json)).toList();
      } else {
        print('❌ getAvailableStaff failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading available staff: $e');
      return [];
    }
  }

  /// Get staff by department
  Future<List<StaffProfile>> getStaffByDepartment(String departmentId) async {
    try {
      final allStaff = await getAllStaff();
      return allStaff.where((s) => s.departmentId == departmentId).toList();
    } catch (e) {
      print('❌ Error loading staff by department: $e');
      return [];
    }
  }

  /// Get staff dashboard
  Future<Map<String, dynamic>> getStaffDashboard(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/dashboard'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load staff dashboard');
      }
    } catch (e) {
      print('❌ Error loading staff dashboard: $e');
      rethrow;
    }
  }

  /// Update availability (alternative method)
  Future<void> updateAvailability(String staffId, bool isAvailable) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/availability'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(isAvailable),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('❌ Error updating availability: $e');
      rethrow;
    }
  }

  // =====================================================
  // LOCATION SERVICES - FIXED ENDPOINTS
  // =====================================================

  /// Update GPS location - FIXED: using /staff/ not /staff-actions/
  Future<void> updateLocation(String staffId, double lat, double lng, double accuracy) async {
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
      print('❌ Error updating location: $e');
      rethrow;
    }
  }

  /// Get nearby complaints - FIXED: requires lat, lng parameters
  Future<List<dynamic>> getNearbyComplaints(String staffId, double lat, double lng, double radiusKm) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff/$staffId/nearby-complaints?lat=$lat&lng=$lng&radiusKm=$radiusKm'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Complaints'] ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Error loading nearby complaints: $e');
      return [];
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
      }
      return null;
    } catch (e) {
      print('❌ Error getting staff location: $e');
      return null;
    }
  }
}