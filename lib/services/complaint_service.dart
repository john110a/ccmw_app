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

  /// Get ALL complaints (for admin)
  Future<List<Complaint>> getAllComplaints({
    int page = 1,
    int pageSize = 50,
    String? status,
    String? zoneId,
    String? categoryId,
    String? departmentId,
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

      print('📡 Fetching complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response body type: ${data.runtimeType}');

        List<dynamic> complaintsList = [];

        if (data is Map) {
          print('📦 Response keys: ${data.keys}');

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
        }
        else if (data is List) {
          complaintsList = data;
          print('✅ Found ${complaintsList.length} complaints (direct list)');
        }

        // Fetch more pages if needed
        if (data is Map && data.containsKey('TotalPages') && data['TotalPages'] > page) {
          print('📄 Fetching page ${page + 1} of ${data['TotalPages']}');
          final nextPage = await getAllComplaints(
            page: page + 1,
            pageSize: pageSize,
            status: status,
            zoneId: zoneId,
            categoryId: categoryId,
            departmentId: departmentId,
          );
          complaintsList.addAll(nextPage);
        }

        print('🔍 DEBUG - Raw complaints list size: ${complaintsList.length}');
        final parsedComplaints = complaintsList.map((json) {
          print('📋 Raw JSON ID: ${json['ComplaintId']} - Title: ${json['Title']} - SubmissionStatus: ${json['SubmissionStatus']}');
          final complaint = Complaint.fromJson(json);
          print('📋 Parsed ID: ${complaint.complaintId} - submissionStatus: ${complaint.submissionStatus}');
          return complaint;
        }).toList();

        return parsedComplaints;
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