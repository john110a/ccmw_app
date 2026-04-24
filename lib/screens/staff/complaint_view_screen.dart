// lib/screens/staff/staff_complaint_view_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/staff_action_service.dart';
import '../../services/locationservice.dart';
import '../../config/routes.dart';

class StaffComplaintViewScreen extends StatefulWidget {
  const StaffComplaintViewScreen({super.key});

  @override
  State<StaffComplaintViewScreen> createState() => _StaffComplaintViewScreenState();
}

class _StaffComplaintViewScreenState extends State<StaffComplaintViewScreen> {
  final StaffActionService _staffActionService = StaffActionService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  // Complaint data from arguments
  Map<String, dynamic>? _complaintData;
  String? _staffId;
  String? _assignmentId;

  // Image and notes
  File? _afterPhoto;
  bool _isSubmitting = false;
  bool _photoUploaded = false;
  String? _uploadedPhotoUrl;

  // Resolution data
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _materialsController = TextEditingController();

  // Workflow state
  String _currentStatus = 'Assigned';
  bool _isAccepted = false;
  bool _isStarted = false;
  bool _isCompleted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _complaintData == null) {
      setState(() {
        _complaintData = args;
        _staffId = args['staffId']?.toString();
        _assignmentId = args['assignmentId']?.toString();
        _currentStatus = args['status']?.toString() ?? 'Assigned';
        _isAccepted = args['acceptedAt'] != null || _currentStatus == 'Accepted';
        _isStarted = args['startedAt'] != null || _currentStatus == 'InProgress';
        _isCompleted = args['completedAt'] != null || _currentStatus == 'Completed';
      });
    }
  }

  Future<void> _pickAfterPhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _afterPhoto = File(photo.path);
          _photoUploaded = false;
        });
      }
    } catch (e) {
      _showError('Error picking photo: $e');
    }
  }

  Future<void> _uploadPhoto() async {
    if (_afterPhoto == null) {
      _showError('Please take an after photo first');
      return;
    }

    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _staffActionService.uploadResolutionPhoto(
        _assignmentId!,
        _staffId!,
        _afterPhoto!,
      );

      setState(() {
        _photoUploaded = true;
        _uploadedPhotoUrl = result['photoUrl'];
        _isSubmitting = false;
      });

      _showSuccess('Photo uploaded successfully!');
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Failed to upload photo: $e');
    }
  }

  Future<void> _acceptTask() async {
    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get current location for GPS verification
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get your location. Please enable GPS.');
      }

      await _staffActionService.acceptAssignmentWithLocation(
        _assignmentId!,
        _staffId!,
        position.latitude,
        position.longitude,
        position.accuracy,
      );

      setState(() {
        _isAccepted = true;
        _currentStatus = 'Accepted';
        _isSubmitting = false;
      });

      _showSuccess('Task accepted successfully');
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _startWork() async {
    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _staffActionService.startWork(_assignmentId!, _staffId!);

      setState(() {
        _isStarted = true;
        _currentStatus = 'InProgress';
        _isSubmitting = false;
      });

      _showSuccess('Work started successfully');
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError(e.toString());
    }
  }

  Future<void> _submitResolution() async {
    if (_notesController.text.trim().isEmpty) {
      _showError('Please enter resolution notes');
      return;
    }

    if (_assignmentId == null || _staffId == null) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // First upload photo if available and not yet uploaded
      String? photoUrl;
      if (_afterPhoto != null && !_photoUploaded) {
        final result = await _staffActionService.uploadResolutionPhoto(
          _assignmentId!,
          _staffId!,
          _afterPhoto!,
        );
        photoUrl = result['photoUrl'];
      } else if (_photoUploaded) {
        photoUrl = _uploadedPhotoUrl;
      }

      // Submit resolution
      await _staffActionService.resolveComplaint(
        _assignmentId!,
        _staffId!,
        _notesController.text.trim(),
        afterPhotoUrl: photoUrl,
      );

      setState(() {
        _isCompleted = true;
        _currentStatus = 'Completed';
        _isSubmitting = false;
      });

      _showSuccess('Resolution submitted successfully!');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Error: $e');
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

  void _openMapNavigation() {
    final lat = _complaintData?['locationLatitude'];
    final lng = _complaintData?['locationLongitude'];

    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/dir/$lat,$lng';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigation: Open Google Maps (requires url_launcher package)'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _showError('Location coordinates not available');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_complaintData == null) {
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

    final priority = _complaintData?['priority']?.toString() ?? 'Medium';
    final priorityColor = priority == 'High' ? Colors.red :
    priority == 'Medium' ? Colors.orange : Colors.green;
    final statusColor = _isCompleted ? Colors.green :
    _isStarted ? Colors.blue :
    _isAccepted ? Colors.orange : Colors.grey;

    final statusText = _isCompleted ? 'Completed' :
    _isStarted ? 'In Progress' :
    _isAccepted ? 'Accepted' : 'Assigned';

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
          IconButton(
            icon: const Icon(Icons.map, color: Colors.grey),
            onPressed: _openMapNavigation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: statusColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task Status',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isCompleted && !_isStarted && !_isAccepted)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _acceptTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(_isSubmitting ? 'Processing...' : 'Accept'),
                    ),
                  if (_isAccepted && !_isStarted && !_isCompleted)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _startWork,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(_isSubmitting ? 'Processing...' : 'Start Work'),
                    ),
                ],
              ),
            ),

            // Complaint Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        _complaintData?['complaintNumber']?.toString() ?? 'N/A',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _complaintData?['title']?.toString() ?? 'No Title',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _buildDetailItem(
                        icon: Icons.category,
                        label: 'Category',
                        value: _complaintData?['categoryName']?.toString() ?? 'General',
                      ),
                      _buildDetailItem(
                        icon: Icons.location_city,
                        label: 'Zone',
                        value: _complaintData?['zoneName']?.toString() ?? 'Unknown',
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        label: 'Report Date',
                        value: _formatDate(_complaintData?['createdAt'] != null
                            ? DateTime.tryParse(_complaintData!['createdAt'].toString())
                            : null),
                      ),
                      _buildDetailItem(
                        icon: Icons.thumb_up,
                        label: 'Upvotes',
                        value: _complaintData?['upvoteCount']?.toString() ?? '0',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _complaintData?['locationAddress']?.toString() ?? 'No address',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: _openMapNavigation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _complaintData?['description']?.toString() ?? 'No description provided',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Resolution Section (only when started or completed)
                  if (_isStarted || _isCompleted) ...[
                    const Text(
                      'Resolution Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // After Photo
                    const Text(
                      'After Photo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickAfterPhoto,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: _afterPhoto != null
                            ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_afterPhoto!, fit: BoxFit.cover),
                            ),
                            if (!_photoUploaded)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _uploadPhoto,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.cloud_upload, size: 16),
                                  label: Text(_isSubmitting ? 'Uploading...' : 'Upload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                            if (_photoUploaded)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ),
                          ],
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to take after photo',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resolution Notes
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Resolution Notes',
                        hintText: 'Describe what was done to resolve the issue...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button (only when started, not completed)
                    if (_isStarted && !_isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitResolution,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isSubmitting ? 'Submitting...' : 'Submit Resolution'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _materialsController.dispose();
    super.dispose();
  }
}