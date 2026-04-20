import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import 'location_picker_screen.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/AuthService.dart';

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({super.key});

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final ComplaintService _complaintService = ComplaintService();
  final AuthService _authService = AuthService();

  // Location coordinates
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Image selection
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  static const int maxPhotos = 5;

  // Category mapping - UPDATED to match your category names
  // CORRECT MAPPING based on your database
  final Map<String, String> _categoryNameToIdMap = {
    // Garbage related
    'Garbage': '872D2E33-34B8-4269-8FE6-1094933F3F28',
    'Garbage Collection': '872D2E33-34B8-4269-8FE6-1094933F3F28',

    // Road Damage related
    'Road Damage': '990F0D40-18CC-49D9-9DEF-745AC0C37897',
    'Road Potholes': 'C4D4F4D0-4444-4F4D-DDDD-555555555555',
    'Pothole Repair': '5E442C80-0F96-42C3-BE37-25564F1486A6',

    // Street Light related
    'Street Light': 'C1A1F1D0-1111-4F1A-AAAA-111111111111',
    'Street Light Issue': 'C1A1F1D0-1111-4F1A-AAAA-111111111111',
    'Street Light Out': '0EE17281-2E49-4F83-8B08-5415FA19DD25',

    // Water related
    'Water Supply': 'EEFE8153-24C9-4BDC-AB1C-3EEE3CAADBE1',
    'Water Supply Issue': 'EEFE8153-24C9-4BDC-AB1C-3EEE3CAADBE1',
    'Water Leakage': 'C3C3F3D0-3333-4F3C-CCCC-444444444444',

    // Sewerage related
    'Sewerage': 'CEACEB99-FA5F-4D00-805D-E9EF5D73608C',
    'Sewerage Blockage': 'CEACEB99-FA5F-4D00-805D-E9EF5D73608C',

    // Park related
    'Parks': '06D9763D-FC9A-437F-9F65-F03C76AAFE78',
    'Park Maintenance': '06D9763D-FC9A-437F-9F65-F03C76AAFE78',

    // Illegal Dumping
    'Illegal Dumping': '5A5CB970-3670-4668-BE31-449B12D75192',
  };

  // Get category from arguments
  String? get _category => ModalRoute.of(context)?.settings.arguments as String?;

  // ======================================================
  // IMAGE PICKER METHODS - YOUR ORIGINAL CODE (UNCHANGED)
  // ======================================================

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images != null) {
      setState(() {
        if (_selectedImages.length + images.length <= maxPhotos) {
          _selectedImages.addAll(images);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $maxPhotos photos allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (_selectedImages.length < maxPhotos) {
          _selectedImages.add(image);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $maxPhotos photos allowed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery (Multiple)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImages(String complaintId, String userId) async {
    for (var image in _selectedImages) {
      await _uploadSingleImage(complaintId, userId, image);
    }
  }

  Future<void> _uploadSingleImage(String complaintId, String userId, XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/complaint-media/complaint/$complaintId/upload?uploadedById=$userId'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: http.MediaType('image', 'jpeg'),
      ),
    );

    var response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload image: ${image.path}');
    }
  }

  // ======================================================
  // LOCATION PICKER METHOD - YOUR ORIGINAL CODE (UNCHANGED)
  // ======================================================

  Future<void> _openLocationPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          onLocationSelected: (lat, lng, address) {
            setState(() {
              _locationController.text = address;
              _selectedLatitude = lat;
              _selectedLongitude = lng;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? category = _category;

    return Scaffold(
      backgroundColor: Colors.grey[50],  // ← YOUR ORIGINAL BACKGROUND
      appBar: AppBar(
        backgroundColor: Colors.white,   // ← YOUR ORIGINAL APP BAR
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Issue Details',
          style: TextStyle(color: Colors.grey[900]),  // ← YOUR ORIGINAL STYLE
        ),
      ),
      body: Column(
        children: [
          // Progress indicator - YOUR ORIGINAL UI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                _buildProgressCircle(1, true),
                Expanded(child: Container(height: 2, color: const Color(0xFF2196F3))),
                _buildProgressCircle(2, true),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provide Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],  // ← YOUR ORIGINAL STYLE
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us understand the issue better',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],  // ← YOUR ORIGINAL STYLE
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category display - YOUR ORIGINAL UI
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          'Category: $category',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Photo upload section - YOUR ORIGINAL UI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upload Photos (${_selectedImages.length}/$maxPhotos)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],  // ← YOUR ORIGINAL STYLE
                          ),
                        ),
                        if (_selectedImages.length < maxPhotos)
                          TextButton.icon(
                            onPressed: _showImageSourceDialog,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Photos'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Image grid - YOUR ORIGINAL UI
                    if (_selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],  // ← YOUR ORIGINAL
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),  // ← YOUR ORIGINAL
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add photos',
                                style: TextStyle(color: Colors.grey),  // ← YOUR ORIGINAL
                              ),
                              Text(
                                '($maxPhotos max)',
                                style: TextStyle(color: Colors.grey, fontSize: 12),  // ← YOUR ORIGINAL
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Title field - YOUR ORIGINAL UI
                    TextFormField(
                      style: const TextStyle(color: Colors.black),  // ← YOUR ORIGINAL
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Issue Title',
                        hintText: 'Brief description of the issue',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,  // ← YOUR ORIGINAL
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field - YOUR ORIGINAL UI
                    TextFormField(
                      style: const TextStyle(color: Colors.black),  // ← YOUR ORIGINAL
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Provide detailed information about the issue',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,  // ← YOUR ORIGINAL
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location field with map picker - YOUR ORIGINAL UI
                    TextFormField(
                      style: const TextStyle(color: Colors.black),  // ← YOUR ORIGINAL
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'Select location on map',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: _openLocationPicker,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,  // ← YOUR ORIGINAL
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a location';
                        }
                        return null;
                      },
                      readOnly: true,
                    ),

                    // Coordinates display - YOUR ORIGINAL UI
                    if (_selectedLatitude != null && _selectedLongitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Coordinates: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],  // ← YOUR ORIGINAL
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Info card - YOUR ORIGINAL UI
                    Card(
                      color: Colors.blue[50],  // ← YOUR ORIGINAL
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue[100]!),  // ← YOUR ORIGINAL
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),  // ← YOUR ORIGINAL
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your report will be reviewed by the department admin before assignment to field staff.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,  // ← YOUR ORIGINAL
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Submit button - YOUR ORIGINAL UI with UPDATED logic
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,  // ← YOUR ORIGINAL
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),  // ← YOUR ORIGINAL
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // ===== ADDED: Validate category first =====
                  if (category == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No category selected. Please go back and select a category.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_formKey.currentState!.validate()) {
                    if (_selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one photo')),
                      );
                      return;
                    }

                    if (_selectedLatitude == null || _selectedLongitude == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a location on map')),
                      );
                      return;
                    }

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      // Get citizenId from AuthService
                      final citizenId = await _authService.getUserId();

                      if (citizenId == null) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not logged in. Please login again.')),
                          );
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                        return;
                      }

                      // ===== UPDATED: Convert category name to ID =====
                      final categoryId = _categoryNameToIdMap[category];
                      if (categoryId == null) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Invalid category: $category'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      // Create complaint data
                      final complaintData = {
                        'title': _titleController.text,
                        'description': _descriptionController.text,
                        'categoryId': categoryId,  // ← Now using mapped ID
                        'locationAddress': _locationController.text,
                        'locationLatitude': _selectedLatitude!,
                        'locationLongitude': _selectedLongitude!

                      };

                      print('Submitting complaint: $complaintData');

                      final response = await _complaintService.submitComplaint(complaintData);
                      print('Response: $response');

                      // Extract complaintId from response
                      String complaintId = '';

                      if (response is Map<String, dynamic>) {
                        complaintId = response['complaintId'] ??
                            response['id'] ??
                            response['data']?['complaintId'] ??
                            response['complaint']?['complaintId'] ??
                            '';
                      }

                      if (complaintId.isEmpty) {
                        throw Exception('Could not get complaint ID from response');
                      }

                      // Upload images
                      if (_selectedImages.isNotEmpty) {
                        await _uploadImages(complaintId, citizenId);
                      }

                      Navigator.pop(context); // Close loading dialog

                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 28),
                                SizedBox(width: 12),
                                Text('Success!'),
                              ],
                            ),
                            content: Text(
                              'Your complaint has been submitted successfully with ${_selectedImages.length} photo(s).',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                        (route) => false,
                                  );
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context); // Close loading dialog
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                      print('Error submitting complaint: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),  // ← YOUR ORIGINAL
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,  // ← YOUR ORIGINAL
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // YOUR ORIGINAL progress circle widget
  Widget _buildProgressCircle(int step, bool active) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2196F3) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}