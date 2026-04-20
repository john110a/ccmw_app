// lib/services/assignment_service.dart - COMPLETELY FIXED VERSION

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';
import '../models/staff_profile_model.dart';
import 'api_config.dart';

class AssignmentService {

  // =====================================================
  // 1. ASSIGNMENT OPERATIONS
  // =====================================================

  /// Assign complaint to staff
  Future<Map<String, dynamic>> assignComplaint(Map<String, dynamic> assignmentData) async {
    try {
      print('📡 Sending assignment request to: ${ApiConfig.baseUrl}/assignments/assign');
      print('📦 Request data: ${json.encode(assignmentData)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/assign'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(assignmentData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final error = json.decode(response.body);
          final errorMsg = error['Message'] ?? error['error'] ?? 'Unknown error';
          throw Exception('Server error: $errorMsg');
        } catch (_) {
          throw Exception('Failed to assign complaint (Status: ${response.statusCode})');
        }
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Cannot connect to server. Check your connection.');
    } catch (e) {
      print('❌ Error assigning complaint: $e');
      rethrow;
    }
  }

  /// Assign complaint using individual parameters (convenience method)
  Future<void> assignComplaintToStaff({
    required String complaintId,
    required String staffId,
    required String assignedById,
    String? notes,
  }) async {
    final assignmentData = {
      'complaintId': complaintId,
      'assignedToId': staffId,
      'assignedById': assignedById,
      'assignmentNotes': notes ?? 'Assigned by admin',
      'expectedCompletionDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
    };
    await assignComplaint(assignmentData);
  }

  /// Reassign complaint to different staff
  Future<void> reassignComplaint({
    required String complaintId,
    required String newStaffId,
    required String assignedById,
    String? notes,
  }) async {
    try {
      final reassignData = {
        'complaintId': complaintId,
        'assignedToId': newStaffId,
        'assignedById': assignedById,
        'assignmentNotes': notes ?? 'Reassigned by admin',
        'expectedCompletionDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      };

      print('📡 Reassigning complaint: $complaintId to staff: $newStaffId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/reassign'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(reassignData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to reassign complaint');
      }
    } catch (e) {
      print('❌ Error reassigning complaint: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update assignment status (Accepted, Started, Completed)
  Future<void> updateAssignmentStatus(String assignmentId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/update-status'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'assignmentId': assignmentId,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to update assignment status');
      }
    } catch (e) {
      print('❌ Error updating assignment status: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 2. GET ASSIGNMENTS
  // =====================================================

  /// Get assignments by staff ID
  Future<List<dynamic>> getAssignmentsByStaff(String staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/staff/$staffId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get complaint assignment history
  Future<List<dynamic>> getAssignmentHistory(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/complaint/$complaintId/history'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load assignment history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get assignment statistics for dashboard
  Future<Map<String, dynamic>> getAssignmentStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/stats'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'totalAssignments': 0,
          'pendingAssignments': 0,
          'completedToday': 0,
          'completedThisWeek': 0,
          'completedThisMonth': 0,
          'averageCompletionTime': 0,
        };
      }
    } catch (e) {
      print('❌ Error loading assignment stats: $e');
      return {
        'totalAssignments': 0,
        'pendingAssignments': 0,
        'completedToday': 0,
        'completedThisWeek': 0,
        'completedThisMonth': 0,
        'averageCompletionTime': 0,
      };
    }
  }

  // =====================================================
  // 3. GET COMPLAINTS (with filters)
  // =====================================================

  /// Get complaints filtered by department (for Department Admin)
  Future<List<Complaint>> getComplaintsByDepartment(String departmentId) async {
    try {
      final url = '${ApiConfig.baseUrl}/complaints?departmentId=$departmentId';
      print('📡 Fetching complaints for department: $departmentId');
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is Map && data.containsKey('Complaints')) {
          complaintsList = data['Complaints'];
        } else if (data is List) {
          complaintsList = data;
        }

        print('✅ Found ${complaintsList.length} complaints for department');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading complaints by department: $e');
      return [];
    }
  }

  /// Get complaints with multiple filters (status, zone, category, department, assigned)
  Future<List<Complaint>> getComplaints({
    int page = 1,
    int pageSize = 100,
    int? status,
    String? zoneId,
    String? categoryId,
    String? departmentId,
    bool? assigned,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/complaints?page=$page&pageSize=$pageSize';

      if (status != null) {
        url += '&status=$status';
      }
      if (zoneId != null) {
        url += '&zoneId=$zoneId';
      }
      if (categoryId != null) {
        url += '&categoryId=$categoryId';
      }
      if (departmentId != null) {
        url += '&departmentId=$departmentId';
      }
      if (assigned != null) {
        url += '&assigned=$assigned';
      }

      print('📡 Fetching complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is Map && data.containsKey('Complaints')) {
          complaintsList = data['Complaints'];
        } else if (data is List) {
          complaintsList = data;
        }

        print('📊 Found ${complaintsList.length} complaints');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading complaints: $e');
      return [];
    }
  }

  /// Get ALL complaints for routing (System Admin sees everything)
  Future<List<Complaint>> getAllComplaintsForRouting() async {
    try {
      print('📡 Fetching ALL complaints for routing from: ${ApiConfig.baseUrl}/complaints');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is Map) {
          if (data.containsKey('Complaints') && data['Complaints'] is List) {
            complaintsList = data['Complaints'];
            print('✅ Found ${complaintsList.length} complaints in "Complaints"');
          } else if (data.containsKey('data') && data['data'] is List) {
            complaintsList = data['data'];
            print('✅ Found ${complaintsList.length} complaints in "data"');
          }
        } else if (data is List) {
          complaintsList = data;
          print('✅ Found ${complaintsList.length} complaints (direct list)');
        }

        print('📊 Total complaints found: ${complaintsList.length}');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading all complaints: $e');
      return [];
    }
  }

  /// Get pending complaints ready for assignment (Approved & Unassigned)
  Future<List<Complaint>> getPendingComplaints() async {
    try {
      print('📡 Fetching pending complaints from: ${ApiConfig.baseUrl}/assignments/pending');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/pending'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is List) {
          complaintsList = data;
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          complaintsList = data['data'];
        }

        print('📊 Found ${complaintsList.length} pending complaints');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading pending complaints: $e');
      return [];
    }
  }

  // =====================================================
  // 4. STAFF MANAGEMENT
  // =====================================================

  /// Get available staff for assignment (optionally filtered by department)
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

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> staffList = [];

        if (data is Map) {
          if (data.containsKey('Staff') && data['Staff'] is List) {
            staffList = data['Staff'];
          } else if (data.containsKey('data') && data['data'] is List) {
            staffList = data['data'];
          }
        } else if (data is List) {
          staffList = data;
        }

        print('📊 Found ${staffList.length} available staff members');
        return staffList.map((json) => StaffProfile.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading available staff: $e');
      return [];
    }
  }

  /// Get all staff (for debugging or admin purposes)
  Future<List<StaffProfile>> getAllStaff() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/staff'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> staffList = [];

        if (data is Map && data.containsKey('Staff')) {
          staffList = data['Staff'];
        } else if (data is List) {
          staffList = data;
        }

        return staffList.map((json) => StaffProfile.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading all staff: $e');
      return [];
    }
  }

  // =====================================================
  // 5. COMPLAINT REJECTION
  // =====================================================

  /// Reject a complaint with reason
  Future<void> rejectComplaint(String complaintId, String reason) async {
    try {
      print('📡 Rejecting complaint: $complaintId');
      print('📡 Reason: $reason');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/reject'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'reason': reason}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to reject complaint');
      }
    } catch (e) {
      print('❌ Error rejecting complaint: $e');
      throw Exception('Network error: $e');
    }
  }
}