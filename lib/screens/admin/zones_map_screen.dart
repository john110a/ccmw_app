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
  List<Zone> _mainZones = [];  // Main zones (Level 1)
  List<Zone> _subZones = [];   // Sub-zones (Level 2)
  bool _isLoading = true;
  String? _errorMessage;

  // Map data
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // UI State
  Zone? _selectedZone;
  bool _showLegend = true;
  bool _showSubZones = true;  // Toggle sub-zones visibility
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
      print('📡 Loading zones hierarchy...');
      final zones = await _zoneService.getZoneHierarchy();
      print('✅ Loaded ${zones.length} main zones');

      // Separate main zones and collect sub-zones
      List<Zone> allSubZones = [];
      for (var mainZone in zones) {
        if (mainZone.subZones != null) {
          allSubZones.addAll(mainZone.subZones!);
        }
      }

      print('📊 Total sub-zones: ${allSubZones.length}');

      // Debug print for each zone's polygon status
      for (var zone in zones) {
        print('🔍 Main Zone: ${zone.zoneName} - hasPolygon: ${zone.hasPolygon}');
      }
      for (var zone in allSubZones) {
        print('🔍 Sub-Zone: ${zone.zoneName} - hasPolygon: ${zone.hasPolygon}');
      }

      setState(() {
        _mainZones = zones;
        _subZones = allSubZones;
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

    // Add MAIN ZONES first (blue theme)
    for (int i = 0; i < _mainZones.length; i++) {
      final zone = _mainZones[i];
      final color = _zoneColors[i % _zoneColors.length];

      // Use zone's color if available, otherwise use blue theme
      final fillColor = zone.colorCode != null
          ? _getColorFromHex(zone.colorCode!).withOpacity(0.25)
          : Colors.blue.withOpacity(0.25);
      final strokeColor = zone.colorCode != null
          ? _getColorFromHex(zone.colorCode!)
          : Colors.blue;

      final hasValidPolygon = zone.hasPolygon;

      if (hasValidPolygon) {
        try {
          final polygonPoints = zone.getPolygonPoints();
          if (polygonPoints.isNotEmpty && polygonPoints.length >= 3) {
            _polygons.add(
              Polygon(
                polygonId: PolygonId('main_${zone.zoneId}'),
                points: polygonPoints,
                fillColor: fillColor,
                strokeColor: strokeColor,
                strokeWidth: 3,
                geodesic: true,
                consumeTapEvents: true,
                onTap: () => _onZoneTap(zone),
              ),
            );
            zonesWithPolygons++;
            print('✅ Added MAIN zone polygon for ${zone.zoneName} with ${polygonPoints.length} points');
          }
        } catch (e) {
          print('❌ Error adding polygon for main zone ${zone.zoneName}: $e');
        }
      } else {
        zonesWithoutPolygons++;
        print('ℹ️ Main zone ${zone.zoneName} has no polygon data');
      }

      // Add marker at zone center
      final center = zone.center ?? _calculateApproximateCenter(zone);
      _markers.add(
        Marker(
          markerId: MarkerId('main_marker_${zone.zoneId}'),
          position: center,
          infoWindow: InfoWindow(
            title: '🏙️ ${zone.zoneName}',
            snippet: 'Main Zone ${zone.zoneNumber}\n${zone.hasPolygon ? 'Has Polygon' : 'No Polygon'}\nSub-Zones: ${zone.subZones?.length ?? 0}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () => _onZoneTap(zone),
        ),
      );
    }

    // Add SUB-ZONES (green theme)
    if (_showSubZones) {
      for (int i = 0; i < _subZones.length; i++) {
        final zone = _subZones[i];

        // Sub-zones use green theme
        final fillColor = zone.colorCode != null
            ? _getColorFromHex(zone.colorCode!).withOpacity(0.4)
            : Colors.green.withOpacity(0.4);
        final strokeColor = zone.colorCode != null
            ? _getColorFromHex(zone.colorCode!)
            : Colors.green;

        final hasValidPolygon = zone.hasPolygon;

        if (hasValidPolygon) {
          try {
            final polygonPoints = zone.getPolygonPoints();
            if (polygonPoints.isNotEmpty && polygonPoints.length >= 3) {
              _polygons.add(
                Polygon(
                  polygonId: PolygonId('sub_${zone.zoneId}'),
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
              print('✅ Added SUB-ZONE polygon for ${zone.zoneName} with ${polygonPoints.length} points');
            }
          } catch (e) {
            print('❌ Error adding polygon for sub-zone ${zone.zoneName}: $e');
          }
        } else {
          zonesWithoutPolygons++;
          print('ℹ️ Sub-zone ${zone.zoneName} has no polygon data');
        }

        // Add marker at zone center (green marker for sub-zones)
        final center = zone.center ?? _calculateApproximateCenter(zone);
        _markers.add(
          Marker(
            markerId: MarkerId('sub_marker_${zone.zoneId}'),
            position: center,
            infoWindow: InfoWindow(
              title: '📍 ${zone.zoneName}',
              snippet: 'Sub-Zone ${zone.zoneNumber}\n${zone.hasPolygon ? 'Has Polygon' : 'No Polygon'}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            onTap: () => _onZoneTap(zone),
          ),
        );
      }
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
    if (_mainZones.isEmpty && _subZones.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    // Include main zones
    for (var zone in _mainZones) {
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

    // Include sub-zones if visible
    if (_showSubZones) {
      for (var zone in _subZones) {
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
  void _toggleSubZones() => setState(() => _showSubZones = !_showSubZones);

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
          actions: [
            IconButton(
              icon: const Icon(Icons.layers, color: Colors.blue),
              onPressed: _toggleSubZones,
              tooltip: _showSubZones ? 'Hide Sub-Zones' : 'Show Sub-Zones',
            ),
          ],
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

    final totalMainZones = _mainZones.length;
    final totalSubZones = _subZones.length;

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
            icon: Icon(_showSubZones ? Icons.visibility_off : Icons.visibility),
            color: Colors.green,
            onPressed: _toggleSubZones,
            tooltip: _showSubZones ? 'Hide Sub-Zones' : 'Show Sub-Zones',
          ),
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

          // Stats Badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$totalMainZones Main', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$totalSubZones Sub', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Legend
          if (_showLegend)
            Positioned(
              top: 70,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.horizontal(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Main Zones', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.horizontal(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Sub-Zones', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const Divider(),
                    ..._mainZones.take(5).map((zone) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5),
                              border: Border.all(color: Colors.blue, width: 1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              zone.zoneName,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (_subZones.isNotEmpty) ...[
                      const Divider(),
                      ..._subZones.take(3).map((zone) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.5),
                                border: Border.all(color: Colors.green, width: 1),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '  └ ${zone.zoneName}',
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (_subZones.length > 3)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('... and more', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                    ],
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
                          Icon(
                            _selectedZone!.isMainZone ? Icons.location_city : Icons.location_on,
                            color: _selectedZone!.isMainZone ? Colors.blue : Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedZone!.zoneName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedZone!.zoneTypeDisplay} ${_selectedZone!.zoneNumber}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedZone!.hasPolygon ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedZone!.hasPolygon ? 'Has Polygon' : 'No Polygon',
                              style: TextStyle(
                                fontSize: 10,
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
                          if (_selectedZone!.isSubZone && _selectedZone!.parentZoneId != null)
                            const SizedBox(width: 8),
                          if (_selectedZone!.isSubZone && _selectedZone!.parentZoneId != null)
                            _buildInfoChip(icon: Icons.folder, label: 'Sub-Zone'),
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