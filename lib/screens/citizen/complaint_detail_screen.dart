// lib/screens/citizen/complaint_detail_screen.dart
import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import '../../models/ComplaintStatusHistory.dart';

class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  final AuthService _authService = AuthService();
  final ComplaintService _complaintService = ComplaintService();

  bool _isUpvoted = false;
  bool _isLoading = true;
  bool _isLoadingPhotos = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  Complaint? _complaint;
  List<dynamic> _photos = [];
  List<ComplaintStatusHistory> _statusHistory = [];
  String? _complaintId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaintId == null && mounted) {
      _extractComplaintId();
    }
  }

  void _extractComplaintId() {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      _complaintId = args;
    } else if (args is Map) {
      _complaintId = args['complaintId']?.toString() ?? args['id']?.toString();
    }

    if (_complaintId != null) {
      _loadComplaintData();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'No complaint ID provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComplaintData() async {
    if (_complaintId == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final complaint = await _complaintService.getComplaintDetails(_complaintId!);

      if (mounted) {
        setState(() {
          _complaint = complaint;
          _isLoading = false;
        });
        _loadAdditionalData(_complaintId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAdditionalData(String complaintId) async {
    await Future.wait([
      _loadPhotos(complaintId),
      _loadStatusHistory(complaintId),
    ]);
  }

  Future<void> _loadPhotos(String complaintId) async {
    if (!mounted) return;
    setState(() => _isLoadingPhotos = true);

    try {
      final photos = await _complaintService.getComplaintPhotos(complaintId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Photo loading timed out');
          return [];
        },
      );
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
      }
    }
  }

  Future<void> _loadStatusHistory(String complaintId) async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);

    try {
      final history = await _complaintService.getComplaintStatusHistory(complaintId).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('History loading timed out');
          return [];
        },
      );
      if (mounted) {
        setState(() {
          _statusHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('Error loading status history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _handleUpvote() async {
    if (_isUpvoted || _complaint == null || !mounted) return;

    final userId = await _authService.getUserId();
    if (userId == null) return;

    setState(() => _isUpvoted = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks for your support!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _getStatusText() {
    if (_complaint != null) {
      switch (_complaint!.currentStatus) {
        case 0: return 'Submitted';
        case 1: return 'Under Review';
        case 2: return 'Approved';
        case 3: return 'Assigned';
        case 4: return 'In Progress';
        case 5: return 'Resolved';
        case 6: return 'Verified';
        case 7: return 'Rejected';
        case 8: return 'Closed';
        default: return 'Pending';
      }
    }
    return 'Pending';
  }

  Color _getStatusColor() {
    if (_complaint != null) {
      switch (_complaint!.currentStatus) {
        case 0: return Colors.orange;
        case 1: return Colors.purple;
        case 2: return Colors.green;
        case 3: return Colors.blue;
        case 4: return Colors.indigo;
        case 5: return Colors.green;
        case 6: return Colors.teal;
        case 7: return Colors.red;
        case 8: return Colors.grey;
        default: return Colors.blue;
      }
    }
    return Colors.blue;
  }

  IconData _getStatusIcon() {
    if (_complaint != null) {
      switch (_complaint!.currentStatus) {
        case 0: return Icons.hourglass_empty;
        case 1: return Icons.visibility;
        case 2: return Icons.check_circle;
        case 3: return Icons.person;
        case 4: return Icons.build;
        case 5: return Icons.done_all;
        case 6: return Icons.verified;
        case 7: return Icons.cancel;
        case 8: return Icons.lock;
        default: return Icons.pending;
      }
    }
    return Icons.pending;
  }

  String _getLastUpdated() {
    if (_complaint?.updatedAt != null) {
      final now = DateTime.now();
      final diff = now.difference(_complaint!.updatedAt!);

      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    }
    return 'Today';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Complaint Details', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Complaint Details', style: TextStyle(color: Colors.grey[900])),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadComplaintData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final upvotes = (_complaint?.upvoteCount ?? 0) + (_isUpvoted ? 1 : 0);

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
          'Complaint Details',
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: _getStatusColor().withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                        Text(
                          'Last updated: ${_getLastUpdated()}',
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
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _complaint?.title ?? 'Complaint Title',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _complaint?.complaintNumber ?? 'CCMW-XXXX-XXXX',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildDetailRow(
                    icon: Icons.location_on,
                    title: 'Location',
                    value: _complaint?.locationAddress ?? 'Unknown Location',
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _complaint?.description ?? 'No description provided',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoadingPhotos)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_photos.isNotEmpty) ...[
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          String photoUrl = '';
                          if (photo is Map) {
                            photoUrl = photo['photoUrl']?.toString() ??
                                photo['PhotoUrl']?.toString() ??
                                photo['url']?.toString() ?? '';
                          } else if (photo is String) {
                            photoUrl = photo;
                          }

                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: photoUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            )
                                : const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 24),

                  if (_isLoadingHistory)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_statusHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/complaint-status-history',
                            arguments: {
                              'complaintId': _complaint!.complaintId,
                              'complaintNumber': _complaint!.complaintNumber,
                              'complaintTitle': _complaint!.title,
                              'history': _statusHistory.map((h) => h.toJson()).toList(),
                            },
                          );
                        },
                        icon: const Icon(Icons.history, size: 18),
                        label: Text(
                          'View Full Status History (${_statusHistory.length})',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Community Support',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$upvotes people reported similar issue',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isUpvoted ? null : _handleUpvote,
                          icon: const Icon(Icons.thumb_up, size: 16),
                          label: const Text('Upvote'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
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
    if (_statusHistory.isEmpty) {
      final steps = [
        {'status': 'Reported', 'time': _formatDate(_complaint?.createdAt), 'completed': true},
        {'status': 'Under Review', 'time': 'Processing', 'completed': _complaint?.currentStatus != 0},
        {'status': 'Assigned', 'time': 'Processing', 'completed': _complaint?.currentStatus != 0 && _complaint?.currentStatus != 1},
        {'status': 'In Progress', 'time': 'Processing', 'completed': _complaint?.currentStatus != 0 && _complaint?.currentStatus != 1 && _complaint?.currentStatus != 2 && _complaint?.currentStatus != 3},
        {'status': 'Resolved', 'time': _complaint?.currentStatus == 5 ? _formatDate(_complaint?.resolvedAt) : 'Pending', 'completed': _complaint?.currentStatus == 5},
      ];

      return Column(
        children: steps.map((step) {
          final isCompleted = step['completed'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? Colors.green : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    if (step != steps.last)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['status'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? Colors.black : Colors.grey,
                        ),
                      ),
                      Text(
                        step['time'].toString(),
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

    return Column(
      children: _statusHistory.map((history) {
        final isLast = history == _statusHistory.last;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.green,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.newStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _formatDateTime(history.changedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (history.notes != null && history.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          history.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}