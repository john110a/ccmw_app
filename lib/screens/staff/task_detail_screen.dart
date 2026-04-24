// lib/screens/staff/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/staff_action_service.dart';
import '../../services/locationservice.dart';
import '../../config/routes.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final StaffActionService _staffActionService = StaffActionService();
  final LocationService _locationService = LocationService();

  // Task data
  String? _assignmentId;
  String? _staffId;
  String? _title;
  String? _complaintNumber;
  String? _description;
  String? _priority;
  String? _categoryName;
  String? _zoneName;
  String? _locationAddress;
  double? _locationLatitude;
  double? _locationLongitude;

  bool _isLoading = false;
  String? _errorMessage;

  // Workflow state
  bool _isAccepted = false;
  bool _isStarted = false;
  bool _isCompleted = false;
  String? _currentStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _assignmentId == null) {
      setState(() {
        _assignmentId = args['assignmentId']?.toString();
        _staffId = args['staffId']?.toString();
        _title = args['title']?.toString();
        _complaintNumber = args['complaintNumber']?.toString();
        _description = args['description']?.toString();
        _priority = args['priority']?.toString();
        _categoryName = args['categoryName']?.toString();
        _zoneName = args['zoneName']?.toString();
        _locationAddress = args['locationAddress']?.toString();
        _locationLatitude = args['locationLatitude']?.toDouble();
        _locationLongitude = args['locationLongitude']?.toDouble();
        _currentStatus = args['status']?.toString();

        // Set workflow state based on status
        _isCompleted = _currentStatus == 'Completed';
        _isStarted = _currentStatus == 'InProgress' || _currentStatus == 'Started';
        _isAccepted = _currentStatus == 'Accepted';
      });
    }
  }

  Future<void> _acceptTask() async {
    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current location for GPS verification
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get your location. Please enable GPS.');
      }

      final result = await _staffActionService.acceptAssignmentWithLocation(
        _assignmentId!,
        _staffId!,
        position.latitude,
        position.longitude,
        position.accuracy,
      );

      setState(() {
        _isAccepted = true;
        _currentStatus = 'Accepted';
        _isLoading = false;
      });

      _showSuccess('Task accepted successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _startWork() async {
    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _staffActionService.startWork(_assignmentId!, _staffId!);

      setState(() {
        _isStarted = true;
        _currentStatus = 'InProgress';
        _isLoading = false;
      });

      _showSuccess('Work started successfully');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _goToResolutionUpload() async {
    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      Routes.resolutionUpload,
      arguments: {
        'assignmentId': _assignmentId,
        'staffId': _staffId,
        'complaintTitle': _title ?? 'Complaint',
        'complaintNumber': _complaintNumber,
      },
    );

    if (result == true) {
      setState(() {
        _isCompleted = true;
        _currentStatus = 'Completed';
      });

      _showSuccess('Resolution submitted successfully!');

      // Return to previous screen after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_assignmentId == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Task Details', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final priorityColor = _priority == 'High'
        ? Colors.red
        : _priority == 'Medium'
        ? Colors.orange
        : Colors.green;

    final statusText = _isCompleted ? 'Completed'
        : _isStarted ? 'In Progress'
        : _isAccepted ? 'Accepted'
        : 'Assigned';

    final statusColor = _isCompleted ? Colors.green
        : _isStarted ? Colors.blue
        : _isAccepted ? Colors.orange
        : Colors.grey;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Task Details', style: TextStyle(color: Colors.grey[900])),
        actions: [
          if (!_isCompleted)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _title ?? 'No Title',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _priority ?? 'Medium',
                          style: TextStyle(color: priorityColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _complaintNumber ?? 'No Number',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _categoryName ?? 'General',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _zoneName ?? 'Unknown Zone',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description ?? 'No description provided',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // Location Map
            if (_locationLatitude != null && _locationLongitude != null)
              Container(
                margin: const EdgeInsets.all(16),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_locationLatitude!, _locationLongitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('complaint'),
                        position: LatLng(_locationLatitude!, _locationLongitude!),
                        infoWindow: InfoWindow(title: _title ?? 'Complaint Location'),
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ),

            // Location Address
            if (_locationAddress != null && _locationAddress!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationAddress!,
                        style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),

            // Resolution Section (for completed tasks)
            if (_isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Task Completed',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Resolution has been submitted successfully.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (!_isCompleted)
              Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!_isAccepted && !_isStarted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _acceptTask,
                          icon: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.check_circle),
                          label: Text(_isLoading ? 'Processing...' : 'Accept Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                    if (_isAccepted && !_isStarted && !_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _startWork,
                          icon: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isLoading ? 'Processing...' : 'Start Work'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                    if (_isStarted && !_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _goToResolutionUpload,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Submit Resolution'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}