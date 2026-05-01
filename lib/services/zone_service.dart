// lib/services/zone_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/zone_model.dart';
import 'api_config.dart';

// =====================================================
// HELPER EXTENSION FOR PARSING POLYGON COORDINATES
// =====================================================
extension PolygonParser on dynamic {
  List<LatLng> toLatLngList() {
    if (this == null) return [];

    try {
      // Handle direct List
      if (this is List) {
        return _parseList(this as List);
      }

      // Handle Map (GeoJSON format)
      if (this is Map) {
        final map = this as Map;

        // Check if it's GeoJSON Polygon
        if (map['type'] == 'Polygon' && map['coordinates'] != null) {
          final coordinates = map['coordinates'];
          if (coordinates is List && coordinates.isNotEmpty) {
            return _parseList(coordinates.first as List);
          }
        }

        // Check for nested polygon data
        if (map['polygon'] != null) {
          return map['polygon'].toLatLngList();
        }
        if (map['boundaryPolygon'] != null) {
          return map['boundaryPolygon'].toLatLngList();
        }
        if (map['boundaryCoordinates'] != null) {
          return map['boundaryCoordinates'].toLatLngList();
        }
      }

      // Handle String (JSON string)
      if (this is String) {
        final str = this as String;
        if (str.isNotEmpty) {
          try {
            final decoded = jsonDecode(str);
            return decoded.toLatLngList();
          } catch (e) {
            print('⚠️ Error parsing JSON string: $e');
          }
        }
      }

      return [];
    } catch (e) {
      print('❌ Error parsing polygon: $e');
      return [];
    }
  }

  List<LatLng> _parseList(List list) {
    return list.map((point) {
      if (point is LatLng) return point;

      // Handle Map format: {latitude: x, longitude: y} or {lat: x, lng: y}
      if (point is Map) {
        final lat = (point['latitude'] ?? point['lat'] ?? 0.0).toDouble();
        final lng = (point['longitude'] ?? point['lng'] ?? point['lon'] ?? 0.0).toDouble();
        return LatLng(lat, lng);
      }

      // Handle List format: [lat, lng] or [lng, lat]
      if (point is List && point.length >= 2) {
        final first = point[0].toDouble();
        final second = point[1].toDouble();

        // Check if it's GeoJSON [lng, lat] format
        if (first >= -180 && first <= 180 && second >= -90 && second <= 90) {
          return LatLng(second, first);
        }
        return LatLng(first, second);
      }

      return const LatLng(0, 0);
    }).toList();
  }
}

// =====================================================
// ZONE SERVICE
// =====================================================
class ZoneService {

  // =====================================================
  // VALIDATION METHODS
  // =====================================================

  /// Validate polygon before saving
  bool validatePolygon(List<LatLng> points) {
    if (points.length < 3) {
      print('⚠️ Polygon must have at least 3 points');
      return false;
    }

    // Check if polygon is closed (first and last point same)
    final first = points.first;
    final last = points.last;
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      print('⚠️ Polygon is not closed - will auto-close');
    }

