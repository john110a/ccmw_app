// lib/screens/admin/zones_map_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/zone_service.dart';
import '../../models/zone_model.dart';

class ZonesMapScreen extends StatefulWidget {
  const ZonesMapScreen({super.key});

  @override
  State<ZonesMapScreen> createState() => _ZonesMapScreenState();
}

class _ZonesMapScreenState extends State<ZonesMapScreen> {
  final ZoneService _zoneService = ZoneService();

  GoogleMapController? _mapController;
  List<Zone> _zones = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Map data
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // UI State
  Zone? _selectedZone;
  bool _showLegend = true;
  double _zoomLevel = 12;
  LatLng _initialCameraPosition = const LatLng(33.6844, 73.0479);

  // Color palette for zones
  final List<Color> _zoneColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading zones...');
      final zones = await _zoneService.getAllZones();
      print('✅ Loaded ${zones.length} zones');

      // Debug print for each zone's polygon status
      for (var zone in zones) {
        print('🔍 Zone: ${zone.zoneName} - hasPolygon: ${zone.hasPolygon}');
        if (zone.boundaryPolygon != null) {
          print('   boundaryPolygon type: ${zone.boundaryPolygon.runtimeType}');
          print('   boundaryPolygon preview: ${zone.boundaryPolygon.toString().substring(0, min(100, zone.boundaryPolygon.toString().length))}');
        }
      }

      setState(() {
        _zones = zones;
        _isLoading = false;
      });

