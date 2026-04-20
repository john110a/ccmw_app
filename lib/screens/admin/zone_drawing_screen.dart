// lib/screens/admin/zone_drawing_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/polygon_drawer_widget.dart';
import '../../utils/polygon_helper.dart';
import '../../services/zone_service.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';

class ZoneDrawingScreen extends StatefulWidget {
  const ZoneDrawingScreen({super.key});

  @override
  State<ZoneDrawingScreen> createState() => _ZoneDrawingScreenState();
}

class _ZoneDrawingScreenState extends State<ZoneDrawingScreen> {
  final TextEditingController _zoneNameController = TextEditingController();
  final TextEditingController _zoneNumberController = TextEditingController();
  final ZoneService _zoneService = ZoneService();
  final DepartmentService _departmentService = DepartmentService();

  GoogleMapController? _mapController;

  bool _polygonDrawn = false;
  bool _isLoadingDepartments = false;
  bool _departmentsLoaded = false;
  bool _isSaving = false;
  String? _departmentError;
  List<LatLng> _drawnPoints = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _departmentAssignments = [];
  List<Department> _departments = [];

  final GlobalKey<PolygonDrawerState> _polygonDrawerKey = GlobalKey<PolygonDrawerState>();

  final Map<String, Color> _departmentColors = {
    'WASA': Colors.blue,
    'RWMC': Colors.green,
    'LESCO': Colors.orange,
    'CDA': Colors.purple,
    'ICT': Colors.red,
  };

