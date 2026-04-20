import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../services/AuthService.dart';
import '../../models/complaint_model.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ComplaintService _complaintService = ComplaintService();
  final AuthService _authService = AuthService();

  List<Complaint> _allComplaints = [];
  List<Complaint> _activeComplaints = [];
  List<Complaint> _resolvedComplaints = [];
  List<Complaint> _rejectedComplaints = [];

  bool _isLoading = true;
  String? _errorMessage;

  int _totalCount = 0;
  int _activeCount = 0;
  int _resolvedCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyComplaints();
  }

  Future<void> _loadMyComplaints() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final complaints = await _complaintService.getUserComplaints();

      setState(() {
        _allComplaints = complaints;

        // Filter complaints
        _activeComplaints = complaints.where((c) =>
        c.currentStatus != 5 && c.currentStatus != 8).toList();
        _resolvedComplaints = complaints.where((c) =>
        c.currentStatus == 5 || c.currentStatus == 8).toList();
        _rejectedComplaints = complaints.where((c) =>
        c.currentStatus == 7).toList();

        // Update counts
        _totalCount = complaints.length;
        _activeCount = _activeComplaints.length;
        _resolvedCount = _resolvedComplaints.length;
        _rejectedCount = _rejectedComplaints.length;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day} ${_getMonth(dateTime.month)} ${dateTime.year}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _getStatusColor(int status) {
    switch (status) {
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

  String _getStatusText(int status) {
    switch (status) {
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
          'My Complaints',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadMyComplaints,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('$_totalCount', 'Total', Colors.grey[700]!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('$_activeCount', 'Active', Colors.blue[600]!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('$_resolvedCount', 'Resolved', Colors.green[600]!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('$_rejectedCount', 'Rejected', Colors.red[600]!),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2196F3),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF2196F3),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Resolved'),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              onPressed: _loadMyComplaints,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintsList(_allComplaints),
          _buildComplaintsList(_activeComplaints),
          _buildComplaintsList(_resolvedComplaints),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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

  Widget _buildComplaintsList(List<Complaint> complaints) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No complaints found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildComplaintCard(complaints[index]),
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/complaint-detail',
            arguments: complaint.complaintId,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Category', // You can add category name from another service
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.currentStatus),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusText(complaint.currentStatus),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.locationAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    '${complaint.upvoteCount} votes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    complaint.complaintNumber ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}