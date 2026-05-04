// lib/screens/staff/staff_map_screen.dart

import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/staff_action_service.dart';
import '../../services/map_service.dart';
import '../../services/authservice.dart';
import '../../config/routes.dart';

class StaffMapScreen extends StatefulWidget {
  const StaffMapScreen({super.key});

  @override
  State<StaffMapScreen> createState() => _StaffMapScreenState();
}

class _StaffMapScreenState extends State<StaffMapScreen> {
  GoogleMapController? _mapController;
  final StaffActionService _staffActionService = StaffActionService();
  final MapService _mapService = MapService();
  final AuthService _authService = AuthService();

  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  String? _staffId;
  String? _errorMessage;

  // Track selected complaint for navigation
  Map<String, dynamic>? _selectedComplaint;
  List<Map<String, dynamic>> _nearbyComplaints = [];

  @override
  void initState() {
    super.initState();
    _getStaffIdAndLoadData();
  }

  Future<void> _getStaffIdAndLoadData() async {
    _staffId = await _authService.getStaffId();
    if (_staffId != null) {
      await _getCurrentLocation();
      await _loadNearbyComplaints();
      await _loadZoneBoundaries();
      await _updateStaffLocation();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });

        // Center map on current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 13),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Unable to get current location. Please enable GPS.';
      });
    }
  }

  Future<void> _loadZoneBoundaries() async {
    try {
      final zones = await _mapService.getZonesWithBoundaries();

      final Set<Polygon> zonePolygons = {};

      for (var zone in zones) {
        // Get zone color
        final colorCode = zone['colorCode'] ?? '#2196F3';
        final color = Color(int.parse(colorCode.replaceAll('#', '0xFF')));

        // Parse boundaries
        final boundaries = zone['boundaries'];
        if (boundaries != null && boundaries is String && boundaries.isNotEmpty) {
          try {
            // Parse GeoJSON polygon
            final Map<String, dynamic> geoJson = jsonDecode(boundaries);
            if (geoJson['type'] == 'Polygon' && geoJson['coordinates'] != null) {
              final coordinates = geoJson['coordinates'] as List;
              if (coordinates.isNotEmpty) {
                final points = (coordinates.first as List).map((coord) {
                  return LatLng(coord[1].toDouble(), coord[0].toDouble());
                }).toList();

                if (points.length >= 3) {
                  zonePolygons.add(
                    Polygon(
                      polygonId: PolygonId(zone['zoneId'].toString()),
                      points: points,
                      fillColor: color.withOpacity(0.2),
                      strokeColor: color,
                      strokeWidth: 2,
                      geodesic: true,
                      consumeTapEvents: true,
                      onTap: () {
                        print('Tapped on zone: ${zone['zoneName']}');
                      },
                    ),
                  );
                }
              }
            }
          } catch (e) {
            print('Error parsing zone boundary for ${zone['zoneName']}: $e');
          }
        }
      }

      setState(() {
        _polygons = zonePolygons;
      });

      print('✅ Loaded ${zonePolygons.length} zone polygons');
    } catch (e) {
      print('❌ Error loading zone boundaries: $e');
    }
  }

  Future<void> _loadNearbyComplaints() async {
    if (_currentLocation == null) return;

    try {
      // Use MapService to get nearby complaints from map endpoint
      final complaints = await _mapService.getNearbyComplaints(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        radiusKm: 5.0,
        limit: 50,
      );

      setState(() {
        _nearbyComplaints = complaints;
      });

      final Set<Marker> newMarkers = {};

      print('📍 Found ${complaints.length} nearby complaints from map service');

      for (var complaint in complaints) {
        // Extract complaint ID
        final complaintId = complaint['complaintId']?.toString() ??
            complaint['ComplaintId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        // Extract coordinates
        final lat = (complaint['latitude'] ?? complaint['Latitude'] ?? 0.0).toDouble();
        final lng = (complaint['longitude'] ?? complaint['Longitude'] ?? 0.0).toDouble();

        if (lat == 0.0 && lng == 0.0) continue;

        // Extract details
        final title = complaint['title']?.toString() ??
            complaint['Title']?.toString() ??
            'Unknown Complaint';

        final priority = complaint['priority']?.toString() ??
            complaint['Priority']?.toString() ??
            'Medium';

        final distance = complaint['distanceKm']?.toDouble() ?? 0.0;
        final statusText = complaint['statusText']?.toString() ?? 'Active';

        newMarkers.add(
          Marker(
            markerId: MarkerId(complaintId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: title.length > 30 ? '${title.substring(0, 30)}...' : title,
              snippet: 'Priority: $priority • ${distance.toStringAsFixed(1)}km away • Status: $statusText',
            ),
            icon: _getMarkerIcon(priority),
            onTap: () {
              setState(() {
                _selectedComplaint = Map<String, dynamic>.from(complaint);
                _selectedLocation = LatLng(lat, lng);
                _showRoute();
              });
            },
          ),
        );
      }

      // Add staff location marker
      if (_currentLocation != null) {
        newMarkers.add(
          Marker(
            markerId: const MarkerId('staff_location'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }

      setState(() {
        _markers = newMarkers;
      });

      if (complaints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No nearby complaints found in your area'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${complaints.length} nearby complaints'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error loading nearby complaints: $e');
      setState(() {
        _errorMessage = 'Failed to load nearby complaints: $e';
      });
    }
  }

  Future<void> _updateStaffLocation() async {
    if (_staffId == null || _currentLocation == null) return;

    try {
      // Use StaffActionService to update staff location
      await _staffActionService.updateLocation(
        _staffId!,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        5.0,
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void _showRoute() {
    if (_currentLocation == null || _selectedLocation == null) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_currentLocation!, _selectedLocation!],
          color: Colors.blue,
          width: 4,
          patterns: [
            PatternItem.dash(30),
            PatternItem.gap(10),
          ],
        ),
      };
    });

    // Calculate distance
    final distance = _calculateDistance(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Distance to complaint: ${distance.toStringAsFixed(1)} km'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Navigate',
          onPressed: () => _openMapsNavigation(),
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  void _openMapsNavigation() {
    if (_currentLocation == null || _selectedLocation == null) return;
    final url = 'https://www.google.com/maps/dir/${_currentLocation!.latitude},${_currentLocation!.longitude}/${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation: Open Google Maps (requires url_launcher package)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  BitmapDescriptor _getMarkerIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'critical':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'medium':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'low':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();
    await _loadNearbyComplaints();
    await _loadZoneBoundaries();
    await _updateStaffLocation();
    setState(() => _isLoading = false);
  }

  void _viewTaskDetails() {
    if (_selectedComplaint != null) {
      Navigator.pushNamed(
        context,
        Routes.taskDetail,
        arguments: {
          'assignmentId': _selectedComplaint!['assignmentId'] ??
              _selectedComplaint!['AssignmentId'],
          'staffId': _staffId,
          'title': _selectedComplaint!['title'] ??
              _selectedComplaint!['Title'],
          'complaintNumber': _selectedComplaint!['complaintNumber'] ??
              _selectedComplaint!['ComplaintNumber'],
          'description': _selectedComplaint!['description'] ??
              _selectedComplaint!['Description'],
          'priority': _selectedComplaint!['priority'] ??
              _selectedComplaint!['Priority'],
          'categoryName': _selectedComplaint!['categoryName'] ??
              _selectedComplaint!['CategoryName'],
          'zoneName': _selectedComplaint!['zoneName'] ??
              _selectedComplaint!['ZoneName'],
          'locationAddress': _selectedComplaint!['locationAddress'] ??
              _selectedComplaint!['LocationAddress'],
          'locationLatitude': _selectedComplaint!['latitude'] ??
              _selectedComplaint!['Latitude'],
          'locationLongitude': _selectedComplaint!['longitude'] ??
              _selectedComplaint!['Longitude'],
          'status': _selectedComplaint!['statusText'] ?? 'Active',
        },
      ).then((result) {
        if (result == true) {
          _refreshData();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Task Map', style: TextStyle(color: Colors.grey[900])),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Task Map', style: TextStyle(color: Colors.grey[900])),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Task Map', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(33.6844, 73.0479),
              zoom: 13,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polygons: _polygons,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            onTap: (LatLng position) {
              setState(() {
                _selectedComplaint = null;
                _selectedLocation = null;
                _polylines = {};
              });
            },
          ),

          // Stats overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${_nearbyComplaints.length} nearby',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${_polygons.length} zones',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.my_location, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        _currentLocation != null ? 'GPS active' : 'GPS off',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _currentLocation != null ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet for selected complaint
          if (_selectedComplaint != null)
            DraggableScrollableSheet(
              initialChildSize: 0.28,
              minChildSize: 0.15,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
                final priority = _selectedComplaint!['priority']?.toString() ??
                    _selectedComplaint!['Priority']?.toString() ?? 'Medium';
                final status = _selectedComplaint!['statusText']?.toString() ??
                    _selectedComplaint!['CurrentStatus']?.toString() ?? 'Active';
                final distance = _selectedComplaint!['distanceKm']?.toDouble() ?? 0.0;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(priority).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    priority,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPriorityColor(priority),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'Resolved' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status == 'Resolved' ? Colors.green : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${distance.toStringAsFixed(1)} km away',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedComplaint!['title']?.toString() ??
                                  _selectedComplaint!['Title']?.toString() ??
                                  'Unknown Complaint',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _selectedComplaint!['locationAddress']?.toString() ??
                                        _selectedComplaint!['LocationAddress']?.toString() ??
                                        'No address provided',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openMapsNavigation,
                                    icon: const Icon(Icons.navigation),
                                    label: const Text('Navigate'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.blue),
                                      foregroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _viewTaskDetails,
                                    icon: const Icon(Icons.assignment),
                                    label: const Text('View Task'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _getCurrentLocation();
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 13),
          );
        },
        child: const Icon(Icons.my_location),
        tooltip: 'Center on my location',
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}