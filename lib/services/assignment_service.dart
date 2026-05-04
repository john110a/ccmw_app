// lib/services/assignment_service.dart - COMPLETELY FIXED VERSION

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';
import '../models/staff_profile_model.dart';
import 'api_config.dart';
import 'AuthService.dart';

class AssignmentService {

  final AuthService _authService = AuthService();

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
  Future<Map<String, dynamic>> assignComplaintToStaff({
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
    return await assignComplaint(assignmentData);
  }

  /// Reassign complaint to different staff
  Future<Map<String, dynamic>> reassignComplaint({
    required String complaintId,
    required String newStaffId,
    required String assignedById,
    String? notes,
  }) async {
    try {
      final reassignData = {
        'complaintId': complaintId,
        'newStaffId': newStaffId,  // Note: Using newStaffId (matches backend)
        'assignedById': assignedById,
        'notes': notes ?? 'Reassigned by admin',
        'expectedCompletionDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      };

      print('📡 Reassigning complaint: $complaintId to staff: $newStaffId');
      print('📍 URL: ${ApiConfig.baseUrl}/assignments/reassign');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/reassign'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(reassignData),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reassign complaint');
      }
    } catch (e) {
      print('❌ Error reassigning complaint: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update assignment status (Accepted, Started, Completed)
  Future<Map<String, dynamic>> updateAssignmentStatus(String assignmentId, String status) async {
    try {
      final requestData = {
        'assignmentId': assignmentId,
        'status': status,
      };

      print('📡 Updating assignment status: $assignmentId to $status');
      print('📍 URL: ${ApiConfig.baseUrl}/assignments/update-status');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/update-status'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
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
      print('❌ Error loading assignments: $e');
      return [];
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
      print('❌ Error loading assignment history: $e');
      return [];
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
  // 3. GET COMPLAINTS
  // =====================================================

  /// Get pending complaints for approval
  Future<List<Complaint>> getPendingComplaintsForApproval() async {
    try {
      print('📡 Fetching pending complaints from: ${ApiConfig.baseUrl}/assignments/pending');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/pending'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

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

  /// Get complaints ready for assignment (Approved & Unassigned)
  Future<List<Complaint>> getComplaintsReadyForAssignment() async {
    try {
      print('📡 Fetching complaints for routing from: ${ApiConfig.baseUrl}/assignments/complaints/all');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assignments/complaints/all'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is List) {
          complaintsList = data;
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          complaintsList = data['data'];
        }

        print('📊 Found ${complaintsList.length} complaints ready for assignment');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading complaints for assignment: $e');
      return [];
    }
  }

  /// Get complaints by department for routing
  Future<List<Complaint>> getComplaintsByDepartmentForRouting(String departmentId) async {
    try {
      final url = '${ApiConfig.baseUrl}/assignments/complaints/department/$departmentId';
      print('📡 Fetching complaints for department: $departmentId');
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> complaintsList = [];

        if (data is List) {
          complaintsList = data;
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          complaintsList = data['data'];
        }

        print('📊 Found ${complaintsList.length} complaints for department');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading complaints by department: $e');
      return [];
    }
  }

  // =====================================================
  // 4. STAFF MANAGEMENT
  // =====================================================

  /// Get available staff for assignment (optionally filtered by department)
  Future<List<StaffProfile>> getAvailableStaff([String? departmentId]) async {
    try {
      String url = '${ApiConfig.baseUrl}/assignments/staff/available';
      if (departmentId != null && departmentId.isNotEmpty) {
        url += '?departmentId=$departmentId';
      }

      print('📡 Fetching available staff from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> staffList = [];

        if (data is Map && data.containsKey('Staff') && data['Staff'] is List) {
          staffList = data['Staff'];
          print('✅ Found ${staffList.length} staff in "Staff" array');
        } else if (data is List) {
          staffList = data;
          print('✅ Found ${staffList.length} staff (direct list)');
        }

        return staffList.map((json) => StaffProfile.fromJson(json)).toList();
      } else {
        print('❌ Failed to load staff: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading available staff: $e');
      return [];
    }
  }

  // =====================================================
  // 5. APPROVE & REJECT COMPLAINTS
  // =====================================================

  /// Approve a complaint
  Future<Map<String, dynamic>> approveComplaint({
    required String complaintId,
    required String approvedById,
    String? notes,
  }) async {
    try {
      print('📡 Approving complaint: $complaintId');
      print('📍 URL: ${ApiConfig.baseUrl}/assignments/approve/$complaintId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/approve/$complaintId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'approvedById': approvedById,
          'notes': notes ?? 'Approved by admin',
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to approve complaint');
      }
    } catch (e) {
      print('❌ Error approving complaint: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Reject a complaint with reason - FIXED to match backend
  Future<Map<String, dynamic>> rejectComplaint({
    required String complaintId,
    required String reason,
    String? rejectedById,
  }) async {
    try {
      print('📡 Rejecting complaint: $complaintId');
      print('📡 Reason: $reason');
      print('📍 URL: ${ApiConfig.baseUrl}/assignments/reject/$complaintId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/reject/$complaintId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'reason': reason,
          'rejectedById': rejectedById,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to reject complaint');
      }
    } catch (e) {
      print('❌ Error rejecting complaint: $e');
      throw Exception('Network error: $e');
    }
  }
}