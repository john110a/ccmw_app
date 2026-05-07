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
  // 3. VERIFY RESOLUTION - UPDATED
  // =====================================================

  /// Verify a resolved complaint (mark as verified)
  Future<void> verifyResolution(String resolutionId, {String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/$resolutionId/verify';
      print('📡 Verifying resolution at: $url');
      print('📡 Request body: ${json.encode({'notes': notes ?? 'Verified by admin'})}');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'notes': notes ?? 'Verified by admin'}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['Message'] != null) {
          print('✅ Resolution verified successfully');
          return;
        } else {
          throw Exception(data['Message'] ?? 'Failed to verify resolution');
        }
      } else {
        String errorMsg;
        try {
          final error = json.decode(response.body);
          errorMsg = error['Message'] ?? error['message'] ?? 'Failed to verify resolution';
        } catch (e) {
          errorMsg = 'Failed to verify resolution: ${response.statusCode}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Error verifying resolution: $e');
      rethrow;
    }
  }

  // =====================================================
  // 4. FLAG RESOLUTION - UPDATED
  // =====================================================

  /// Flag a resolution for rework (sends back to In Progress)
  Future<void> flagResolution(String resolutionId, String reason, {String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/$resolutionId/flag';
      print('📡 Flagging resolution at: $url');
      print('📡 Request body: ${json.encode({
        'reason': reason,
        'notes': notes ?? 'Flagged by admin'
      })}');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'reason': reason,
          'notes': notes ?? 'Flagged by admin'
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['Message'] != null) {
          print('✅ Resolution flagged successfully');
          return;
        } else {
          throw Exception(data['Message'] ?? 'Failed to flag resolution');
        }
      } else {
        String errorMsg;
        try {
          final error = json.decode(response.body);
          errorMsg = error['Message'] ?? error['message'] ?? 'Failed to flag resolution';
        } catch (e) {
          errorMsg = 'Failed to flag resolution: ${response.statusCode}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Error flagging resolution: $e');
      rethrow;
    }
  }

  // =====================================================
  // 5. GET RESOLUTION STATISTICS - UPDATED
  // =====================================================

  /// Get statistics about resolutions
  Future<Map<String, dynamic>> getResolutionStats() async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/stats';
      print('📡 Fetching resolution stats from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Stats loaded: $data');
        return {
          'PendingResolutions': data['PendingResolutions'] ?? 0,
          'VerifiedResolutions': data['VerifiedResolutions'] ?? 0,
          'TotalResolutions': data['TotalResolutions'] ?? 0,
          'ThisMonth': data['ThisMonth'] ?? 0,
        };
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
      print('📡 Uploading after photo for complaint: $complaintId');
      // Your multipart upload code here
      return true;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      return false;
    }
  }

  // =====================================================
  // 8. HELPER METHOD - GET FULL IMAGE URL
  // =====================================================

  /// Get full URL for an image path
  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash
    String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    // Get base URL without /api
    String baseUrl = ApiConfig.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    return '$baseUrl/$cleanPath';
  }
  // Add this method to get verified resolutions
  // Future<List<Resolution>> getVerifiedResolutions() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('${ApiConfig.baseUrl}/resolutions/all?status=verified&pageSize=50'),
  //       headers: ApiConfig.getHeaders(),
  //     ).timeout(const Duration(seconds: 10));
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final resolutions = data['Resolutions'] ?? [];
  //       return resolutions.map((json) => Resolution.fromJson(json)).toList();
  //     }
  //     return [];
  //   } catch (e) {
  //     print('❌ Error loading verified resolutions: $e');
  //     return [];
  //   }
  // }
  // =====================================================
// 9. GET VERIFIED RESOLUTIONS
// =====================================================

  /// Get verified resolutions
  Future<List<Resolution>> getVerifiedResolutions() async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/all?status=verified&pageSize=100';
      print('📡 Fetching verified resolutions from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> resolutionsList = [];

        if (data['Resolutions'] != null && data['Resolutions'] is List) {
          resolutionsList = data['Resolutions'];
        } else if (data is List) {
          resolutionsList = data;
        }

        print('✅ Found ${resolutionsList.length} verified resolutions');
        return resolutionsList.map((json) => Resolution.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading verified resolutions: $e');
      return [];
    }
  }

// =====================================================
// 10. GET FLAGGED RESOLUTIONS
// =====================================================

  /// Get flagged resolutions
  Future<List<Resolution>> getFlaggedResolutions() async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/all?status=flagged&pageSize=100';
      print('📡 Fetching flagged resolutions from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> resolutionsList = [];

        if (data['Resolutions'] != null && data['Resolutions'] is List) {
          resolutionsList = data['Resolutions'];
        } else if (data is List) {
          resolutionsList = data;
        }

        print('✅ Found ${resolutionsList.length} flagged resolutions');
        return resolutionsList.map((json) => Resolution.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading flagged resolutions: $e');
      return [];
    }
  }
}