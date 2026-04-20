import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  GoogleMapController? _mapController;
  final ComplaintService _complaintService = ComplaintService();
  final CategoryService _categoryService = CategoryService();

  // Location variables
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _address = 'Getting location...';
  String? _errorMessage;

  // Map markers
  Set<Marker> _markers = {};
  List<Complaint> _nearbyComplaints = [];
  List<Complaint> _filteredComplaints = [];
  List<Category> _categories = [];

  // Filter variables
  String? _selectedCategoryId;
  double _radiusKm = 5.0;
  final List<double> _radiusOptions = [1, 2, 5, 10];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories.map((json) => Category.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions
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
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // Get address from coordinates
        await _getAddressFromLatLng(position.latitude, position.longitude);

        // Load nearby complaints
        await _loadNearbyComplaints();
      } else {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _currentPosition = const LatLng(24.8607, 67.0011); // Default: Karachi
        _errorMessage = 'Could not get location. Using default.';
        _isLoading = false;
      });
    }
  }

  // Convert coordinates to address
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.locality}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Location found';
      });
    }
  }

  // Load complaints from API
  Future<void> _loadNearbyComplaints() async {
    if (_currentPosition == null) return;

    try {
      final complaints = await _complaintService.getMapComplaints(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        radiusKm: _radiusKm,
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _nearbyComplaints = complaints;
        _filteredComplaints = complaints;
        _createMarkers(complaints);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error loading complaints: $e');
      setState(() {
        _errorMessage = 'Failed to load complaints';
        _isLoading = false;
      });
    }
  }

  // Create markers from complaints
  void _createMarkers(List<Complaint> complaints) {
    Set<Marker> markers = {};

    for (var complaint in complaints) {
      Color markerColor = _getStatusColor(complaint.currentStatus);

      markers.add(
        Marker(
          markerId: MarkerId(complaint.complaintId),
          position: LatLng(
            complaint.locationLatitude,
            complaint.locationLongitude,
          ),
          infoWindow: InfoWindow(
            title: complaint.title,
            snippet: 'Status: ${complaint.getStatusString()}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _colorToHue(markerColor),
          ),
          onTap: () => _showComplaintDetails(complaint),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Convert Color to hue for marker
  double _colorToHue(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }

  // Get status color
  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.purple;
      case 4: return Colors.amber;
      case 5: return Colors.green;
      case 7: return Colors.red;
      default: return Colors.grey;
    }
  }

  // Show complaint details bottom sheet
  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint.currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    complaint.getStatusString(),
                    style: TextStyle(
                      color: _getStatusColor(complaint.currentStatus),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    complaint.locationAddress,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/complaint-detail',
                        arguments: complaint.complaintId,
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      MapsLauncher.launchCoordinates(
                        complaint.locationLatitude,
                        complaint.locationLongitude,
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategoryId == null) {
        _filteredComplaints = _nearbyComplaints;
      } else {
        _filteredComplaints = _nearbyComplaints.where((c) =>
        c.categoryId == _selectedCategoryId).toList();
      }
    });
    _createMarkers(_filteredComplaints);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Map'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyComplaints,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map View
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              trafficEnabled: false,
            )
          else if (_errorMessage == null)
            const Center(child: CircularProgressIndicator()),

          // Error message if no location
          if (_errorMessage != null && _currentPosition == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Top Filter Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        hint: const Text('All Categories'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem(
                              value: category.categoryId,
                              child: Text(category.categoryName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: _radiusKm,
                        items: _radiusOptions.map((radius) {
                          return DropdownMenuItem(
                            value: radius,
                            child: Text('$radius km'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _radiusKm = value!;
                          });
                          _loadNearbyComplaints();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Bottom Sheet with complaints list
          if (!_isLoading && _filteredComplaints.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.1,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.all(8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Issues',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // List of complaints
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _filteredComplaints[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                    complaint.currentStatus,
                                  ).withOpacity(0.1),
                                  child: Icon(
                                    Icons.location_on,
                                    color: _getStatusColor(
                                      complaint.currentStatus,
                                    ),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  complaint.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      complaint.locationAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              complaint.currentStatus,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            complaint.getStatusString(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getStatusColor(
                                                complaint.currentStatus,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.thumb_up,
                                          size: 12,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${complaint.upvoteCount}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _showComplaintDetails(complaint),
                              ),
                            );
                          },
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
          if (_currentPosition != null && _mapController != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: _currentPosition!,
                  zoom: 16,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}