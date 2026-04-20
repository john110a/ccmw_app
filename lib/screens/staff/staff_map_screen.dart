import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/staff_action_service.dart';
import '../../services/authservice.dart';

class StaffMapScreen extends StatefulWidget {
  const StaffMapScreen({super.key});

  @override
  State<StaffMapScreen> createState() => _StaffMapScreenState();
}

class _StaffMapScreenState extends State<StaffMapScreen> {
  GoogleMapController? _mapController;
  final StaffActionService _staffActionService = StaffActionService();
  final AuthService _authService = AuthService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  String? _staffId;
  String? _errorMessage;

  // Track selected complaint for navigation
  Map<String, dynamic>? _selectedComplaint;

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
          CameraUpdate.newLatLngZoom(_currentLocation!, 14),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Unable to get current location. Please enable GPS.';
      });
    }
  }

  Future<void> _loadNearbyComplaints() async {
    if (_staffId == null || _currentLocation == null) return;

    try {
      final response = await _staffActionService.getNearbyComplaints(
        _staffId!,                    // 1st: staffId
        _currentLocation!.latitude,   // 2nd: latitude
        _currentLocation!.longitude,  // 3rd: longitude
        3.0,                          // 4th: radius in km
      );

      // Clear existing markers
      Set<Marker> newMarkers = {};

      // Handle different response formats
      List<dynamic> complaintsList = [];

      // Check the type of response
      if (response is List) {
        // Response is already a list
        complaintsList = response as List;
      } else if (response is Map<String, dynamic>) {
        // Response is a map - extract the complaints array
        if (response.containsKey('complaints')) {
          complaintsList = response['complaints'] as List<dynamic>;
        } else if (response.containsKey('data')) {
          complaintsList = response['data'] as List<dynamic>;
        } else if (response.containsKey('Complaints')) {
          complaintsList = response['Complaints'] as List<dynamic>;
        } else if (response.containsKey('Data')) {
          complaintsList = response['Data'] as List<dynamic>;
        } else if (response.containsKey('results')) {
          complaintsList = response['results'] as List<dynamic>;
        } else if (response.containsKey('items')) {
          complaintsList = response['items'] as List<dynamic>;
        } else {
          // If no array found, check if the map itself contains complaint data
          if (response.containsKey('complaintId') || response.containsKey('ComplaintId')) {
            complaintsList = [response];
          }
        }
      }

      // Process each complaint
      for (var complaint in complaintsList) {
        if (complaint is Map<String, dynamic>) {
          // Extract complaint ID with fallbacks
          String complaintId = complaint['complaintId']?.toString() ??
              complaint['ComplaintId']?.toString() ??
              complaint['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();

          // Extract coordinates
          double lat = 0.0;
          double lng = 0.0;

          if (complaint.containsKey('locationLatitude')) {
            lat = (complaint['locationLatitude'] as num).toDouble();
          } else if (complaint.containsKey('LocationLatitude')) {
            lat = (complaint['LocationLatitude'] as num).toDouble();
          } else if (complaint.containsKey('latitude')) {
            lat = (complaint['latitude'] as num).toDouble();
          } else if (complaint.containsKey('Latitude')) {
            lat = (complaint['Latitude'] as num).toDouble();
          }

          if (complaint.containsKey('locationLongitude')) {
            lng = (complaint['locationLongitude'] as num).toDouble();
          } else if (complaint.containsKey('LocationLongitude')) {
            lng = (complaint['LocationLongitude'] as num).toDouble();
          } else if (complaint.containsKey('longitude')) {
            lng = (complaint['longitude'] as num).toDouble();
          } else if (complaint.containsKey('Longitude')) {
            lng = (complaint['Longitude'] as num).toDouble();
          }

          // Extract title
          String title = complaint['title']?.toString() ??
              complaint['Title']?.toString() ??
              complaint['name']?.toString() ??
              'Unknown';

          // Extract priority
          String priority = complaint['priority']?.toString() ??
              complaint['Priority']?.toString() ??
              'Medium';

          // Extract distance
          String distance = complaint['distanceKm']?.toString() ??
              complaint['distance']?.toString() ??
              '?';

          newMarkers.add(
            Marker(
              markerId: MarkerId(complaintId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: title,
                snippet: 'Priority: $priority • ${distance}km away',
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
      }

      // Add staff location marker
      newMarkers.add(
        Marker(
          markerId: const MarkerId('staff_location'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      setState(() {
        _markers = newMarkers;
      });

      if (complaintsList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No nearby complaints found'),
            duration: Duration(seconds: 2),
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
      await _staffActionService.updateLocation(
        _staffId!,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        10.0,
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
          width: 3,
        ),
      };
    });

    // Calculate distance
    double distance = _calculateDistance(
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
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  void _openMapsNavigation() {
    if (_currentLocation == null || _selectedLocation == null) return;
    // Open Google Maps for navigation
    final url = 'https://www.google.com/maps/dir/${_currentLocation!.latitude},${_currentLocation!.longitude}/${_selectedLocation!.latitude},${_selectedLocation!.longitude}';
    // Use url_launcher to open - add url_launcher package
    // launchUrl(Uri.parse(url));

    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation feature coming soon. Add url_launcher package.'),
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
    await _updateStaffLocation();
    setState(() => _isLoading = false);
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
          if (_selectedComplaint != null)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/staff-complaint-view',
                  arguments: _selectedComplaint,
                );
              },
              child: const Text('View Details'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(24.8607, 67.0011),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
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

          // Bottom sheet for selected complaint
          if (_selectedComplaint != null)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
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
                                    color: _getPriorityColor(_selectedComplaint!['priority']?.toString() ?? 'medium').withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _selectedComplaint!['priority']?.toString() ?? 'Medium',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPriorityColor(_selectedComplaint!['priority']?.toString() ?? 'medium'),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedComplaint!['complaintNumber']?.toString() ??
                                      _selectedComplaint!['ComplaintNumber']?.toString() ??
                                      'N/A',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedComplaint!['title']?.toString() ??
                                  _selectedComplaint!['Title']?.toString() ??
                                  'Unknown',
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
                                        'No address',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/staff-complaint-view',
                                        arguments: _selectedComplaint,
                                      );
                                    },
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
        onPressed: _refreshData,
        child: const Icon(Icons.my_location),
        tooltip: 'Center on my location',
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'critical': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}