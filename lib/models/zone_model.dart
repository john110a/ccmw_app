// lib/models/zone_model.dart - COMPLETE with isActive field
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

// =====================================================
// POLYGON PARSER EXTENSION (Same as before)
// =====================================================
extension PolygonParser on dynamic {
  List<LatLng> toLatLngList() {
    if (this == null) return [];

    try {
      if (this is String) {
        final str = this as String;
        if (str.isNotEmpty && str != 'null') {
          try {
            final decoded = jsonDecode(str);
            return decoded.toLatLngList();
          } catch (e) {
            print('⚠️ Error parsing JSON string: $e');
          }
        }
        return [];
      }

      if (this is List) {
        return _parseList(this as List);
      }

      if (this is Map) {
        final map = this as Map;
        if (map['type'] == 'Polygon' && map['coordinates'] != null) {
          final coordinates = map['coordinates'];
          if (coordinates is List && coordinates.isNotEmpty) {
            return _parseList(coordinates.first as List);
          }
        }
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

      return [];
    } catch (e) {
      print('❌ Error parsing polygon: $e');
      return [];
    }
  }

  List<LatLng> _parseList(List list) {
    return list.map((point) {
      if (point is LatLng) return point;
      if (point is Map) {
        final lat = (point['latitude'] ?? point['lat'] ?? 0.0).toDouble();
        final lng = (point['longitude'] ?? point['lng'] ?? point['lon'] ?? 0.0).toDouble();
        return LatLng(lat, lng);
      }
      if (point is List && point.length >= 2) {
        final first = point[0].toDouble();
        final second = point[1].toDouble();
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
// ZONE MODEL WITH SUB-ZONE SUPPORT
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

  // Polygon data
  final dynamic boundaryPolygon;
  final double? centerLatitude;
  final double? centerLongitude;
  final String? colorCode;

  // ===== ADD THIS: Active status =====
  final bool isActive;

  // =====================================================
  // SUB-ZONE PROPERTIES
  // =====================================================
  final String? parentZoneId;
  final int level;  // 1 = Main Zone, 2 = Sub-Zone
  final int displayOrder;
  List<Zone>? subZones;  // For hierarchy (only populated when fetching hierarchy)

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
    required this.isActive,  // ===== ADD THIS =====
    this.parentZoneId,
    this.level = 1,
    this.displayOrder = 0,
    this.subZones,
  });

  // Helper getters for zone type
  bool get isMainZone => level == 1;
  bool get isSubZone => level == 2;
  bool get hasSubZones => subZones != null && subZones!.isNotEmpty;
  String get zoneTypeDisplay => isMainZone ? 'Main Zone' : 'Sub-Zone';
  String get statusDisplay => isActive ? 'Active' : 'Inactive';
  Color get statusColor => isActive ? Colors.green : Colors.red;

  String get displayNameWithLevel {
    if (isSubZone) {
      return '  └ $zoneName';
    }
    return '📌 $zoneName';
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    dynamic boundaryPolygonData = json['BoundaryPolygon'] ??
        json['boundaryPolygon'] ??
        json['boundary_polygon'];

    // Parse sub-zones if present
    List<Zone>? parsedSubZones;
    if (json['SubZones'] != null && json['SubZones'] is List) {
      parsedSubZones = (json['SubZones'] as List)
          .map((sz) => Zone.fromJson(sz))
          .toList();
    }

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
      boundaryPolygon: boundaryPolygonData,
      centerLatitude: _getDoubleValue(json, ['CenterLatitude', 'centerLatitude', 'center_latitude']),
      centerLongitude: _getDoubleValue(json, ['CenterLongitude', 'centerLongitude', 'center_longitude']),
      colorCode: _getStringValue(json, ['ColorCode', 'colorCode', 'color_code']),
      // ===== ADD THIS: Parse isActive =====
      isActive: _getBoolValue(json, ['IsActive', 'isActive', 'is_active']) ?? true,
      // Sub-zone properties
      parentZoneId: _getStringValue(json, ['ParentZoneId', 'parentZoneId', 'parent_zone_id']),
      level: _getIntValue(json, ['Level', 'level']) ?? 1,
      displayOrder: _getIntValue(json, ['DisplayOrder', 'displayOrder']) ?? 0,
      subZones: parsedSubZones,
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
      'is_active': isActive,  // ===== ADD THIS =====
      'parent_zone_id': parentZoneId,
      'level': level,
      'display_order': displayOrder,
    };
  }

  // =====================================================
  // POLYGON METHODS
  // =====================================================

  List<LatLng> _parsePolygonDirectly() {
    if (boundaryPolygon == null) return [];

    try {
      String jsonString;
      if (boundaryPolygon is String) {
        jsonString = boundaryPolygon as String;
        if (jsonString.isEmpty || jsonString == 'null') return [];
      } else {
        jsonString = jsonEncode(boundaryPolygon);
      }

      final decoded = jsonDecode(jsonString);

      if (decoded is Map) {
        if (decoded.containsKey('coordinates')) {
          final coordinates = decoded['coordinates'];
          if (coordinates is List && coordinates.isNotEmpty) {
            final ring = coordinates.first as List;
            return ring.map((point) {
              if (point is List && point.length >= 2) {
                return LatLng(point[1].toDouble(), point[0].toDouble());
              }
              if (point is Map) {
                final lat = (point['lat'] ?? point['latitude'] ?? 0.0).toDouble();
                final lng = (point['lng'] ?? point['longitude'] ?? 0.0).toDouble();
                return LatLng(lat, lng);
              }
              return const LatLng(0, 0);
            }).toList();
          }
        }
        if (decoded.containsKey('polygon')) {
          return decoded['polygon'].toLatLngList();
        }
        if (decoded.containsKey('boundaryPolygon')) {
          return decoded['boundaryPolygon'].toLatLngList();
        }
      }

      if (decoded is List) {
        return decoded.toLatLngList();
      }

      return [];
    } catch (e) {
      print('❌ Direct parse error for zone $zoneName: $e');
      return [];
    }
  }

  List<LatLng> getPolygonPoints() {
    if (_cachedPolygonPoints != null) {
      return _cachedPolygonPoints!;
    }

    List<LatLng> points = _parsePolygonDirectly();

    if (points.isEmpty) {
      try {
        points = boundaryPolygon.toLatLngList();
      } catch (e) {
        print('❌ Extension parse error for zone $zoneName: $e');
      }
    }

    if (points.length < 3) {
      print('⚠️ Zone $zoneName has insufficient points: ${points.length}');
      points = [];
    } else {
      final first = points.first;
      final last = points.last;
      if (first.latitude != last.latitude || first.longitude != last.longitude) {
        points.add(first);
      }
    }

    _cachedPolygonPoints = points;
    return points;
  }

  bool get hasPolygon {
    if (boundaryPolygon == null) return false;
    if (boundaryPolygon is String) {
      final str = boundaryPolygon as String;
      if (str.isEmpty || str == 'null' || str.length < 20) return false;
      if (!str.contains('coordinates') && !str.contains('polygon')) return false;
    }
    try {
      final points = getPolygonPoints();
      return points.isNotEmpty && points.length >= 3;
    } catch (e) {
      return false;
    }
  }

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

  LatLng? get center {
    if (centerLatitude != null && centerLongitude != null) {
      return LatLng(centerLatitude!, centerLongitude!);
    }
    return null;
  }

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
    area = area * 111.0 * 111.0;
    return area;
  }

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
    return 'Zone{id: $zoneId, name: $zoneName, number: $zoneNumber, level: $level, isActive: $isActive, hasPolygon: $hasPolygon, points: ${getPolygonPoints().length}}';
  }

  // =====================================================
  // STATIC HELPER METHODS
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
          } catch (e) {}
        }
      }
    }
    return null;
  }

  // ===== ADD THIS: Helper method for boolean values =====
  static bool? _getBoolValue(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      final value = json[key];
      if (value != null) {
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) {
          final lowerValue = value.toLowerCase();
          if (lowerValue == 'true' || lowerValue == '1') return true;
          if (lowerValue == 'false' || lowerValue == '0') return false;
        }
      }
    }
    return null;
  }
}