import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

// =====================================================
// POLYGON PARSER EXTENSION
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
// ZONE MODEL
// =====================================================
class Zone {
  final String zoneId;
  final int zoneNumber;
  final String zoneName;
  final String? zoneCode;
  final String? boundaryCoordinates;
  final String? city;
  final String? province;
  final double? totalAreaSqKm;
  final int? population;
  final int? activeComplaintsCount;
  final int? totalComplaintsCount;
  final String? performanceRating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Polygon data - can be String, Map, or List
  final dynamic boundaryPolygon;
  final double? centerLatitude;
  final double? centerLongitude;
  final String? colorCode;

  // Cached polygon points
  List<LatLng>? _cachedPolygonPoints;

  Zone({
    required this.zoneId,
    required this.zoneNumber,
    required this.zoneName,
    this.zoneCode,
    this.boundaryCoordinates,
    this.city,
    this.province,
    this.totalAreaSqKm,
    this.population,
    this.activeComplaintsCount,
    this.totalComplaintsCount,
    this.performanceRating,
    required this.createdAt,
    this.updatedAt,
    this.boundaryPolygon,
    this.centerLatitude,
    this.centerLongitude,
    this.colorCode,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      zoneId: _getStringValue(json, ['ZoneId', 'zoneId', 'zone_id']) ?? '',
      zoneNumber: _getIntValue(json, ['ZoneNumber', 'zoneNumber', 'zone_number']) ?? 0,
      zoneName: _getStringValue(json, ['ZoneName', 'zoneName', 'zone_name']) ?? '',
      zoneCode: _getStringValue(json, ['ZoneCode', 'zoneCode', 'zone_code']),
      boundaryCoordinates: _getStringValue(json, ['BoundaryCoordinates', 'boundaryCoordinates', 'boundary_coordinates']),
      city: _getStringValue(json, ['City', 'city']),
      province: _getStringValue(json, ['Province', 'province']),
      totalAreaSqKm: _getDoubleValue(json, ['TotalAreaSqKm', 'totalAreaSqKm', 'total_area_sq_km', 'area']),
      population: _getIntValue(json, ['Population', 'population']),
      activeComplaintsCount: _getIntValue(json, ['ActiveComplaintsCount', 'activeComplaintsCount', 'active_complaints_count']) ?? 0,
      totalComplaintsCount: _getIntValue(json, ['TotalComplaintsCount', 'totalComplaintsCount', 'total_complaints_count']) ?? 0,
      performanceRating: _getStringValue(json, ['PerformanceRating', 'performanceRating', 'performance_rating']),
      createdAt: _getDateTimeValue(json, ['CreatedAt', 'createdAt', 'created_at']) ?? DateTime.now(),
      updatedAt: _getDateTimeValue(json, ['UpdatedAt', 'updatedAt', 'updated_at']),
      boundaryPolygon: json['BoundaryPolygon'] ?? json['boundaryPolygon'] ?? json['boundary_polygon'],
      centerLatitude: _getDoubleValue(json, ['CenterLatitude', 'centerLatitude', 'center_latitude']),
      centerLongitude: _getDoubleValue(json, ['CenterLongitude', 'centerLongitude', 'center_longitude']),
      colorCode: _getStringValue(json, ['ColorCode', 'colorCode', 'color_code']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zone_id': zoneId,
      'zone_number': zoneNumber,
      'zone_name': zoneName,
      'zone_code': zoneCode,
      'boundary_coordinates': boundaryCoordinates,
      'city': city,
      'province': province,
      'total_area_sq_km': totalAreaSqKm,
      'population': population,
      'active_complaints_count': activeComplaintsCount,
      'total_complaints_count': totalComplaintsCount,
      'performance_rating': performanceRating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'boundary_polygon': boundaryPolygon is Map ? jsonEncode(boundaryPolygon) : boundaryPolygon,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'color_code': colorCode,
    };
  }

  // =====================================================
  // POLYGON METHODS
  // =====================================================

  /// Get polygon points as List<LatLng>
  List<LatLng> getPolygonPoints() {
    // Return cached points if available
    if (_cachedPolygonPoints != null) {
      return _cachedPolygonPoints!;
    }

    // Use the extension to parse polygon
    final points = boundaryPolygon.toLatLngList();

    _cachedPolygonPoints = points;
    return points;
  }

  /// Check if zone has a valid polygon
  bool get hasPolygon {
    // FIXED: Don't call getPolygonPoints here to avoid recursion
    // Just check if boundaryPolygon exists and has content
    if (boundaryPolygon == null) return false;

    // Quick check without full parsing
    try {
      final points = getPolygonPoints();
      return points.isNotEmpty && points.length >= 3;
    } catch (e) {
      return false;
    }
  }

  /// Get polygon area display string
  String get polygonAreaDisplay {
    if (totalAreaSqKm != null && totalAreaSqKm! > 0) {
      return '${totalAreaSqKm!.toStringAsFixed(2)} km²';
    }
    final points = getPolygonPoints();
    if (points.isNotEmpty) {
      return '${points.length} points';
    }
    return 'No polygon drawn';
  }

  /// Get center point as LatLng
  LatLng? get center {
    if (centerLatitude != null && centerLongitude != null) {
      return LatLng(centerLatitude!, centerLongitude!);
    }
    return null;
  }

  /// Calculate area from polygon points (if not provided)
  double calculateArea() {
    if (totalAreaSqKm != null && totalAreaSqKm! > 0) {
      return totalAreaSqKm!;
    }

    final points = getPolygonPoints();
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

  /// Calculate center from polygon points (if not provided)
  LatLng calculateCenter() {
    if (center != null) return center!;

    final points = getPolygonPoints();
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
  // HELPER METHODS
  // =====================================================

  static String? _getStringValue(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      final value = json[key];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null && value is String) {
        return value;
      }
    }
    return null;
  }

  static int? _getIntValue(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      final value = json[key];
      if (value != null) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  static double? _getDoubleValue(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      final value = json[key];
      if (value != null) {
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _getDateTimeValue(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      final value = json[key];
      if (value != null) {
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            // Ignore parsing error
          }
        }
      }
    }
    return null;
  }

  // =====================================================
  // UI HELPER GETTERS
  // =====================================================

  String get displayName => '$zoneName (Zone $zoneNumber)';

  String get locationDisplay {
    if (city != null && province != null) {
      return '$city, $province';
    } else if (city != null) {
      return city!;
    } else if (province != null) {
      return province!;
    }
    return 'Location not specified';
  }

  String get complaintStatsDisplay {
    return 'Active: $activeComplaintsCount | Total: $totalComplaintsCount';
  }

  String get areaDisplay {
    if (totalAreaSqKm != null && totalAreaSqKm! > 0) {
      return '${totalAreaSqKm!.toStringAsFixed(1)} km²';
    }
    final area = calculateArea();
    if (area > 0) {
      return '${area.toStringAsFixed(1)} km² (calculated)';
    }
    return 'Area not specified';
  }

  String get populationDisplay {
    if (population != null && population! > 0) {
      return '${population!.toString()} people';
    }
    return 'Population not specified';
  }

  String get pointsDisplay {
    final points = getPolygonPoints();
    return '${points.length} points';
  }

  Color getPerformanceColor() {
    switch (performanceRating?.toLowerCase()) {
      case 'a':
      case 'a+':
      case 'excellent':
        return Colors.green;
      case 'b':
      case 'b+':
      case 'good':
        return Colors.lightGreen;
      case 'c':
      case 'average':
        return Colors.orange;
      case 'd':
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() {
    return 'Zone{id: $zoneId, name: $zoneName, number: $zoneNumber, hasPolygon: $hasPolygon, points: ${getPolygonPoints().length}}';
  }
}