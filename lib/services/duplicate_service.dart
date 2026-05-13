// lib/services/duplicate_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/duplicate_cluster_model.dart';
import '../models/complaint_model.dart';
import 'api_config.dart';
import 'package:flutter/material.dart';

class DuplicateService {

  // =====================================================
  // 1. DETECT POTENTIAL DUPLICATES
  // =====================================================

  /// Detect potential duplicate complaints based on location and time
  Future<Map<String, dynamic>> detectPotentialDuplicates({
    String? categoryId,
    double? lat,
    double? lng,
    double radiusMeters = 100,
    int hoursThreshold = 24,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lng != null) queryParams['lng'] = lng.toString();
      if (radiusMeters != null) queryParams['radiusMeters'] = radiusMeters.toString();
      if (hoursThreshold != null) queryParams['hoursThreshold'] = hoursThreshold.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}/duplicates/detect')
          .replace(queryParameters: queryParams);

      print('📡 Detecting duplicates from: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response: $data');

        if (data is Map) {
          final Map<String, dynamic> castedData = {};
          data.forEach((key, value) {
            castedData[key.toString()] = value;
          });
          return castedData;
        } else if (data is List) {
          return {'PotentialDuplicates': data};
        } else {
          return {'PotentialDuplicates': []};
        }
      } else {
        print('❌ Failed to detect duplicates: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return {'PotentialDuplicates': []};
      }
    } catch (e) {
      print('❌ Error detecting duplicates: $e');
      return {'PotentialDuplicates': []};
    }
  }

  // =====================================================
  // 2. COMPARE TWO COMPLAINTS
  // =====================================================

  /// Compare two specific complaints to determine if they are duplicates
  Future<Map<String, dynamic>> compareComplaints({
    required String complaintId1,
    required String complaintId2,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/duplicates/compare?complaintId1=$complaintId1&complaintId2=$complaintId2');

      print('📡 Comparing complaints: $complaintId1 vs $complaintId2');
      print('📡 URL: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Comparison result: $data');

        if (data is Map) {
          final Map<String, dynamic> castedData = {};
          data.forEach((key, value) {
            castedData[key.toString()] = value;
          });
          return castedData;
        } else {
          return {};
        }
      } else {
        print('❌ Failed to compare complaints: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to compare complaints');
      }
    } catch (e) {
      print('❌ Error comparing complaints: $e');
      rethrow;
    }
  }

  // =====================================================
  // 3. MERGE DUPLICATES (MANUAL)
  // =====================================================

  /// Merge multiple complaints into one primary complaint
  Future<Map<String, dynamic>> mergeDuplicates({
    required String primaryComplaintId,
    required List<String> duplicateComplaintIds,
    required String mergedByUserId,
    int radiusMeters = 100,
    Map<String, double>? similarityScores,
  }) async {
    try {
      final requestBody = {
        'primaryComplaintId': primaryComplaintId,
        'duplicateComplaintIds': duplicateComplaintIds,
        'mergedByUserId': mergedByUserId,
        'radiusMeters': radiusMeters,
        if (similarityScores != null) 'similarityScores': similarityScores,
      };

      print('📡 Merging duplicates with data: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/duplicates/merge'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Merge result: $data');

        if (data is Map) {
          final Map<String, dynamic> castedData = {};
          data.forEach((key, value) {
            castedData[key.toString()] = value;
          });
          return castedData;
        } else {
          return {};
        }
      } else {
        print('❌ Failed to merge duplicates: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to merge duplicates');
      }
    } catch (e) {
      print('❌ Error merging duplicates: $e');
      rethrow;
    }
  }

  // =====================================================
  // 4. GET MERGED CLUSTERS
  // =====================================================

  /// Get all duplicate clusters (already merged complaints)
  Future<List<DuplicateCluster>> getDuplicateClusters({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/duplicates/clusters?page=$page&pageSize=$pageSize');

      print('📡 Fetching duplicate clusters from: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Raw cluster data: $data');

        List<dynamic> clustersList = [];

        if (data is List) {
          clustersList = data;
        } else if (data is Map && data['clusters'] != null) {
          if (data['clusters'] is List) {
            clustersList = data['clusters'];
          }
        } else if (data is Map && data['data'] != null) {
          if (data['data'] is List) {
            clustersList = data['data'];
          }
        } else if (data is Map && data['results'] != null) {
          if (data['results'] is List) {
            clustersList = data['results'];
          }
        }

        print('✅ Found ${clustersList.length} clusters');

        for (var i = 0; i < clustersList.length; i++) {
          print('📊 Cluster $i: ${clustersList[i]}');
        }

        return clustersList.map((json) => DuplicateCluster.fromJson(json)).toList();
      } else {
        print('❌ Failed to load clusters: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading duplicate clusters: $e');
      return [];
    }
  }

  // =====================================================
  // 5. TRIGGER DUPLICATE DETECTION
  // =====================================================

  /// Manually trigger duplicate detection for all complaints
  Future<bool> triggerDuplicateDetection() async {
    try {
      print('📡 Triggering duplicate detection...');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/duplicates/process-all-existing'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(minutes: 2));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Duplicate detection triggered successfully');
        return true;
      } else {
        print('❌ Failed to trigger duplicate detection: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error triggering duplicate detection: $e');
      return false;
    }
  }

  // =====================================================
  // 6. GET PENDING CLUSTER COUNT
  // =====================================================

  /// Get the count of pending duplicate clusters ready for review
  Future<int> getPendingClusterCount() async {
    try {
      final stats = await getDuplicateStats();

      int count = stats['PendingReview'] ??
          stats['TotalClusters'] ??
          stats['clusters'] ??
          0;

      print('📊 Pending cluster count: $count');
      return count;
    } catch (e) {
      print('❌ Error getting pending cluster count: $e');

      try {
        final clusters = await getDuplicateClusters(page: 1, pageSize: 100);
        print('📊 Fallback cluster count: ${clusters.length}');
        return clusters.length;
      } catch (e) {
        print('❌ Fallback also failed: $e');
        return 0;
      }
    }
  }

  // =====================================================
  // 7. GET DUPLICATE STATISTICS
  // =====================================================

  /// Get duplicate statistics from backend
  Future<Map<String, dynamic>> getDuplicateStats() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/duplicates/stats');

      print('📡 Fetching duplicate stats from: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Stats data: $data');

        if (data is Map) {
          final Map<String, dynamic> castedData = {};
          data.forEach((key, value) {
            castedData[key.toString()] = value;
          });
          return castedData;
        } else {
          return {};
        }
      }

      print('⚠️ Stats endpoint returned ${response.statusCode}');

      // Fallback: calculate from clusters
      final clusters = await getDuplicateClusters(page: 1, pageSize: 100);
      int totalDuplicates = 0;
      for (var cluster in clusters) {
        totalDuplicates += cluster.duplicateEntries.length - 1;
      }

      return {
        'TotalComplaints': 0,
        'TotalClusters': clusters.length,
        'TotalDuplicates': totalDuplicates,
        'PendingReview': clusters.length,
        'AutoDetectedToday': 0,
      };
    } catch (e) {
      print('❌ Error loading duplicate stats: $e');
      return {
        'TotalComplaints': 0,
        'TotalClusters': 0,
        'TotalDuplicates': 0,
        'PendingReview': 0,
        'AutoDetectedToday': 0,
      };
    }
  }

  // =====================================================
  // 8. FORCE PROCESS COMPLAINTS
  // =====================================================

  /// Force process complaints to find duplicates (for testing)
  Future<bool> forceProcessComplaints() async {
    try {
      print('📡 Force processing complaints...');

      List<String> endpointsToTry = [
        '${ApiConfig.baseUrl}/duplicates/process-all-existing',
        '${ApiConfig.baseUrl}/duplicates/detect-all',
        '${ApiConfig.baseUrl}/admin/duplicates/process',
        '${ApiConfig.baseUrl}/api/duplicates/process-all',
      ];

      for (String endpoint in endpointsToTry) {
        try {
          print('📡 Trying endpoint: $endpoint');

          final response = await http.post(
            Uri.parse(endpoint),
            headers: ApiConfig.getHeaders(),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            print('✅ Successfully processed at $endpoint');
            return true;
          }
        } catch (e) {
          print('⚠️ Endpoint $endpoint failed: $e');
        }
      }

      return false;
    } catch (e) {
      print('❌ Error force processing: $e');
      return false;
    }
  }

  // =====================================================
  // 9. CHECK COMPLAINT STATUS
  // =====================================================

  /// Check if a specific complaint is marked as duplicate
  Future<Map<String, dynamic>> checkComplaintStatus(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/view'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map) {
          final Map<String, dynamic> castedData = {};
          data.forEach((key, value) {
            castedData[key.toString()] = value;
          });

          return {
            'isDuplicate': castedData['isDuplicate'] ?? false,
            'mergedInto': castedData['mergedIntoComplaintId'],
            'data': castedData,
          };
        } else {
          return {'isDuplicate': false};
        }
      }
      return {'isDuplicate': false};
    } catch (e) {
      print('❌ Error checking complaint status: $e');
      return {'isDuplicate': false};
    }
  }

  // =====================================================
  // 10. HELPER METHODS
  // =====================================================

  /// Format distance in meters to readable string
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format similarity score with color
  static Color getSimilarityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.grey;
  }

  // =====================================================
  // 11. CHECK FOR DUPLICATES DURING SUBMISSION
  // =====================================================

  /// Check if a new complaint has duplicates (called before submission)
  Future<Map<String, dynamic>> checkForDuplicatesOnSubmit({
    required double lat,
    required double lng,
    required String categoryId,
    double radiusMeters = 200,
  }) async {
    try {
      final queryParams = {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'categoryId': categoryId,
        'radiusMeters': radiusMeters.toString(),
        'hoursThreshold': '168', // 7 days
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/duplicates/detect')
          .replace(queryParameters: queryParams);

      print('📡 Checking for duplicates near location: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final potentialDuplicates = data['PotentialDuplicates'] ?? [];

        print('📊 Found ${potentialDuplicates.length} potential duplicates');

        return {
          'hasDuplicates': potentialDuplicates.isNotEmpty,
          'duplicateCount': potentialDuplicates.length,
          'duplicates': potentialDuplicates,
          'message': potentialDuplicates.isEmpty
              ? 'No duplicates found'
              : 'Found ${potentialDuplicates.length} similar complaints nearby'
        };
      }

      return {'hasDuplicates': false, 'duplicateCount': 0, 'duplicates': []};
    } catch (e) {
      print('❌ Error checking duplicates on submit: $e');
      return {'hasDuplicates': false, 'duplicateCount': 0, 'duplicates': []};
    }
  }

  /// Get similar complaints by ID
  Future<List<Complaint>> getSimilarComplaints(String complaintId, {double radiusMeters = 200}) async {
    try {
      // First get the complaint details
      final complaintResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId/view'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (complaintResponse.statusCode != 200) {
        return [];
      }

      final complaintData = json.decode(complaintResponse.body);
      final lat = complaintData['locationLatitude']?.toDouble();
      final lng = complaintData['locationLongitude']?.toDouble();
      final categoryId = complaintData['categoryId']?.toString();

      if (lat == null || lng == null || categoryId == null) {
        return [];
      }

      // Find similar complaints
      final detectResult = await detectPotentialDuplicates(
        lat: lat,
        lng: lng,
        categoryId: categoryId,
        radiusMeters: radiusMeters,
        hoursThreshold: 168,
      );

      final duplicates = detectResult['PotentialDuplicates'] ?? [];

      List<Complaint> similarComplaints = [];
      for (var dup in duplicates) {
        if (dup['Complaint'] != null) {
          similarComplaints.add(Complaint.fromJson(dup['Complaint']));
        }
      }

      return similarComplaints;
    } catch (e) {
      print('❌ Error getting similar complaints: $e');
      return [];
    }
  }
}