// lib/screens/citizen/complaint_status_history_screen.dart

import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';
import '../../models/ComplaintStatusHistory.dart';

class ComplaintStatusHistoryScreen extends StatefulWidget {
  const ComplaintStatusHistoryScreen({super.key});

  @override
  State<ComplaintStatusHistoryScreen> createState() => _ComplaintStatusHistoryScreenState();
}

class _ComplaintStatusHistoryScreenState extends State<ComplaintStatusHistoryScreen> {
  final ComplaintService _complaintService = ComplaintService();

  List<ComplaintStatusHistory> _history = [];
  Complaint? _complaint;
  bool _isLoading = true;
  String? _errorMessage;

  // Store complaintId separately
  String? _complaintId;

  @override
  void initState() {
    super.initState();
    // Don't access ModalRoute here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access arguments here instead of initState
    if (_complaintId == null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args == null) {
        throw Exception('No data provided');
      }

      String? complaintId;
      Complaint? complaint;

      if (args is String) {
        complaintId = args;
      } else if (args is Map) {
        complaintId = args['complaintId']?.toString();
        complaint = args['complaint'];
      } else if (args is Complaint) {
        complaint = args;
        complaintId = complaint.complaintId;
      }

      if (complaintId == null || complaintId.isEmpty) {
        throw Exception('No complaint ID provided');
      }

      // Store complaintId for future refreshes
      _complaintId = complaintId;

      // Load complaint details if not provided
      if (complaint == null) {
        try {
          complaint = await _complaintService.getComplaintDetails(complaintId);
        } catch (e) {
          print('Could not load complaint details: $e');
          // Continue without complaint details
        }
      }

      // Load status history
      final history = await _complaintService.getComplaintStatusHistory(complaintId);

      if (mounted) {
        setState(() {
          _complaint = complaint;
          _history = history;
          _isLoading = false;
        });
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
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

  String _getCurrentStatusText() {
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
        default: return 'Unknown';
      }
    }
    return 'Unknown';
  }

  Color _getCurrentStatusColor() {
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
          'Status History',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No status history found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status updates will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Complaint Summary Card
          if (_complaint != null)
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _complaint!.complaintNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCurrentStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCurrentStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _complaint!.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Timeline Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_history.length} update${_history.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Timeline List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final history = _history[index];
                final isLast = index == _history.length - 1;
                return _buildTimelineItem(history, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ComplaintStatusHistory history, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: history.getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: history.getStatusColor(),
                    width: 2,
                  ),
                ),
                child: Icon(
                  history.getStatusIcon(),
                  size: 12,
                  color: history.getStatusColor(),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Timeline content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          history.newStatus,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: history.getStatusColor(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTimeAgo(history.changedAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Changed by
                  if (history.changedByName != null && history.changedByName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'By: ${history.changedByName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Exact time
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateTime(history.changedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notes/reason
                  if (history.notes != null && history.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        history.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Change reason (if different from notes)
                  if (history.changeReason != null &&
                      history.changeReason != history.notes &&
                      history.changeReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Reason: ${history.changeReason}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}