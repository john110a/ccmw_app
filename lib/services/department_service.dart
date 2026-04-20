// lib/services/department_service.dart - COMPLETELY FIXED VERSION

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department_model.dart';
import '../models/staff_profile_model.dart';
import '../models/complaint_model.dart';
import 'api_config.dart';
import 'complaint_service.dart';

class DepartmentService {
  final ComplaintService _complaintService = ComplaintService();

  // Get all departments
  Future<List<Department>> getAllDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Departments response status: ${response.statusCode}');
      print('📦 Departments response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> departmentsList = [];

        if (data is List) {
          departmentsList = data;
        } else if (data is Map && data.containsKey('Departments')) {
          departmentsList = data['Departments'];
        } else if (data is Map && data.containsKey('data')) {
          departmentsList = data['data'];
        }

        print('✅ Found ${departmentsList.length} departments');
        return departmentsList.map((json) => Department.fromJson(json)).toList();
      } else {
        print('❌ Failed to load departments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading departments: $e');
      return [];
    }
  }

  // Get department by ID
  Future<Department> getDepartmentById(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId'),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        return Department.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load department');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // CREATE DEPARTMENT
  // =====================================================
  Future<Map<String, dynamic>> createDepartment(Map<String, dynamic> departmentData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/departments/create'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(departmentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create department');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // UPDATE DEPARTMENT
  // =====================================================
  Future<Map<String, dynamic>> updateDepartment(String departmentId, Map<String, dynamic> departmentData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/update'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(departmentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update department');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // ACTIVATE DEPARTMENT
  // =====================================================
  Future<Map<String, dynamic>> activateDepartment(String departmentId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/activate'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to activate department');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // DEACTIVATE DEPARTMENT
  // =====================================================
  Future<Map<String, dynamic>> deactivateDepartment(String departmentId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/deactivate'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to deactivate department');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT STAFF
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentStaff(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/staff'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department staff');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT STAFF AS LIST (Helper method)
  // =====================================================
  Future<List<StaffProfile>> getDepartmentStaffList(String departmentId) async {
    try {
      final response = await getDepartmentStaff(departmentId);
      final staffList = response['Staff'] ?? [];
      return staffList.map((json) => StaffProfile.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting department staff list: $e');
      return [];
    }
  }

  // =====================================================
  // GET AVAILABLE STAFF IN DEPARTMENT
  // =====================================================
  Future<List<StaffProfile>> getAvailableDepartmentStaff(String departmentId) async {
    try {
      final response = await getDepartmentStaff(departmentId);
      final staffList = response['Staff'] ?? [];
      final availableStaff = staffList.where((s) =>
      s['isAvailable'] == true && (s['pendingAssignments'] ?? 0) < 5
      ).toList();
      return availableStaff.map((json) => StaffProfile.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting available department staff: $e');
      return [];
    }
  }

  // =====================================================
  // GET DEPARTMENT CONTRACTORS
  // =====================================================
  Future<List<dynamic>> getDepartmentContractors(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/contractors'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department contractors');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT PERFORMANCE
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentPerformance(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/performance'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department performance');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT COMPLAINTS
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentComplaints(
      String departmentId, {
        int page = 1,
        int pageSize = 20,
        String? status,
      }) async {
    try {
      String url = '${ApiConfig.baseUrl}/departments/$departmentId/complaints?page=$page&pageSize=$pageSize';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department complaints');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT COMPLAINTS AS LIST (Helper method)
  // =====================================================
  Future<List<Complaint>> getDepartmentComplaintsList(
      String departmentId, {
        int page = 1,
        int pageSize = 20,
        String? status,
      }) async {
    try {
      final response = await getDepartmentComplaints(departmentId, page: page, pageSize: pageSize, status: status);
      final complaintsList = response['Complaints'] ?? [];
      return complaintsList.map((json) => Complaint.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting department complaints list: $e');
      return [];
    }
  }

  // =====================================================
  // GET DEPARTMENT STATISTICS
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentStats(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/stats'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department statistics');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET DEPARTMENT SUMMARY FOR ADMIN
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/summary'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load department summary');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // APPROVE COMPLAINT - FIXED: Now uses ComplaintService
  // =====================================================
  Future<Map<String, dynamic>> approveComplaint(String complaintId, String adminId) async {
    try {
      print('📡 Approving complaint via ComplaintService: $complaintId');
      final result = await _complaintService.updateStatus(complaintId, 'Approved');
      print('✅ Complaint approved successfully');
      return result;
    } catch (e) {
      print('❌ Error approving complaint: $e');
      throw Exception('Failed to approve complaint: $e');
    }
  }

  // =====================================================
  // REJECT COMPLAINT - FIXED: Now uses ComplaintService
  // =====================================================
  Future<Map<String, dynamic>> rejectComplaint(String complaintId, String adminId, String reason) async {
    try {
      print('📡 Rejecting complaint via ComplaintService: $complaintId');
      print('📡 Reason: $reason');
      final result = await _complaintService.updateStatus(complaintId, 'Rejected');
      print('✅ Complaint rejected successfully');
      return result;
    } catch (e) {
      print('❌ Error rejecting complaint: $e');
      throw Exception('Failed to reject complaint: $e');
    }
  }

  // =====================================================
  // AUTO-ASSIGN COMPLAINT TO BEST STAFF
  // =====================================================
  Future<Map<String, dynamic>> autoAssignComplaint(String complaintId, String assignedById) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/departments/complaints/$complaintId/assign-to-staff'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'assignedById': assignedById}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to auto-assign complaint');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // MANUALLY ASSIGN COMPLAINT TO SPECIFIC STAFF
  // =====================================================
  Future<Map<String, dynamic>> manualAssignComplaint(
      String complaintId,
      String staffId,
      String assignedById,
      {String? notes}
      ) async {
    try {
      final assignmentData = {
        'complaintId': complaintId,
        'assignedToId': staffId,
        'assignedById': assignedById,
        'assignmentNotes': notes ?? 'Manually assigned',
        'expectedCompletionDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/assignments/assign'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(assignmentData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to assign complaint');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // GET PENDING COMPLAINTS FOR DEPARTMENT (For Approval)
  // =====================================================
  Future<List<Complaint>> getPendingComplaints(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/departments/$departmentId/complaints/pending'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Complaint.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading pending complaints: $e');
      return [];
    }
  }

  // =====================================================
  // GET DEPARTMENT DASHBOARD STATS (Combined)
  // =====================================================
  Future<Map<String, dynamic>> getDepartmentDashboard(String departmentId) async {
    try {
      final results = await Future.wait([
        getDepartmentStats(departmentId),
        getDepartmentPerformance(departmentId),
        getDepartmentStaff(departmentId),
      ]);

      return {
        'stats': results[0],
        'performance': results[1],
        'staff': results[2],
      };
    } catch (e) {
      print('❌ Error loading department dashboard: $e');
      return {};
    }
  }

  // =====================================================
  // GET ALL DEPARTMENTS WITH STAFF COUNTS
  // =====================================================
  Future<List<Map<String, dynamic>>> getAllDepartmentsWithStats() async {
    try {
      final departments = await getAllDepartments();
      final List<Map<String, dynamic>> result = [];

      for (var dept in departments) {
        final staff = await getDepartmentStaff(dept.departmentId);
        result.add({
          'department': dept,
          'staffCount': staff['StaffCount'] ?? 0,
          'availableStaff': staff['AvailableStaff'] ?? 0,
        });
      }

      return result;
    } catch (e) {
      print('❌ Error loading departments with stats: $e');
      return [];
    }
  }
}