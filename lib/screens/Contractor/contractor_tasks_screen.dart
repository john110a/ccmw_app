import 'package:flutter/material.dart';
import '../../services/contractor_service.dart';
import '../../services/AuthService.dart';
import '../../models/complaint_model.dart';
import '../../config/routes.dart';

class ContractorTasksScreen extends StatefulWidget {
  const ContractorTasksScreen({super.key});

  @override
  State<ContractorTasksScreen> createState() => _ContractorTasksScreenState();
}

class _ContractorTasksScreenState extends State<ContractorTasksScreen> {
  final ContractorService _contractorService = ContractorService();
  final AuthService _authService = AuthService();

  List<Complaint> _activeComplaints = [];
  List<Complaint> _completedComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'active';
  String? _contractorId;
  String? _selectedZoneId;

  @override
  void initState() {
    super.initState();
    _loadContractorData();
  }

  Future<void> _loadContractorData() async {
    setState(() => _isLoading = true);

    try {
      _contractorId = await _authService.getContractorId();
      if (_contractorId == null) {
        throw Exception('Contractor ID not found');
      }

      // Get assigned zones first
      final zones = await _contractorService.getAssignedZones(_contractorId!);

      if (zones.isNotEmpty) {
        _selectedZoneId = zones.first.zoneId;
        await _loadComplaints();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComplaints() async {
    if (_selectedZoneId == null) return;

    setState(() => _isLoading = true);

    try {
      // Get complaints for the selected zone
      final complaints = await _contractorService.getZoneComplaints(_selectedZoneId!);

      setState(() {
        _activeComplaints = complaints.where((c) =>
        c.currentStatus != 5 && c.currentStatus != 8).toList();
        _completedComplaints = complaints.where((c) =>
        c.currentStatus == 5 || c.currentStatus == 8).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToComplaintDetail(Complaint complaint) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.complaintDetail,
      arguments: complaint.complaintId,
    );

    if (result == true && mounted) {
      _loadComplaints();
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Submitted';
      case 1: return 'Pending';
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
          'Zone Complaints',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadComplaints,
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
              onPressed: _loadContractorData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${_activeComplaints.length}',
                    'Active',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${_completedComplaints.length}',
                    'Resolved',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${_activeComplaints.length + _completedComplaints.length}',
                    'Total',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Tab Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'active'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'active' ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Active (${_activeComplaints.length})',
                          style: TextStyle(
                            color: _selectedTab == 'active' ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 'completed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'completed' ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Resolved (${_completedComplaints.length})',
                          style: TextStyle(
                            color: _selectedTab == 'completed' ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Complaints List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComplaints,
              child: _selectedTab == 'active' && _activeComplaints.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No active complaints', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('All complaints resolved!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _selectedTab == 'active'
                    ? _activeComplaints.length
                    : _completedComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = _selectedTab == 'active'
                      ? _activeComplaints[index]
                      : _completedComplaints[index];
                  return _buildComplaintCard(complaint);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final priorityColor = _getPriorityColor(complaint.priority);
    final statusText = _getStatusText(complaint.currentStatus);
    final statusColor = complaint.currentStatus == 5
        ? Colors.green
        : complaint.currentStatus == 4
        ? Colors.blue
        : complaint.currentStatus == 2
        ? Colors.lightBlue
        : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToComplaintDetail(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      complaint.priority,
                      style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.complaintNumber ?? 'No Number',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.locationAddress,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.upvoteCount}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(complaint.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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