// lib/widgets/polygon_drawer_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/polygon_helper.dart';

// Make the state class public by removing underscore
class PolygonDrawerState extends State<PolygonDrawer> {
  List<LatLng> _points = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _points = List.from(widget.initialPoints!);
      _updateDisplay();
    }
  }

  // PUBLIC METHODS for parent to access
  void handleMapTap(LatLng point) {
    if (!_isDrawing) return;
    _handleTap(point);
  }

  // PUBLIC GETTERS for parent to access state
  Set<Polygon> get polygons => _polygons;
  Set<Marker> get markers => _markers;
  bool get isDrawing => _isDrawing;
  List<LatLng> get points => _points;

  void _handleTap(LatLng point) {
    setState(() {
      _points.add(point);
      _markers.add(
        Marker(
          markerId: MarkerId('point_${_points.length}'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Point ${_points.length}',
            snippet: '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          ),
        ),
      );
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    if (_points.length >= 3) {
      setState(() {
        _polygons = {
          Polygon(
            polygonId: const PolygonId('drawing_polygon'),
            points: List.from(_points),
            strokeWidth: 3,
            strokeColor: widget.strokeColor,
            fillColor: widget.fillColor,
            geodesic: true,
          ),
        };
      });
    }
  }

  void _updateDisplay() {
    setState(() {
      _polygons.clear();
      _markers.clear();
      if (_points.isNotEmpty) {
        for (int i = 0; i < _points.length; i++) {
          _markers.add(
            Marker(
              markerId: MarkerId('point_$i'),
              position: _points[i],
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue
              ),
              infoWindow: InfoWindow(
                title: 'Point ${i + 1}',
                snippet: '${_points[i].latitude.toStringAsFixed(4)}, ${_points[i].longitude.toStringAsFixed(4)}',
              ),
            ),
          );
        }
        if (_points.length >= 3) {
          _polygons = {
            Polygon(
              polygonId: const PolygonId('drawing_polygon'),
              points: List.from(_points),
              strokeWidth: 3,
              strokeColor: widget.strokeColor,
              fillColor: widget.fillColor,
              geodesic: true,
            ),
          };
        }
      }
    });
  }

  void _clearPolygon() {
    setState(() {
      _points.clear();
      _polygons.clear();
      _markers.clear();
      _isDrawing = false;
    });
  }

  void _completePolygon() {
    if (_points.length >= 3) {
      if (_points.first != _points.last) {
        setState(() {
          _points.add(_points.first);
          _updatePolygon();
        });
      }
      setState(() {
        _isDrawing = false;
      });
      widget.onPolygonCompleted(_points);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Polygon completed! Area: ${PolygonHelper.calculateArea(_points).toStringAsFixed(2)} sq km'
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
        _markers.removeWhere((m) => m.markerId.value == 'point_${_points.length + 1}');
        _updatePolygon();
      });
    }
  }

  void startDrawing() {
    setState(() {
      _clearPolygon();
      _isDrawing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDrawing ? Colors.blue[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isDrawing ? Icons.draw : Icons.edit_off,
                  color: _isDrawing ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isDrawing
                        ? 'Drawing mode: Tap on map to add points (${_points.length} points)'
                        : 'Click "Start Drawing" to begin',
                    style: TextStyle(
                      color: _isDrawing ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!_isDrawing)
                  ElevatedButton.icon(
                    onPressed: startDrawing,
                    icon: const Icon(Icons.draw),
                    label: const Text('Start Drawing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                if (_isDrawing) ...[
                  ElevatedButton.icon(
                    onPressed: _points.length >= 3 ? _completePolygon : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _points.isNotEmpty ? _removeLastPoint : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _clearPolygon,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Points: ${_points.length}'),
                if (_points.length >= 3)
                  Text(
                    'Area: ${PolygonHelper.calculateArea(_points).toStringAsFixed(2)} km²',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PolygonDrawer extends StatefulWidget {
  final Function(List<LatLng>) onPolygonCompleted;
  final Color strokeColor;
  final Color fillColor;
  final List<LatLng>? initialPoints;

  const PolygonDrawer({
    super.key,
    required this.onPolygonCompleted,
    this.strokeColor = Colors.blue,
    this.fillColor = const Color(0x330000FF),
    this.initialPoints,
  });

  @override
  PolygonDrawerState createState() => PolygonDrawerState(); // Now using public state class
}