    return true;
  }

  /// Convert LatLng list to GeoJSON format
  Map<String, dynamic> toGeoJson(List<LatLng> points) {
    return {
      'type': 'Polygon',
      'coordinates': [
        points.map((p) => [p.longitude, p.latitude]).toList(),
      ],
    };
  }

  /// Calculate polygon area in square kilometers (simplified)
  double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) *
          (points[j].latitude - points[i].latitude);
      j = i;
    }

    area = area.abs() / 2.0;
    // Convert to square kilometers (approximate, 1 degree ≈ 111 km)
    area = area * 111.0 * 111.0;

    return area;
  }

  /// Calculate center point of polygon
  LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);

    double lat = 0.0;
    double lng = 0.0;

    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  // =====================================================
  // CRUD OPERATIONS
  // =====================================================

  /// Get all zones - FIXED: Using correct endpoint /zones (not /zones/all)
  Future<List<Zone>> getAllZones() async {
    try {
      final url = '${ApiConfig.baseUrl}/zones';
      print('📡 GET zones from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 GET zones response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        print('📦 Response type: ${data.runtimeType}');

        // Your ZoneController returns a direct list of zones
        List<dynamic> zonesList = [];
        if (data is List) {
          zonesList = data;
          print('✅ Found ${zonesList.length} zones (direct list)');
        } else if (data is Map && data['data'] != null && data['data'] is List) {
          zonesList = data['data'] as List;
          print('✅ Found ${zonesList.length} zones (nested in data)');
        } else if (data is Map && data['zones'] != null && data['zones'] is List) {
          zonesList = data['zones'] as List;
          print('✅ Found ${zonesList.length} zones (nested in zones)');
        } else if (data is Map && data['items'] != null && data['items'] is List) {
          zonesList = data['items'] as List;
          print('✅ Found ${zonesList.length} zones (nested in items)');
        } else {
          print('⚠️ Unexpected response format: ${data.runtimeType}');
          if (data is Map) {
            print('📦 Response keys: ${data.keys}');
          }
          return [];
        }

        if (zonesList.isEmpty) {
          print('ℹ️ No zones found');
          return [];
        }

        // Parse each zone
        final zones = <Zone>[];
        for (var json in zonesList) {
          try {
            final zone = Zone.fromJson(json);
            zones.add(zone);
            print('📍 Parsed zone: ${zone.zoneName} (${zone.zoneId}) - Has polygon: ${zone.hasPolygon}');
          } catch (e) {
            print('❌ Error parsing zone: $e');
            print('📦 Zone data: $json');
          }
        }

        print('✅ Successfully parsed ${zones.length} zones');
        return zones;
      } else if (response.statusCode == 404) {
        print('ℹ️ Zones endpoint not found (404)');
        return [];
      } else {
        print('❌ Failed to load zones: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error loading zones: $e');
      return [];
    }
  }

  /// Get zones with polygons only
  Future<List<Zone>> getZonesWithPolygons() async {
    try {
      final allZones = await getAllZones();
      return allZones.where((zone) => zone.hasPolygon).toList();
    } catch (e) {
      print('❌ Error getting zones with polygons: $e');
      return [];
    }
  }

  /// Get zone by ID
  Future<Zone?> getZoneById(String zoneId) async {
    try {
      final url = '${ApiConfig.baseUrl}/zones/$zoneId';
      print('📡 GET zone from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 GET zone $zoneId response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Zone.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        print('ℹ️ Zone not found');
        return null;
      } else {
        throw Exception('Failed to load zone: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading zone: $e');
      return null;
    }
  }

  /// Create zone with polygon - FIXED: Using correct endpoint /zones (not /zones/create)
  Future<Map<String, dynamic>> createZone({
    required String zoneName,
    required int zoneNumber,
    required List<LatLng> boundaryPoints,
    LatLng? centerPoint,
    double? area,
    required String colorCode,
    String? city,
    String? province,
    int? population,
    List<Map<String, dynamic>>? departmentAssignments,
  }) async {
    try {
      // Validate polygon
      var points = List<LatLng>.from(boundaryPoints);
      if (!validatePolygon(points)) {
        throw Exception('Invalid polygon: Must have at least 3 points');
      }

      // Calculate center if not provided
      final center = centerPoint ?? calculateCenter(points);

      // Calculate area if not provided
      final calculatedArea = area ?? calculatePolygonArea(points);

      // Convert polygon to GeoJSON format
      final geoJson = toGeoJson(points);

      // Convert department assignments to PascalCase to match C# model
      final departmentAssignmentsList = departmentAssignments?.map((dept) {
        return {
          'DepartmentId': dept['departmentId'],
          'DepartmentName': dept['departmentName'],
          'StaffCount': dept['staffCount'] ?? 0,
          'ColorCode': dept['colorCode'] ?? colorCode,
        };
      }).toList();

      // Prepare zone data with PascalCase to match C# model
      final zoneData = {
        'ZoneName': zoneName,
        'ZoneNumber': zoneNumber,
        'ZoneCode': 'Z${zoneNumber.toString().padLeft(3, '0')}',
        'City': city ?? 'Islamabad',
        'Province': province ?? 'ICT',
        'Population': population ?? 0,
        'BoundaryPolygon': geoJson,
        'CenterLatitude': center.latitude,
        'CenterLongitude': center.longitude,
        'ColorCode': colorCode,
        'TotalAreaSqKm': calculatedArea,
        'IsActive': true,
        'DepartmentAssignments': departmentAssignmentsList ?? [],
      };

      print('📡 Creating zone: $zoneName');
      print('📡 Points: ${points.length} boundary points');
      print('📡 Area: ${calculatedArea.toStringAsFixed(2)} km²');
      print('📡 Department assignments: ${departmentAssignmentsList?.length ?? 0}');
      print('📡 URL: ${ApiConfig.baseUrl}/zones');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/zones'), // CORRECT: no /create
        headers: ApiConfig.getHeaders(),
        body: json.encode(zoneData),
      ).timeout(const Duration(seconds: 15));

      print('📡 POST zone response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Zone created successfully');
        return result;
      } else {
        print('❌ Failed to create zone: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to create zone: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating zone: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update zone - FIXED: Using correct endpoint /zones/{id} (not /update)
  Future<Map<String, dynamic>> updateZone(String zoneId, Map<String, dynamic> zoneData) async {
    try {
      final url = '${ApiConfig.baseUrl}/zones/$zoneId';
      print('📡 PUT zone to: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode(zoneData),
      ).timeout(const Duration(seconds: 15));

      print('📡 PUT zone $zoneId response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update zone: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating zone: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Update zone polygon only
  Future<Map<String, dynamic>> updateZonePolygon(
      String zoneId,
      List<LatLng> boundaryPoints
      ) async {
    try {
      // Validate polygon
      var points = List<LatLng>.from(boundaryPoints);
      if (!validatePolygon(points)) {
        throw Exception('Invalid polygon: Must have at least 3 points');
      }

      final geoJson = toGeoJson(points);
      final center = calculateCenter(points);
      final area = calculatePolygonArea(points);

      final url = '${ApiConfig.baseUrl}/zones/$zoneId/polygon';
      print('📡 PUT zone polygon to: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          'BoundaryPolygon': geoJson,
          'CenterLatitude': center.latitude,
          'CenterLongitude': center.longitude,
          'TotalAreaSqKm': area,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 PUT zone polygon response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update zone polygon');
      }
    } catch (e) {
      print('❌ Error updating zone polygon: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Delete zone - FIXED: Using correct endpoint /zones/{id} (not /delete)
  Future<bool> deleteZone(String zoneId) async {
    try {
      final url = '${ApiConfig.baseUrl}/zones/$zoneId';
      print('📡 DELETE zone at: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 DELETE zone $zoneId response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Zone deleted successfully');
        return true;
      } else if (response.statusCode == 404) {
        print('⚠️ Zone not found');
        return false;
      } else {
        print('❌ Failed to delete zone: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting zone: $e');
      return false;
    }
  }

  // =====================================================
  // STATISTICS & UTILITIES
  // =====================================================

  /// Get zone statistics
  Future<Map<String, dynamic>> getZoneStatistics(String zoneId) async {
    try {
      final url = '${ApiConfig.baseUrl}/zones/$zoneId/statistics';
      print('📡 GET zone statistics from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 GET zone statistics response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load zone statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading zone statistics: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get all zones as GeoJSON (for map display)
  Future<Map<String, dynamic>> getAllZonesAsGeoJson() async {
    try {
      final zones = await getAllZones();

      final features = <Map<String, dynamic>>[];

      for (var zone in zones) {
        if (zone.hasPolygon) {
          features.add({
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                zone.getPolygonPoints().map((p) => [p.longitude, p.latitude]).toList(),
              ],
            },
            'properties': {
              'id': zone.zoneId,
              'name': zone.zoneName,
              'number': zone.zoneNumber,
              'color': zone.colorCode,
              'activeComplaints': zone.activeComplaintsCount,
              'totalComplaints': zone.totalComplaintsCount,
            },
          });
        }
      }

      return {
        'type': 'FeatureCollection',
        'features': features,
      };
    } catch (e) {
      print('❌ Error creating GeoJSON: $e');
      return {'type': 'FeatureCollection', 'features': []};
    }
  }
}