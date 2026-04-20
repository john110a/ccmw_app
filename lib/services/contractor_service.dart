// lib/services/contractor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import '../models/contract_performance_model.dart';
import '../models/contractor_model.dart';
import '../models/contractor_zone_model.dart';
import '../models/complaint_model.dart';
import 'AuthService.dart';
import 'api_config.dart';

class ContractorService {
  final AuthService _authService = AuthService();

  // =====================================================
  // 1. AUTHENTICATION
  // =====================================================

  /// Login for contractor (using staff login endpoint)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 Contractor login attempt for: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/staff/login'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'email': email,
          'passwordHash': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 2. CONTRACTOR PROFILE
  // =====================================================

  /// Get contractor details by ID
  Future<Contractor> getContractorProfile(String contractorId) async {
    try {
      print('📡 Fetching contractor profile: $contractorId');
      final url = '${ApiConfig.baseUrl}/contractors/$contractorId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Your backend returns { Contractor, AssignedZones, PerformanceHistory, etc. }
        // Extract the Contractor object
        final contractorData = data['Contractor'] ?? data;
        return Contractor.fromJson(contractorData);
      } else if (response.statusCode == 404) {
        throw Exception('Contractor not found');
      } else {
        throw Exception('Failed to load contractor profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading contractor profile: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get all contractors (for admin)
  Future<List<Contractor>> getAllContractors() async {
    try {
      print('📡 Fetching all contractors from: ${ApiConfig.baseUrl}/contractors');
      final url = '${ApiConfig.baseUrl}/contractors';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Handle response format - your backend returns { TotalContractors, ActiveContractors, Contractors }
        if (data is Map && data['Contractors'] != null && data['Contractors'] is List) {
          print('✅ Found ${data['Contractors'].length} contractors');
          return (data['Contractors'] as List).map((json) => Contractor.fromJson(json)).toList();
        } else if (data is List) {
          print('✅ Found ${data.length} contractors');
          return data.map((json) => Contractor.fromJson(json)).toList();
        } else {
          print('⚠️ Unexpected response format');
          return [];
        }
      } else {
        print('❌ Failed to load contractors: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading contractors: $e');
      return [];
    }
  }

  // =====================================================
  // 3. ZONE MANAGEMENT
  // =====================================================

  /// Get all zones assigned to contractor
  Future<List<ContractorZone>> getAssignedZones(String contractorId) async {
    try {
      print('📡 Fetching assigned zones for contractor: $contractorId');
      final url = '${ApiConfig.baseUrl}/contractors/$contractorId/zones';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response data keys: ${data.keys}');

        // Your backend returns { ContractorId, CompanyName, TotalZones, Zones }
        if (data is Map && data['Zones'] != null && data['Zones'] is List) {
          print('✅ Found ${data['Zones'].length} assigned zones');
          return (data['Zones'] as List).map((json) => ContractorZone.fromJson(json)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ No assigned zones found');
        return [];
      } else {
        print('❌ Failed to load assigned zones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading assigned zones: $e');
      return [];
    }
  }

  /// Get zone details by ID
  Future<Map<String, dynamic>> getZoneDetails(String zoneId) async {
    try {
      print('📡 Fetching zone details: $zoneId');
      final url = '${ApiConfig.baseUrl}/zones/$zoneId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        print('⚠️ Zone not found');
        return {};
      } else {
        print('❌ Failed to load zone details: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ Error loading zone details: $e');
      return {};
    }
  }

  /// Get available zones for assignment
  Future<List<Map<String, dynamic>>> getAvailableZones() async {
    try {
      // Try the exact endpoints from your backend
      List<String> endpointsToTry = [
        '${ApiConfig.baseUrl}/privatization/zones/available',
        '${ApiConfig.baseUrl}/contractor-zones/available-zones',
        '${ApiConfig.baseUrl}/zones/available',
      ];

      for (String endpoint in endpointsToTry) {
        try {
          print('📡 Trying endpoint: $endpoint');

          final response = await http.get(
            Uri.parse(endpoint),
            headers: ApiConfig.getHeaders(),
          ).timeout(const Duration(seconds: 5));

          print('📡 Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final dynamic data = json.decode(response.body);

            List<dynamic> zonesList = [];

            if (data is List) {
              zonesList = data;
            } else if (data is Map && data['data'] != null && data['data'] is List) {
              zonesList = data['data'];
            } else if (data is Map && data['zones'] != null && data['zones'] is List) {
              zonesList = data['zones'];
            } else if (data is Map && data['availableZones'] != null && data['availableZones'] is List) {
              zonesList = data['availableZones'];
            }

            if (zonesList.isNotEmpty) {
              print('✅ Found ${zonesList.length} available zones from $endpoint');

              return zonesList.map((zone) {
                return {
                  'zoneId': zone['zoneId']?.toString() ?? zone['id']?.toString() ?? '',
                  'zoneName': zone['zoneName']?.toString() ?? zone['name']?.toString() ?? 'Unknown Zone',
                  'zoneNumber': zone['zoneNumber']?.toString() ?? zone['number']?.toString() ?? 'N/A',
                  'city': zone['city']?.toString() ?? zone['City']?.toString() ?? 'City',
                  'province': zone['province']?.toString() ?? zone['Province']?.toString() ?? '',
                  'hasContractor': zone['hasContractor'] == true || zone['hasContractor'] == 'true',
                  'activeComplaints': zone['activeComplaints'] ?? zone['complaintCount'] ?? zone['ActiveComplaints'] ?? 0,
                };
              }).toList();
            } else {
              print('⚠️ No zones found in response from $endpoint');
            }
          }
        } catch (e) {
          print('⚠️ Endpoint $endpoint failed: $e');
        }
      }

      print('⚠️ All endpoints failed for available zones - returning empty list');
      return [];
    } catch (e) {
      print('❌ Critical error in getAvailableZones: $e');
      return [];
    }
  }

  /// Assign contractor to zone
  Future<Map<String, dynamic>> assignContractorToZone({
    required String contractorId,
    required String zoneId,
    required String assignedBy,
    required DateTime contractStart,
    required DateTime contractEnd,
    required String serviceType,
    required double contractValue,
    required double performanceBond,
  }) async {
    try {
      final requestBody = {
        'contractorId': contractorId,
        'zoneId': zoneId,
        'assignedBy': assignedBy,
        'contractStart': contractStart.toIso8601String(),
        'contractEnd': contractEnd.toIso8601String(),
        'serviceType': serviceType,
        'contractValue': contractValue,
        'performanceBond': performanceBond,
      };

      print('📡 Assigning contractor to zone with data: $requestBody');
      final url = '${ApiConfig.baseUrl}/contractors/assign-to-zone';
      print('📍 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Successfully assigned contractor to zone');
        return responseData;
      } else {
        throw Exception('Failed to assign contractor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error assigning contractor: $e');
      throw Exception('Failed to assign contractor: $e');
    }
  }

  /// Terminate contractor assignment
  Future<Map<String, dynamic>> terminateAssignment(
      String assignmentId, {
        required String reason,
        required String terminatedBy,
      }) async {
    try {
      print('📡 Terminating assignment: $assignmentId');
      final url = '${ApiConfig.baseUrl}/contractors/assignments/$assignmentId/terminate';
      print('📍 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'reason': reason,
          'terminatedBy': terminatedBy,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Assignment not found');
      } else {
        throw Exception('Failed to terminate assignment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error terminating assignment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get assignment history for a contractor
  Future<List<Map<String, dynamic>>> getAssignmentHistory(String contractorId) async {
    try {
      print('📡 Fetching assignment history for contractor: $contractorId');
      final url = '${ApiConfig.baseUrl}/contractor-zones/assignment-history/contractor/$contractorId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['history'] != null && data['history'] is List) {
          return List<Map<String, dynamic>>.from(data['history']);
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        return [];
      } else if (response.statusCode == 404) {
        print('ℹ️ No assignment history found');
        return [];
      } else {
        print('❌ Failed to load assignment history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading assignment history: $e');
      return [];
    }
  }

  // =====================================================
  // 4. CONTRACTOR DASHBOARD
  // =====================================================

  /// Get contractor dashboard data
  Future<Map<String, dynamic>> getContractorDashboard(String contractorId) async {
    try {
      print('📡 Fetching contractor dashboard for: $contractorId');
      final url = '${ApiConfig.baseUrl}/contractors/$contractorId/dashboard';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dashboard loaded successfully');
        print('📦 Response keys: ${data.keys}');
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Contractor not found');
      } else {
        throw Exception('Failed to load contractor dashboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading contractor dashboard: $e');
      throw Exception('Failed to load contractor dashboard: $e');
    }
  }

  // =====================================================
  // 5. COMPLAINT MANAGEMENT
  // =====================================================

  /// Get complaints for a specific zone
  Future<List<Complaint>> getZoneComplaints(String zoneId, {String? status}) async {
    try {
      String url = '${ApiConfig.baseUrl}/complaints?zoneId=$zoneId';
      if (status != null) {
        url += '&status=$status';
      }

      print('📡 Fetching complaints for zone: $zoneId');
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
        } else if (data is Map && data['complaints'] != null && data['complaints'] is List) {
          complaintsList = data['complaints'];
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          complaintsList = data['data'];
        }

        print('✅ Found ${complaintsList.length} complaints');
        return complaintsList.map((json) => Complaint.fromJson(json)).toList();
      } else {
        print('❌ Failed to load complaints: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading complaints: $e');
      return [];
    }
  }

  /// Get complaint details
  Future<Complaint?> getComplaintDetails(String complaintId) async {
    try {
      print('📡 Fetching complaint details: $complaintId');
      final url = '${ApiConfig.baseUrl}/complaints/$complaintId/view';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Complaint.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        print('⚠️ Complaint not found');
        return null;
      } else {
        print('❌ Failed to load complaint details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error loading complaint details: $e');
      return null;
    }
  }

  /// Update complaint status
  Future<Map<String, dynamic>> updateComplaintStatus(
      String complaintId,
      int newStatus,
      String userId
      ) async {
    try {
      print('📡 Updating complaint status: $complaintId to $newStatus');
      final url = '${ApiConfig.baseUrl}/complaints/$complaintId/status?newStatus=$newStatus&userId=$userId';
      print('📍 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 6. PHOTO UPLOAD
  // =====================================================

  /// Upload resolution photo
  Future<bool> uploadResolutionPhoto(
      String assignmentId,
      String staffId,
      File imageFile
      ) async {
    try {
      print('📡 Uploading resolution photo for assignment: $assignmentId');
      final url = '${ApiConfig.baseUrl}/complaint-media/assignment/$assignmentId/resolution/upload?staffId=$staffId';
      print('📍 URL: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      print('📡 Upload response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }

  /// Get photos for a complaint
  Future<List<dynamic>> getComplaintPhotos(String complaintId) async {
    try {
      print('📡 Fetching photos for complaint: $complaintId');
      final url = '${ApiConfig.baseUrl}/complaint-media/complaint/$complaintId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data['Photos'] ?? [];
      } else {
        print('❌ Failed to load photos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading photos: $e');
      return [];
    }
  }

  // =====================================================
  // 7. PERFORMANCE & REPORTS
  // =====================================================

  /// Get contractor performance history
  Future<List<ContractPerformance>> getPerformanceHistory(String contractorId) async {
    try {
      print('📡 Fetching performance history for contractor: $contractorId');
      final url = '${ApiConfig.baseUrl}/contractors/$contractorId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Your backend returns PerformanceHistory in the response
        if (data is Map && data['PerformanceHistory'] != null && data['PerformanceHistory'] is List) {
          print('✅ Found ${data['PerformanceHistory'].length} performance records');
          return (data['PerformanceHistory'] as List)
              .map((json) => ContractPerformance.fromJson(json))
              .toList();
        } else {
          print('ℹ️ No performance history found');
          return [];
        }
      } else {
        print('❌ Failed to load performance history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading performance history: $e');
      return [];
    }
  }

  /// Get current contractor performance summary
  Future<Map<String, dynamic>> getPerformanceSummary(String contractorId) async {
    try {
      final history = await getPerformanceHistory(contractorId);

      if (history.isEmpty) {
        return {
          'totalComplaints': 0,
          'resolvedComplaints': 0,
          'averageResolutionTime': 0,
          'slaComplianceRate': 0,
          'performanceScore': 0,
        };
      }

      // Calculate averages from history
      final latest = history.first;
      final totalComplaints = history.fold<int>(
          0, (sum, item) => sum + item.complaintsHandled
      );
      final totalResolved = history.fold<int>(
          0, (sum, item) => sum + item.complaintsResolved
      );
      final avgSla = history.fold<double>(
          0, (sum, item) => sum + item.slaComplianceRate
      ) / history.length;
      final avgScore = history.fold<double>(
          0, (sum, item) => sum + item.performanceScore
      ) / history.length;

      return {
        'totalComplaints': totalComplaints,
        'resolvedComplaints': totalResolved,
        'averageResolutionTime': latest.averageResolutionTimeDays,
        'slaComplianceRate': avgSla,
        'performanceScore': avgScore,
        'latestPeriod': {
          'start': latest.reviewPeriodStart,
          'end': latest.reviewPeriodEnd,
          'score': latest.performanceScore,
        },
      };
    } catch (e) {
      print('❌ Error calculating performance summary: $e');
      return {
        'totalComplaints': 0,
        'resolvedComplaints': 0,
        'averageResolutionTime': 0,
        'slaComplianceRate': 0,
        'performanceScore': 0,
      };
    }
  }

  /// Get monthly performance report
  Future<Map<String, dynamic>> getMonthlyReport(
      String contractorId,
      int year,
      int month
      ) async {
    try {
      final history = await getPerformanceHistory(contractorId);

      final monthlyData = history.where((item) =>
      item.reviewPeriodStart.year == year &&
          item.reviewPeriodStart.month == month
      ).toList();

      if (monthlyData.isEmpty) {
        return {
          'exists': false,
          'message': 'No data for $month/$year',
        };
      }

      final report = monthlyData.first;
      return {
        'exists': true,
        'period': '${report.reviewPeriodStart.month}/${report.reviewPeriodStart.year}',
        'complaintsHandled': report.complaintsHandled,
        'complaintsResolved': report.complaintsResolved,
        'resolutionRate': report.complaintsHandled > 0
            ? (report.complaintsResolved / report.complaintsHandled * 100)
            : 0,
        'averageResolutionTime': report.averageResolutionTimeDays,
        'slaCompliance': report.slaComplianceRate,
        'citizenRating': report.citizenSatisfactionScore,
        'performanceScore': report.performanceScore,
        'penalties': report.penaltiesIncurred,
        'bonuses': report.bonusesEarned,
        'notes': report.reviewNotes,
      };
    } catch (e) {
      print('❌ Error loading monthly report: $e');
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  // =====================================================
  // 8. TASK MANAGEMENT
  // =====================================================

  /// Get staff ID for contractor (if contractor is also a staff user)
  Future<String?> getStaffId(String userId) async {
    try {
      print('📡 Fetching staff ID for user: $userId');
      final url = '${ApiConfig.baseUrl}/staff?userId=$userId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> staffList = [];
        if (data is List) {
          staffList = data;
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          staffList = data['data'];
        } else if (data is Map && data['staff'] != null && data['staff'] is List) {
          staffList = data['staff'];
        }

        if (staffList.isNotEmpty) {
          return staffList.first['staffId']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting staff ID: $e');
      return null;
    }
  }

  /// Get assignments for contractor's staff
  Future<List<dynamic>> getAssignments(String staffId) async {
    try {
      print('📡 Fetching assignments for staff: $staffId');
      final url = '${ApiConfig.baseUrl}/staff-actions/staff/$staffId/assignments';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is List) {
          return data;
        } else if (data is Map && data['assignments'] != null && data['assignments'] is List) {
          return data['assignments'];
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          return data['data'];
        }

        return [];
      } else {
        print('❌ Failed to load assignments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading assignments: $e');
      return [];
    }
  }

  /// Accept assignment
  Future<Map<String, dynamic>> acceptAssignment(
      String assignmentId,
      String staffId
      ) async {
    try {
      print('📡 Accepting assignment: $assignmentId');
      final url = '${ApiConfig.baseUrl}/staff-actions/assignments/$assignmentId/accept?staffId=$staffId';
      print('📍 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': response.body};
      } else {
        throw Exception('Failed to accept assignment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accepting assignment: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Resolve assignment
  Future<Map<String, dynamic>> resolveAssignment(
      String assignmentId,
      String staffId,
      String resolutionNotes
      ) async {
    try {
      print('📡 Resolving assignment: $assignmentId');
      final url = '${ApiConfig.baseUrl}/staff-actions/assignments/$assignmentId/resolve?staffId=$staffId';
      print('📍 URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode(resolutionNotes),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': response.body};
      } else {
        throw Exception('Failed to resolve assignment: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error resolving assignment: $e');
      throw Exception('Network error: $e');
    }
  }

  // =====================================================
  // 9. HELPER METHODS
  // =====================================================

  /// Check if API is reachable
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Add performance record (for admin)
  Future<void> addPerformanceRecord(String contractorId, Map<String, dynamic> performanceData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/contractors/$contractorId/performance'),
      headers: ApiConfig.getHeaders(),
      body: json.encode(performanceData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add performance record');
    }
  }
}