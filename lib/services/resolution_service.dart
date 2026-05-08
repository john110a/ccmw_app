// lib/services/resolution_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resolution_model.dart';
import 'api_config.dart';

class ResolutionService {

  // =====================================================
  // 1. GET PENDING RESOLUTIONS
  // =====================================================

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

  Future<Map<String, dynamic>> getAllResolutions({
    int page = 1,
    int pageSize = 20,
    String? status,
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

  Future<void> verifyResolution(String resolutionId, {String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/$resolutionId/verify';
      print('📡 Verifying resolution at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({'notes': notes ?? 'Verified by admin'}),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

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
  // 4. FLAG RESOLUTION
  // =====================================================

  Future<void> flagResolution(String resolutionId, String reason, {String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/$resolutionId/flag';
      print('📡 Flagging resolution at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'reason': reason,
          'notes': notes ?? 'Flagged by admin'
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

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
  // 5. GET RESOLUTION STATISTICS
  // =====================================================

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
          'FlaggedResolutions': data['FlaggedResolutions'] ?? 0,
          'TotalResolutions': data['TotalResolutions'] ?? 0,
          'ThisMonth': data['ThisMonth'] ?? 0,
        };
      } else {
        print('⚠️ Failed to load stats: ${response.statusCode}');
        return {
          'PendingResolutions': 0,
          'VerifiedResolutions': 0,
          'FlaggedResolutions': 0,
          'TotalResolutions': 0,
          'ThisMonth': 0,
        };
      }
    } catch (e) {
      print('❌ Error loading resolution stats: $e');
      return {
        'PendingResolutions': 0,
        'VerifiedResolutions': 0,
        'FlaggedResolutions': 0,
        'TotalResolutions': 0,
        'ThisMonth': 0,
      };
    }
  }

  // =====================================================
  // 6. MARK COMPLAINT AS RESOLVED (FOR STAFF)
  // =====================================================

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

  Future<bool> uploadAfterPhoto(String complaintId, String imagePath) async {
    try {
      print('📡 Uploading after photo for complaint: $complaintId');
      return true;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      return false;
    }
  }

  // =====================================================
  // 8. HELPER METHOD - GET FULL IMAGE URL
  // =====================================================

  static String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    String baseUrl = ApiConfig.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    return '$baseUrl/$cleanPath';
  }

  // =====================================================
  // 9. GET VERIFIED RESOLUTIONS
  // =====================================================

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
  // 10. GET FLAGGED COMPLAINTS (FAKE COMPLAINTS) - FIXED
  // =====================================================

  /// Get flagged/fake complaints for verification
  Future<List<Map<String, dynamic>>> getFlaggedComplaints() async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/flagged';
      print('📡 Fetching flagged complaints from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> complaints = [];

        if (data['complaints'] != null && data['complaints'] is List) {
          complaints = List<Map<String, dynamic>>.from(data['complaints']);
        } else if (data is List) {
          complaints = List<Map<String, dynamic>>.from(data);
        }

        print('✅ Found ${complaints.length} flagged complaints');
        return complaints;
      } else if (response.statusCode == 404) {
        print('⚠️ Flagged complaints endpoint not found');
        return [];
      } else {
        print('⚠️ Failed to fetch flagged complaints: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching flagged complaints: $e');
      return [];
    }
  }

  // =====================================================
  // 11. GET FLAGGED COMPLAINT DETAILS
  // =====================================================

  Future<Map<String, dynamic>?> getFlaggedComplaintDetails(String complaintId) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/flagged/$complaintId';
      print('📡 Fetching flagged complaint details from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['complaint'] ?? data;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching flagged complaint details: $e');
      return null;
    }
  }

  // =====================================================
  // 12. MARK FLAGGED COMPLAINT AS GENUINE
  // =====================================================

  Future<bool> verifyGenuineComplaint(String complaintId, {String? adminId, String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/flagged/$complaintId/verify-genuine';
      print('📡 Marking flagged complaint as genuine at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'adminId': adminId.toString(),
          'notes': notes ?? 'Verified as genuine by admin',
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error verifying genuine complaint: $e');
      return false;
    }
  }

  // =====================================================
  // 13. MARK FLAGGED COMPLAINT AS FAKE
  // =====================================================

  Future<Map<String, dynamic>> markAsFakeComplaint(String complaintId, {String? adminId, String? reason, String? notes}) async {
    try {
      final url = '${ApiConfig.baseUrl}/resolutions/flagged/$complaintId/mark-fake';
      print('📡 Marking complaint as fake at: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'adminId': adminId.toString(),
          'reason': reason ?? 'Confirmed as fake complaint',
          'notes': notes ?? 'Admin confirmed this complaint is fake',
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to mark as fake'};
    } catch (e) {
      print('❌ Error marking complaint as fake: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}