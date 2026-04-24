// lib/screens/staff/resolution_upload_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/staff_action_service.dart';

class ResolutionUploadScreen extends StatefulWidget {
  const ResolutionUploadScreen({super.key});

  @override
  State<ResolutionUploadScreen> createState() => _ResolutionUploadScreenState();
}

class _ResolutionUploadScreenState extends State<ResolutionUploadScreen> {
  final StaffActionService _staffActionService = StaffActionService();
  final ImagePicker _imagePicker = ImagePicker();

  // Will be set from arguments
  String _assignmentId = '';
  String _staffId = '';
  String _complaintTitle = '';
  String _complaintNumber = '';

  final TextEditingController _notesController = TextEditingController();
  File? _afterPhoto;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _photoUploaded = false;
  String? _uploadedPhotoUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _assignmentId.isEmpty) {
      setState(() {
        _assignmentId = args['assignmentId']?.toString() ?? '';
        _staffId = args['staffId']?.toString() ?? '';
        _complaintTitle = args['complaintTitle']?.toString() ?? '';
        _complaintNumber = args['complaintNumber']?.toString() ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _notesController.addListener(() {
      setState(() {});
    });
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

    setState(() => _isSubmitting = true);

    try {
      final result = await _staffActionService.uploadResolutionPhoto(
        _assignmentId,
        _staffId,
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

  Future<void> _submitResolution() async {
    if (_notesController.text.trim().isEmpty) {
      _showError('Please enter resolution notes');
      return;
    }

    if (_assignmentId.isEmpty || _staffId.isEmpty) {
      _showError('Missing task information');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // First upload photo if available and not yet uploaded
      String? photoUrl;
      if (_afterPhoto != null && !_photoUploaded) {
        final result = await _staffActionService.uploadResolutionPhoto(
          _assignmentId,
          _staffId,
          _afterPhoto!,
        );
        photoUrl = result['photoUrl'];
      } else if (_photoUploaded) {
        photoUrl = _uploadedPhotoUrl;
      }

      // Submit resolution
      await _staffActionService.resolveComplaint(
        _assignmentId,
        _staffId,
        _notesController.text.trim(),
        afterPhotoUrl: photoUrl,
      );

      if (mounted) {
        _showSuccess('Resolution submitted successfully!');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
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

  @override
  Widget build(BuildContext context) {
    if (_assignmentId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Submit Resolution', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canSubmit = _notesController.text.trim().isNotEmpty && !_isSubmitting;
    final hasPhoto = _afterPhoto != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Submit Resolution',
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Complaint Info
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complaint',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _complaintTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_complaintNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _complaintNumber,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Assignment ID: ${_assignmentId.substring(0, 8)}...',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // After Photo (Required for evidence)
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
                  Row(
                    children: [
                      const Text(
                        'After Photo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Recommended',
                          style: TextStyle(fontSize: 10, color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickAfterPhoto,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _afterPhoto != null
                          ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _afterPhoto!,
                              fit: BoxFit.cover,
                            ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo of the resolved issue',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_photoUploaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Photo uploaded successfully!',
                                style: TextStyle(fontSize: 12, color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Resolution Notes
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
                    'Resolution Notes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe how you resolved the issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canSubmit ? _submitResolution : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Resolution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}