// lib/services/resolution_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resolution_model.dart';
import 'api_config.dart';

class ResolutionService {

  // =====================================================
  // 1. GET PENDING RESOLUTIONS
  // =====================================================

  /// Get complaints that are resolved and need verification
  Future<List<Resolution>> getPendingResolutions() async {
    try {
      print('📡 Fetching pending resolutions from: ${ApiConfig.baseUrl}/resolutions/pending');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/resolutions/pending'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response body: $data');

        List<dynamic> resolutionsList = [];

        if (data is List) {
          resolutionsList = data;
        } else if (data is Map && data['data'] != null) {
          if (data['data'] is List) {
            resolutionsList = data['data'];
          }
        } else if (data is Map && data['resolutions'] != null) {
          if (data['resolutions'] is List) {
            resolutionsList = data['resolutions'];
          }
        }

        print('✅ Found ${resolutionsList.length} pending resolutions');
        return resolutionsList.map((json) => Resolution.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('⚠️ Pending resolutions endpoint not found');
        return [];
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading resolutions: $e');
      return [];
    }
  }

  // =====================================================
  // 2. GET ALL RESOLUTIONS WITH PAGINATION
  // =====================================================

  /// Get all resolutions with pagination and optional status filter
  Future<Map<String, dynamic>> getAllResolutions({
    int page = 1,
    int pageSize = 20,
    String? status, // 'pending' or 'verified'
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/resolutions/all?page=$page&pageSize=$pageSize';
      if (status != null) {
        url += '&status=$status';
      }

      print('📡 Fetching all resolutions from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('⚠️ Failed to load resolutions: ${response.statusCode}');
        return {
          'Total': 0,
          'Page': page,
          'PageSize': pageSize,
          'TotalPages': 0,
          'Resolutions': [],
        };
      }
    } catch (e) {
      print('❌ Error loading all resolutions: $e');
      return {
        'Total': 0,
        'Page': page,
        'PageSize': pageSize,
        'TotalPages': 0,
        'Resolutions': [],
      };
    }
  }

  // =====================================================
  // 3. VERIFY RESOLUTION
  // =====================================================

  /// Verify a resolved complaint (mark as verified)
  Future<void> verifyResolution(String resolutionId, {String? notes}) async {
    try {
      print('📡 Verifying resolution: $resolutionId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/resolutions/$resolutionId/verify'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'notes': notes}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify resolution');
      }

      print('✅ Resolution verified successfully');
    } catch (e) {
      print('❌ Error verifying resolution: $e');
      rethrow;
    }
  }

  // =====================================================
  // 4. FLAG RESOLUTION (SEND BACK FOR REWORK)
  // =====================================================

  /// Flag a resolution for rework (sends back to In Progress)
  Future<void> flagResolution(String resolutionId, String reason, {String? notes}) async {
    try {
      print('📡 Flagging resolution: $resolutionId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/resolutions/$resolutionId/flag'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'reason': reason,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to flag resolution');
      }

      print('✅ Resolution flagged successfully');
    } catch (e) {
      print('❌ Error flagging resolution: $e');
      rethrow;
    }
  }

  // =====================================================
  // 5. GET RESOLUTION STATISTICS
  // =====================================================

  /// Get statistics about resolutions
  Future<Map<String, dynamic>> getResolutionStats() async {
    try {
      print('📡 Fetching resolution stats from: ${ApiConfig.baseUrl}/resolutions/stats');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/resolutions/stats'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Stats loaded: $data');
        return data;
      } else {
        print('⚠️ Failed to load stats: ${response.statusCode}');
        return {
          'PendingResolutions': 0,
          'VerifiedResolutions': 0,
          'TotalResolutions': 0,
          'ThisMonth': 0,
        };
      }
    } catch (e) {
      print('❌ Error loading resolution stats: $e');
      return {
        'PendingResolutions': 0,
        'VerifiedResolutions': 0,
        'TotalResolutions': 0,
        'ThisMonth': 0,
      };
    }
  }

  // =====================================================
  // 6. MARK COMPLAINT AS RESOLVED (FOR STAFF)
  // =====================================================

  /// Mark a complaint as resolved (called by staff when work is done)
  Future<void> markAsResolved(String complaintId, {
    required String resolvedById,
    required String resolutionNotes,
    String? afterPhotoUrl,
  }) async {
    try {
      print('📡 Marking complaint as resolved: $complaintId');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/mark-resolved'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'resolvedById': resolvedById,
          'resolutionNotes': resolutionNotes,
          'afterPhotoUrl': afterPhotoUrl,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to mark complaint as resolved');
      }

      print('✅ Complaint marked as resolved');
    } catch (e) {
      print('❌ Error marking complaint as resolved: $e');
      rethrow;
    }
  }

  // =====================================================
  // 7. UPLOAD RESOLUTION PHOTO
  // =====================================================

  /// Upload after photo for resolution
  Future<bool> uploadAfterPhoto(String complaintId, String imagePath) async {
    try {
      // This would use MultipartRequest - implement based on your backend
      print('📡 Uploading after photo for complaint: $complaintId');

      // Your multipart upload code here

      return true;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      return false;
    }
  }
}