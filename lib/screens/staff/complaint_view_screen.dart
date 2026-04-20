import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StaffComplaintViewScreen extends StatefulWidget {
  const StaffComplaintViewScreen({super.key});

  @override
  State<StaffComplaintViewScreen> createState() => _StaffComplaintViewScreenState();
}

class _StaffComplaintViewScreenState extends State<StaffComplaintViewScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _afterImage;
  String _status = 'In Progress';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _materialsController = TextEditingController();
  
  final Map<String, dynamic> complaint = {
    'id': 'CCMW-2024-1234',
    'title': 'Garbage heap on street corner',
    'category': 'Garbage',
    'location': 'Tariq Road, Zone 5',
    'reportedBy': 'Ahmad Ali',
    'reportDate': 'Oct 18, 2025',
    'upvotes': 12,
    'description': 'Large garbage pile accumulated on the street corner near the mosque. Needs immediate attention.',
    'priority': 'High',
    'priorityColor': Colors.red,
    'assignedDate': 'Oct 19, 2025',
    'deadline': 'Oct 20, 2025',
  };

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _afterImage = image;
      });
    }
  }

  void _updateStatus(String newStatus) {
    setState(() {
      _status = newStatus;
    });
  }

  void _submitResolution() {
    if (_afterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload after photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add resolution notes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Resolution Submitted'),
          ],
        ),
        content: const Text(
          'Your resolution has been submitted for verification. Department admin will review it shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Task Details',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Task Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _status,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _updateStatus,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                      const PopupMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      const PopupMenuItem(
                        value: 'On Hold',
                        child: Text('On Hold'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: complaint['priorityColor'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          complaint['priority'],
                          style: TextStyle(
                            fontSize: 12,
                            color: complaint['priorityColor'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        complaint['id'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    complaint['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                        value: complaint['category'],
                      ),
                      _buildDetailItem(
                        icon: Icons.person,
                        label: 'Reported By',
                        value: complaint['reportedBy'],
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        label: 'Report Date',
                        value: complaint['reportDate'],
                      ),
                      _buildDetailItem(
                        icon: Icons.thumb_up,
                        label: 'Upvotes',
                        value: '${complaint['upvotes']}',
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                complaint['location'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.directions, color: Colors.blue),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Timeline
                  const Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimeline(),
                  const SizedBox(height: 24),
                  
                  // Resolution Section
                  const Text(
                    'Resolution Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // After Photo
                  const Text(
                    'Upload After Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _afterImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to take after photo',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_afterImage!.path),
                                fit: BoxFit.cover,
                              ),
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
                  
                  // Materials Used
                  TextField(
                    style: const TextStyle(color: Colors.black),
                    controller: _materialsController,
                    decoration: const InputDecoration(
                      labelText: 'Materials Used (Optional)',
                      hintText: 'List materials used...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitResolution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit Resolution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final steps = [
      {'step': 'Reported', 'date': complaint['reportDate'], 'completed': true},
      {'step': 'Approved', 'date': 'Oct 19, 2025', 'completed': true},
      {'step': 'Assigned', 'date': complaint['assignedDate'], 'completed': true},
      {'step': 'In Progress', 'date': 'Today', 'completed': _status == 'In Progress' || _status == 'Completed'},
      {'step': 'Completed', 'date': complaint['deadline'], 'completed': _status == 'Completed'},
    ];

    return Column(
      children: steps.map((step) {
        final isCompleted = step['completed'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['step'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isCompleted ? Colors.black : Colors.grey,
                      ),
                    ),
                    Text(
                      step['date'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _materialsController.dispose();
    super.dispose();
  }
}
