// lib/services/complaint_service.dart - UPDATED TO MATCH BACKEND

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/ComplaintStatusHistory.dart';
import '../models/complaint_model.dart';
import '../models/complaint_photo_model.dart';
import 'api_config.dart';
import 'AuthService.dart';

class ComplaintService {
  final AuthService _authService = AuthService();

  /// Submit new complaint
  Future<Map<String, dynamic>> submitComplaint(Map<String, dynamic> complaintData) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login again.');
      }

      final Map<String, dynamic> requestData = {
        ...complaintData,
        'citizenId': userId,
      };

      print('📤 Submitting complaint to: ${ApiConfig.baseUrl}/complaints/submit');
      print('📦 Request data: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/complaints/submit'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        try {
          final error = json.decode(response.body);
          final errorMsg = error['Message'] ?? error['message'] ?? error['error'] ?? 'Unknown error';
          throw Exception('Server error: $errorMsg');
        } catch (_) {
          throw Exception('Failed to submit complaint (Status: ${response.statusCode})');
        }
      }
    } on SocketException {
      throw Exception('Network error: Cannot connect to server. Check your internet connection.');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: $e');
    } catch (e) {
      print('❌ Error submitting complaint: $e');
      rethrow;
    }
  }

  /// Get user complaints
  Future<List<Complaint>> getUserComplaints() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/user/$userId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Complaint.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading complaints: $e');
      return [];
    }
  }

  /// Get ALL complaints (for admin) - FIXED: System_Admin sees ALL complaints
  Future<List<Complaint>> getAllComplaints({
    int page = 1,
    int pageSize = 100,
    String? status,
    String? zoneId,
    String? categoryId,
    String? departmentId,
  }) async {
    try {
      // Check if user is System_Admin
      final userType = await _authService.getUserType();
      final isSystemAdmin = userType == 'System_Admin';

      String url = '${ApiConfig.baseUrl}/complaints?page=$page&pageSize=$pageSize';

      // IMPORTANT: Only filter by department if NOT system admin
      if (departmentId != null) {
        url += '&departmentId=$departmentId';
      } else if (!isSystemAdmin) {
        // For department admins, automatically filter by their department
        final departmentIdFromStorage = await _authService.getDepartmentId();
        if (departmentIdFromStorage != null && departmentIdFromStorage.isNotEmpty) {
          url += '&departmentId=$departmentIdFromStorage';
          print('📋 Filtering by department: $departmentIdFromStorage');
        }
      } else {
        print('👑 System Admin - Showing ALL complaints across all departments');
      }

      if (status != null) {
        url += '&status=$status';
      }
      if (zoneId != null) {
        url += '&zoneId=$zoneId';
      }
      if (categoryId != null) {
        url += '&categoryId=$categoryId';
      }

      print('📡 Fetching complaints from: $url');
      print('👤 User type: $userType, IsSystemAdmin: $isSystemAdmin');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response body type: ${data.runtimeType}');

        List<Complaint> allComplaints = [];

        if (data is Map) {
          print('📦 Response keys: ${data.keys}');

          // Get pagination info
          int totalPages = data['TotalPages'] ?? data['totalPages'] ?? 1;
          int currentPage = data['Page'] ?? data['page'] ?? page;
          int totalCount = data['TotalCount'] ?? data['totalCount'] ?? 0;

          print('📊 Total complaints in DB: $totalCount');
          print('📊 Total pages: $totalPages, Current page: $currentPage');
          print('📊 Page size: $pageSize');

          // Extract complaints from current page
          List<dynamic> complaintsList = [];

          if (data.containsKey('Complaints') && data['Complaints'] is List) {
            complaintsList = data['Complaints'];
            print('✅ Found ${complaintsList.length} complaints in "Complaints"');
          }
          else if (data.containsKey('complaints') && data['complaints'] is List) {
            complaintsList = data['complaints'];
            print('✅ Found ${complaintsList.length} complaints in "complaints"');
          }
          else if (data.containsKey('data') && data['data'] is List) {
            complaintsList = data['data'];
            print('✅ Found ${complaintsList.length} complaints in "data"');
          }
          else if (data.containsKey('results') && data['results'] is List) {
            complaintsList = data['results'];
            print('✅ Found ${complaintsList.length} complaints in "results"');
          }

          // Parse current page complaints
          for (var json in complaintsList) {
            try {
              allComplaints.add(Complaint.fromJson(json));
            } catch (e) {
              print('❌ Error parsing complaint: $e');
            }
          }

          // If there are more pages, fetch them (only for system admin or if needed)
          if (currentPage < totalPages && totalCount > allComplaints.length) {
            print('📄 Fetching remaining pages from ${currentPage + 1} to $totalPages');

            // Fetch all remaining pages
            for (int p = currentPage + 1; p <= totalPages; p++) {
              try {
                String nextUrl = '${ApiConfig.baseUrl}/complaints?page=$p&pageSize=$pageSize';

                // Apply same filtering logic for subsequent pages
                if (departmentId != null) {
                  nextUrl += '&departmentId=$departmentId';
                } else if (!isSystemAdmin) {
                  final departmentIdFromStorage = await _authService.getDepartmentId();
                  if (departmentIdFromStorage != null && departmentIdFromStorage.isNotEmpty) {
                    nextUrl += '&departmentId=$departmentIdFromStorage';
                  }
                }

                if (status != null) nextUrl += '&status=$status';
                if (zoneId != null) nextUrl += '&zoneId=$zoneId';
                if (categoryId != null) nextUrl += '&categoryId=$categoryId';

                print('📡 Fetching page $p from: $nextUrl');

                final nextResponse = await http.get(
                  Uri.parse(nextUrl),
                  headers: ApiConfig.getHeaders(),
                ).timeout(const Duration(seconds: 15));

                if (nextResponse.statusCode == 200) {
                  final nextData = json.decode(nextResponse.body);
                  List<dynamic> nextComplaintsList = [];

                  if (nextData.containsKey('Complaints') && nextData['Complaints'] is List) {
                    nextComplaintsList = nextData['Complaints'];
                  }
                  else if (nextData.containsKey('complaints') && nextData['complaints'] is List) {
                    nextComplaintsList = nextData['complaints'];
                  }
                  else if (nextData.containsKey('data') && nextData['data'] is List) {
                    nextComplaintsList = nextData['data'];
                  }

                  for (var json in nextComplaintsList) {
                    try {
                      allComplaints.add(Complaint.fromJson(json));
                    } catch (e) {
                      print('❌ Error parsing complaint on page $p: $e');
                    }
                  }
                  print('✅ Page $p loaded: ${nextComplaintsList.length} complaints');
                }
              } catch (e) {
                print('❌ Error fetching page $p: $e');
              }
            }
          }
        }
        else if (data is List) {
          // Direct list response (no pagination)
          print('✅ Found ${data.length} complaints (direct list)');
          for (var json in data) {
            try {
              allComplaints.add(Complaint.fromJson(json));
            } catch (e) {
              print('❌ Error parsing complaint: $e');
            }
          }
        }

        print('✅ Total complaints loaded: ${allComplaints.length}');
        return allComplaints;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading all complaints: $e');
      return [];
    }
  }

  /// Get complaint details
  Future<Complaint> getComplaintDetails(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/view'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Complaint.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load complaint details');
      }
    } catch (e) {
      print('❌ Error loading complaint details: $e');
      rethrow;
    }
  }

  /// Upload photo
  Future<bool> uploadPhoto(String complaintId, File imageFile, {String photoType = 'Complaint'}) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/complaint-media/complaint/$complaintId/upload?uploadedById=$userId'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload failed: $e');
      return false;
    }
  }

  /// Upload multiple photos
  Future<bool> uploadMultiplePhotos(String complaintId, List<File> imageFiles) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      for (var imageFile in imageFiles) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/complaint-media/complaint/$complaintId/upload?uploadedById=$userId'),
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
          throw Exception('Failed to upload image');
        }
      }
      return true;
    } catch (e) {
      print('❌ Multiple upload failed: $e');
      return false;
    }
  }

  /// Get complaint photos
  Future<List<ComplaintPhoto>> getComplaintPhotos(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaint-media/complaint/$complaintId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> photos = data['Photos'] ?? [];
        return photos.map((json) => ComplaintPhoto.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading photos: $e');
      return [];
    }
  }

  /// =====================================================
  /// UPDATE COMPLAINT STATUS - MATCHES BACKEND EXACTLY
  /// Backend expects: newStatus as string (e.g., "Approved", "Rejected")
  /// Backend also updates SubmissionStatus automatically
  /// =====================================================
  Future<Map<String, dynamic>> updateStatus(String complaintId, String newStatus) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // Valid status values that backend accepts
      final validStatuses = ['Approved', 'Rejected', 'Assigned', 'InProgress', 'Resolved', 'Verified', 'Closed', 'Submitted'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Invalid status: $newStatus. Must be one of: ${validStatuses.join(", ")}');
      }

      final url = '${ApiConfig.baseUrl}/complaints/$complaintId/status?newStatus=$newStatus&userId=$userId';

      print('📡 Updating complaint status: $complaintId to $newStatus');
      print('📍 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Status updated successfully');
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'message': decoded.toString()};
        }
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      rethrow;
    }
  }

  /// Get map complaints
  Future<List<Complaint>> getMapComplaints({
    required double lat,
    required double lng,
    required double radiusKm,
    String? categoryId,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/map/complaints?lat=$lat&lng=$lng&radiusKm=$radiusKm';

      if (categoryId != null) {
        url += '&categoryId=$categoryId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> complaints = data['data'] ?? [];
        return complaints.map((json) => Complaint.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading map complaints: $e');
      return [];
    }
  }
// Add to complaint_service.dart
  // lib/services/complaint_service.dart
// Add this method to existing ComplaintService class

  /// Mark complaint as fake (Admin only)
  Future<Map<String, dynamic>> markAsFake(String complaintId, String adminId) async {
    try {
      print('📡 Marking complaint as fake: $complaintId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/mark-fake'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'adminId': adminId}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to mark as fake');
      }
    } catch (e) {
      print('❌ Error marking as fake: $e');
      rethrow;
    }
  }

  /// Get citizen's strike info
  Future<Map<String, dynamic>> getCitizenStrikes(String citizenId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/citizen/$citizenId/strikes'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'strikes': 0, 'isBanned': false, 'message': ''};
    } catch (e) {
      print('❌ Error getting strikes: $e');
      return {'strikes': 0, 'isBanned': false, 'message': ''};
    }
  }

  /// Get fake complaints list (Admin only)
  Future<Map<String, dynamic>> getFakeComplaints({int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/fake-complaints?page=$page&pageSize=$pageSize'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'TotalCount': 0, 'FakeComplaints': []};
    } catch (e) {
      print('❌ Error getting fake complaints: $e');
      return {'TotalCount': 0, 'FakeComplaints': []};
    }
  }
  /// Get complaint status history
  Future<List<ComplaintStatusHistory>> getComplaintStatusHistory(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaint-status-history/complaint/$complaintId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => ComplaintStatusHistory.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading status history: $e');
      return [];
    }
  }
}