  PolygonDrawerState? get _drawerState => _polygonDrawerKey.currentState;
  bool get _isDrawing => _drawerState?.isDrawing ?? false;
  List<LatLng> get _currentPoints => _drawerState?.points ?? [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDepartments = true;
      _departmentError = null;
    });

    try {
      print('📡 Loading departments from database...');
      final departments = await _departmentService.getAllDepartments();
      print('✅ Loaded ${departments.length} departments');

      if (mounted) {
        setState(() {
          _departments = departments;
          _isLoadingDepartments = false;
          _departmentsLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Error loading departments: $e');
      if (mounted) {
        setState(() {
          _isLoadingDepartments = false;
          _departmentsLoaded = true;
          _departmentError = 'Failed to load departments: $e';
        });
      }
    }
  }

  void _centerMapOnPolygon(List<LatLng> points) {
    if (points.isEmpty || _mapController == null) return;
    LatLng center = PolygonHelper.calculateCenter(points);
    _mapController!.animateCamera(CameraUpdate.newLatLng(center));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_polygonDrawn ? 'Zone Information' : 'Draw Zone Boundary'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (_polygonDrawn)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveZone,
            )
          else
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _proceedToForm,
              tooltip: 'Next',
            ),
        ],
      ),
      body: _polygonDrawn ? _buildFormView() : _buildDrawingView(),
    );
  }

  Widget _buildDrawingView() {
    return Column(
      children: [
        PolygonDrawer(
          key: _polygonDrawerKey,
          onPolygonCompleted: (points) {
            print('✅ Polygon completed with ${points.length} points');
            _drawnPoints = points;
            _centerMapOnPolygon(points);
            if (mounted) {
              setState(() {
                _polygons = _drawerState?.polygons ?? {};
                _markers = _drawerState?.markers ?? {};
              });
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Polygon drawn! Area: ${PolygonHelper.calculateArea(points).toStringAsFixed(2)} sq km'
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(33.6844, 73.0479),
                  zoom: 12,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onTap: (point) {
                  if (_isDrawing) {
                    _drawerState?.handleMapTap(point);
                    if (mounted) {
                      setState(() {
                        _polygons = _drawerState?.polygons ?? {};
                        _markers = _drawerState?.markers ?? {};
                      });
                    }
                  }
                },
                polygons: _polygons,
                markers: _markers,
                mapType: MapType.hybrid,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              if (!_isDrawing && _currentPoints.isEmpty)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'How to draw a zone:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('1. Click "Start Drawing" button above'),
                        const Text('2. Tap on map to add points'),
                        const Text('3. Click "Complete" when done'),
                        const SizedBox(height: 8),
                        const Text('Points needed: 3+', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Polygon Drawn Successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Area: ${PolygonHelper.calculateArea(_drawnPoints).toStringAsFixed(2)} sq km | Points: ${_drawnPoints.length}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _polygonDrawn = false;
                    });
                  },
                  child: const Text('Redraw'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zone Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    style: const TextStyle(color: Colors.black),
                    controller: _zoneNameController,
                    decoration: const InputDecoration(
                      labelText: 'Zone Name',
                      hintText: 'e.g., Saddar, Gulshan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    style: const TextStyle(color: Colors.black),
                    controller: _zoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Zone Number',
                      hintText: 'e.g., 1, 2, 3',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Department Assignments',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _departmentsLoaded && !_isSaving ? _showAddDepartmentDialog : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_departmentsLoaded && !_isSaving) ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingDepartments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_departmentError != null)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                          const SizedBox(height: 8),
                          Text(
                            _departmentError!,
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDepartments,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_departmentAssignments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.business, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No departments assigned',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const Text('Click "Add" to assign departments to this zone'),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _departmentAssignments.map((dept) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (dept['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dept['color']),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: dept['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dept['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Area included in zone',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _departmentAssignments.remove(dept);
                                  });
                                },
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveZone,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Save Zone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToForm() {
    if (_currentPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw a valid polygon first (minimum 3 points)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _drawnPoints = List.from(_currentPoints);
      _polygonDrawn = true;
    });
  }

  void _showAddDepartmentDialog() {
    if (!_departmentsLoaded || _departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_departments.isEmpty ? 'No departments available' : 'Loading departments...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedDepartmentId;
    Department? selectedDepartment;
    Color? selectedColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Department'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDepartmentId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Choose a department'),
                    ),
                    ..._departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.departmentId,
                        child: Text(dept.departmentName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedDepartmentId = value;
                      selectedDepartment = value != null
                          ? _departments.firstWhere((d) => d.departmentId == value)
                          : null;
                      if (selectedDepartment != null) {
                        selectedColor = _departmentColors[selectedDepartment!.departmentName?.split(' ').first] ??
                            Colors.blue;
                      }
                    });
                    print('📌 Selected department: ${selectedDepartment?.departmentName} ($selectedDepartmentId)');
                  },
                ),
                const SizedBox(height: 16),
                const Text('Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _departmentColors.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = entry.value),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == entry.value ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDepartmentId != null && selectedColor != null) {
                  print('✅ Adding department: ${selectedDepartment?.departmentName} with color $selectedColor');

                  this.setState(() {
                    _departmentAssignments.add({
                      'id': selectedDepartmentId,
                      'name': selectedDepartment?.departmentName ?? 'Unknown',
                      'color': selectedColor,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedDepartment?.departmentName} assigned to zone'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select both department and color'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveZone() async {
    if (_zoneNameController.text.isEmpty) {
      _showError('Please enter zone name');
      return;
    }

    if (_zoneNumberController.text.isEmpty) {
      _showError('Please enter zone number');
      return;
    }

    int? zoneNumber = int.tryParse(_zoneNumberController.text);
    if (zoneNumber == null) {
      _showError('Please enter a valid zone number');
      return;
    }

    if (_drawnPoints.isEmpty || _drawnPoints.length < 3) {
      _showError('Please draw a valid polygon first');
      return;
    }

    // Create clean copy of points
    final List<LatLng> validPoints = _drawnPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    setState(() => _isSaving = true);

    try {
      print('📡 Saving zone: ${_zoneNameController.text}');
      print('📌 Points: ${validPoints.length}');
      print('📌 Department assignments: ${_departmentAssignments.length}');

      LatLng center = PolygonHelper.calculateCenter(validPoints);
      double area = PolygonHelper.calculateArea(validPoints);

      // Prepare department assignments for API - camelCase for Flutter
      final departmentAssignments = _departmentAssignments.map((dept) {
        return {
          'departmentId': dept['id'],
          'departmentName': dept['name'],
          'staffCount': 0,
          'colorCode': '#${dept['color'].value.toRadixString(16).substring(2)}',
        };
      }).toList();

      print('📡 Department assignments payload: $departmentAssignments');

      final result = await _zoneService.createZone(
        zoneName: _zoneNameController.text.trim(),
        zoneNumber: zoneNumber,
        boundaryPoints: validPoints,
        centerPoint: center,
        area: area,
        colorCode: '#2196F3',
        city: 'Islamabad',
        province: 'ICT',
        population: 0,
        departmentAssignments: departmentAssignments, // ← This is critical!
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zone created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      print('❌ Error saving zone: $e');
      if (mounted) {
        _showError('Error saving zone: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    _zoneNumberController.dispose();
    super.dispose();
  }
}