      _addZonesToMap();
    } catch (e) {
      print('❌ Error loading zones: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addZonesToMap() {
    _polygons.clear();
    _markers.clear();

    int zonesWithPolygons = 0;
    int zonesWithoutPolygons = 0;

    for (int i = 0; i < _zones.length; i++) {
      final zone = _zones[i];
      final color = _zoneColors[i % _zoneColors.length];

      // Get color from zone if available
      final fillColor = zone.colorCode != null
          ? _getColorFromHex(zone.colorCode!).withOpacity(0.3)
          : color.withOpacity(0.3);
      final strokeColor = zone.colorCode != null
          ? _getColorFromHex(zone.colorCode!)
          : color;

      // CRITICAL FIX: Directly check boundaryPolygon property
      final hasValidPolygon = zone.boundaryPolygon != null &&
          zone.boundaryPolygon.toString().isNotEmpty &&
          zone.boundaryPolygon.toString() != 'null';

      if (hasValidPolygon) {
        try {
          final polygonPoints = zone.getPolygonPoints();
          if (polygonPoints.isNotEmpty && polygonPoints.length >= 3) {
            _polygons.add(
              Polygon(
                polygonId: PolygonId(zone.zoneId),
                points: polygonPoints,
                fillColor: fillColor,
                strokeColor: strokeColor,
                strokeWidth: 2,
                geodesic: true,
                consumeTapEvents: true,
                onTap: () => _onZoneTap(zone),
              ),
            );
            zonesWithPolygons++;
            print('✅ Added polygon for ${zone.zoneName} with ${polygonPoints.length} points');
          } else {
            print('⚠️ Zone ${zone.zoneName} has polygon data but no valid points');
          }
        } catch (e) {
          print('❌ Error adding polygon for zone ${zone.zoneName}: $e');
        }
      } else {
        zonesWithoutPolygons++;
        print('ℹ️ Zone ${zone.zoneName} has no polygon data');
      }

      // Add marker at zone center
      final center = zone.center ?? _calculateApproximateCenter(zone);
      _markers.add(
        Marker(
          markerId: MarkerId(zone.zoneId),
          position: center,
          infoWindow: InfoWindow(
            title: zone.zoneName,
            snippet: 'Zone ${zone.zoneNumber}\n${hasValidPolygon ? 'Has Polygon' : 'No Polygon'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(color),
          ),
          onTap: () => _onZoneTap(zone),
        ),
      );
    }

    print('📊 Map stats: $zonesWithPolygons zones with polygons, $zonesWithoutPolygons without polygons');
    print('📊 Total polygons added: ${_polygons.length}');

    setState(() {});
  }

  // Helper to convert hex color string to Color
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Calculate an approximate center from zone name (fallback)
  LatLng _calculateApproximateCenter(Zone zone) {
    if (zone.centerLatitude != null && zone.centerLongitude != null) {
      return LatLng(zone.centerLatitude!, zone.centerLongitude!);
    }

    // Try to extract coordinates from zone name
    final name = zone.zoneName.toLowerCase();
    if (name.contains('f-6')) return const LatLng(33.7200, 73.0900);
    if (name.contains('f-7')) return const LatLng(33.7100, 73.0800);
    if (name.contains('f-8')) return const LatLng(33.7000, 73.0700);
    if (name.contains('g-6')) return const LatLng(33.6800, 73.0700);
    if (name.contains('g-7')) return const LatLng(33.6700, 73.0600);
    if (name.contains('i-8')) return const LatLng(33.6600, 73.0800);
    if (name.contains('saddar')) return const LatLng(33.6500, 73.0500);
    if (name.contains('satellite')) return const LatLng(33.6400, 73.0600);
    if (name.contains('central')) return const LatLng(33.6900, 73.0500);
    if (name.contains('north')) return const LatLng(33.7100, 73.0600);
    if (name.contains('south')) return const LatLng(33.6500, 73.0600);
    if (name.contains('east')) return const LatLng(33.6900, 73.1000);
    if (name.contains('west')) return const LatLng(33.6900, 73.0100);
    if (name.contains('katarin')) return const LatLng(33.5900, 73.0500);

    return const LatLng(33.6844, 73.0479);
  }

  double _getMarkerHue(Color color) {
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return 270.0;
    if (color == Colors.pink) return 330.0;
    if (color == Colors.teal) return 180.0;
    if (color == Colors.amber) return 60.0;
    return BitmapDescriptor.hueAzure;
  }

  void _onZoneTap(Zone zone) {
    setState(() {
      _selectedZone = zone;
    });

    final center = zone.center ?? _calculateApproximateCenter(zone);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: 14),
      ),
    );
  }

  void _fitAllZones() {
    if (_zones.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var zone in _zones) {
      if (zone.hasPolygon) {
        final points = zone.getPolygonPoints();
        for (var point in points) {
          minLat = minLat == null ? point.latitude : min(minLat!, point.latitude);
          maxLat = maxLat == null ? point.latitude : max(maxLat!, point.latitude);
          minLng = minLng == null ? point.longitude : min(minLng!, point.longitude);
          maxLng = maxLng == null ? point.longitude : max(maxLng!, point.longitude);
        }
      } else {
        final center = zone.center ?? _calculateApproximateCenter(zone);
        minLat = minLat == null ? center.latitude : min(minLat!, center.latitude);
        maxLat = maxLat == null ? center.latitude : max(maxLat!, center.latitude);
        minLng = minLng == null ? center.longitude : min(minLng!, center.longitude);
        maxLng = maxLng == null ? center.longitude : max(maxLng!, center.longitude);
      }
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());
  void _toggleLegend() => setState(() => _showLegend = !_showLegend);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Zones Map', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Zones Map', style: TextStyle(color: Colors.grey[900])),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadZones,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadZones,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Zones Map', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers, color: Colors.blue),
            onPressed: _toggleLegend,
            tooltip: 'Toggle Legend',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.blue),
            onPressed: _fitAllZones,
            tooltip: 'Fit All Zones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadZones,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _fitAllZones();
            },
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: _zoomLevel,
            ),
            polygons: _polygons,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            onTap: (_) => setState(() => _selectedZone = null),
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Legend
          if (_showLegend)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Zones Legend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    ..._zones.take(8).map((zone) {
                      final index = _zones.indexOf(zone);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _zoneColors[index % _zoneColors.length].withOpacity(0.5),
                                border: Border.all(
                                  color: zone.colorCode != null
                                      ? _getColorFromHex(zone.colorCode!)
                                      : _zoneColors[index % _zoneColors.length],
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                zone.zoneName,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_zones.length > 8)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('... and more', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ),

          // Selected Zone Info Card
          if (_selectedZone != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/zone-details', arguments: _selectedZone),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _zoneColors[_zones.indexOf(_selectedZone!) % _zoneColors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedZone!.zoneName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Zone ${_selectedZone!.zoneNumber}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedZone!.hasPolygon ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedZone!.hasPolygon ? 'Has Polygon' : 'No Polygon',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedZone!.hasPolygon ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(icon: Icons.area_chart, label: _selectedZone!.areaDisplay),
                          const SizedBox(width: 8),
                          _buildInfoChip(icon: Icons.location_city, label: _selectedZone!.locationDisplay),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Tap to view details', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[500]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color ?? Colors.grey[600])),
        ],
      ),
    );
  }
}