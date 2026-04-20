// lib/utils/polygon_helper.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class PolygonHelper {

  // Calculate area of polygon (in square km)
  static double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = area.abs() / 2;

    // Convert to square km (rough approximation)
    // 1 degree lat ≈ 111 km, 1 degree lng ≈ 111 km * cos(lat)
    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double kmPerDegree = 111.0 * cos(avgLat * pi / 180);
    return area * kmPerDegree * kmPerDegree;
  }

  // Calculate center point of polygon
  static LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(33.6844, 73.0479);

    double lat = 0, lng = 0;
    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  // FIXED: Check if polygon is valid (minimum 3 points)
  // Removed the "closed polygon" requirement since most drawing tools don't auto-close
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;

    // Check for zero coordinates
    for (var point in points) {
      if (point.latitude == 0 && point.longitude == 0) {
        return false;
      }
    }

    return true;
  }

  // FIXED: Check if polygon is closed (first and last point same)
  static bool isPolygonClosed(List<LatLng> points) {
    if (points.length < 3) return false;

    LatLng first = points.first;
    LatLng last = points.last;
    return (first.latitude - last.latitude).abs() < 0.0001 &&
        (first.longitude - last.longitude).abs() < 0.0001;
  }

  // FIXED: Auto-close polygon by adding first point at the end if needed
  static List<LatLng> closePolygon(List<LatLng> points) {
    if (points.length < 3) return points;

    LatLng first = points.first;
    LatLng last = points.last;

    // Check if already closed (within tolerance)
    bool isClosed = (first.latitude - last.latitude).abs() < 0.0001 &&
        (first.longitude - last.longitude).abs() < 0.0001;

    if (!isClosed) {
      return List.from(points)..add(first);
    }

    return List.from(points);
  }

  // Convert points to GeoJSON
  static Map<String, dynamic> toGeoJson(List<LatLng> points) {
    // Ensure polygon is closed for GeoJSON
    final closedPoints = closePolygon(points);

    return {
      'type': 'Polygon',
      'coordinates': [
        closedPoints.map((p) => [p.longitude, p.latitude]).toList(),
      ],
    };
  }

  // Convert GeoJSON to LatLng list
  static List<LatLng> fromGeoJson(Map<String, dynamic> geoJson) {
    try {
      if (geoJson['type'] == 'Polygon') {
        final coordinates = geoJson['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final ring = coordinates[0] as List;
          return ring.map((coord) {
            final lng = (coord[0] as num).toDouble();
            final lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      }
    } catch (e) {
      print('Error parsing GeoJSON: $e');
    }
    return [];
  }

  // Check if a point is inside polygon (ray casting algorithm)
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    // Use closed polygon for point-in-polygon test
    final testPolygon = closePolygon(polygon);

    int i, j = testPolygon.length - 1;
    bool oddNodes = false;

    for (i = 0; i < testPolygon.length; i++) {
      if ((testPolygon[i].longitude < point.longitude &&
          testPolygon[j].longitude >= point.longitude ||
          testPolygon[j].longitude < point.longitude &&
              testPolygon[i].longitude >= point.longitude) &&
          (testPolygon[i].latitude <= point.latitude ||
              testPolygon[j].latitude <= point.latitude)) {
        oddNodes ^= (testPolygon[i].latitude +
            (point.longitude - testPolygon[i].longitude) /
                (testPolygon[j].longitude - testPolygon[i].longitude) *
                (testPolygon[j].latitude - testPolygon[i].latitude) < point.latitude);
      }
      j = i;
    }
    return oddNodes;
  }

  // NEW: Simplify polygon by removing redundant points (Douglas-Peucker algorithm)
  static List<LatLng> simplifyPolygon(List<LatLng> points, double tolerance) {
    if (points.length < 3) return points;

    double maxDistance = 0;
    int index = 0;
    int end = points.length - 1;

    for (int i = 1; i < end; i++) {
      double distance = perpendicularDistance(points[i], points[0], points[end]);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > tolerance) {
      List<LatLng> left = simplifyPolygon(points.sublist(0, index + 1), tolerance);
      List<LatLng> right = simplifyPolygon(points.sublist(index, end + 1), tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points[0], points[end]];
    }
  }

  static double perpendicularDistance(LatLng point, LatLng lineStart, LatLng lineEnd) {
    double area = (lineEnd.latitude - lineStart.latitude) * (point.longitude - lineStart.longitude) -
        (lineEnd.longitude - lineStart.longitude) * (point.latitude - lineStart.latitude);
    double bottom = sqrt(pow(lineEnd.latitude - lineStart.latitude, 2) +
        pow(lineEnd.longitude - lineStart.longitude, 2));
    return area.abs() / bottom;
  }

  // NEW: Get polygon bounds (min/max lat/lng)
  static Map<String, double> getBounds(List<LatLng> points) {
    if (points.isEmpty) return {'minLat': 0, 'maxLat': 0, 'minLng': 0, 'maxLng': 0};

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  // NEW: Get polygon perimeter in km
  static double calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0;

    double perimeter = 0;
    final closedPoints = closePolygon(points);

    for (int i = 0; i < closedPoints.length - 1; i++) {
      perimeter += distanceBetweenPoints(closedPoints[i], closedPoints[i + 1]);
    }

    return perimeter;
  }

  static double distanceBetweenPoints(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // km

    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLng / 2) * sin(deltaLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}