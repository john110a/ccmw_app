import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../services/AuthService.dart';
import '../../models/complaint_model.dart';

class ApprovalStatusScreen extends StatefulWidget {
  const ApprovalStatusScreen({super.key});

  @override
  State<ApprovalStatusScreen> createState() => _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState extends State<ApprovalStatusScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final AuthService _authService = AuthService();

  int _selectedFilter = 0;
  final List<String> filters = ['All', 'Pending', 'Approved', 'Rejected'];

  List<Complaint> _complaints = [];
  List<Complaint> _filteredComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadApprovalRequests();
  }

  Future<void> _loadApprovalRequests() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final complaints = await _complaintService.getUserComplaints();

      setState(() {
        _complaints = complaints;
        _applyFilter();
        _calculateStats(complaints);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<Complaint> complaints) {
    _pendingCount = complaints.where((c) =>
    c.submissionStatus == 0).length; // PendingApproval
    _approvedCount = complaints.where((c) =>
    c.submissionStatus == 1).length; // Approved
    _rejectedCount = complaints.where((c) =>
    c.submissionStatus == 2).length; // Rejected
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 1: // Pending
          _filteredComplaints = _complaints.where((c) =>
          c.submissionStatus == 0).toList();
          break;
        case 2: // Approved
          _filteredComplaints = _complaints.where((c) =>
          c.submissionStatus == 1).toList();
          break;
        case 3: // Rejected
          _filteredComplaints = _complaints.where((c) =>
          c.submissionStatus == 2).toList();
          break;
        default: // All
          _filteredComplaints = List.from(_complaints);
      }
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day} ${_getMonth(dateTime.month)} ${dateTime.year}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
          'Approval Status',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadApprovalRequests,
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
              onPressed: _loadApprovalRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildApprovalStat(
                    '$_pendingCount',
                    'Pending',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildApprovalStat(
                    '$_approvedCount',
                    'Approved',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildApprovalStat(
                    '$_rejectedCount',
                    'Rejected',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filters[index]),
                    selected: _selectedFilter == index,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = index;
                        _applyFilter();
                      });
                    },
                    selectedColor: const Color(0xFF2196F3),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedFilter == index
                          ? Colors.white
                          : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
          ),

          // Requests List
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredComplaints.length,
              itemBuilder: (context, index) {
                return _buildApprovalCard(_filteredComplaints[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard(Complaint complaint) {
    final bool isPending = complaint.submissionStatus == 0;
    final bool isApproved = complaint.submissionStatus == 1;
    final bool isRejected = complaint.submissionStatus == 2;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending';
    } else if (isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Approved';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rejected';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Category', // You can add category name from another service
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(complaint.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  complaint.complaintNumber ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status Details
            if (isPending)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Under Review',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Estimated approval time: 24-48 hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (isApproved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Approved',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your complaint has been approved and assigned to field staff',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              )
            else if (isRejected)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Request Rejected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${complaint.rejectionReason ?? 'No reason provided'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),

            const SizedBox(height: 12),

            if (isRejected)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/report-issue');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Resubmit Request'),
              ),
          ],
        ),
      ),
    );
  }
}