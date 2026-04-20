import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';

class PublicComplaintsScreen extends StatefulWidget {
  const PublicComplaintsScreen({super.key});

  @override
  State<PublicComplaintsScreen> createState() => _PublicComplaintsScreenState();
}

class _PublicComplaintsScreenState extends State<PublicComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService();

  List<Complaint> _complaints = [];
  List<Complaint> _filteredComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  int _totalIssues = 0;
  int _activeIssues = 0;
  int _resolvedIssues = 0;
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _loadPublicComplaints();
    _searchController.addListener(_filterComplaints);
  }

  Future<void> _loadPublicComplaints() async {
    setState(() => _isLoading = true);

    try {
      // Get complaints from API (using Karachi coordinates as default)
      final complaints = await _complaintService.getMapComplaints(
        lat: 24.8607,
        lng: 67.0011,
        radiusKm: 20.0,
      );

      setState(() {
        _complaints = complaints;
        _filteredComplaints = complaints;
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
    _totalIssues = complaints.length;
    _activeIssues = complaints.where((c) =>
    c.currentStatus != 5 && c.currentStatus != 8).length;
    _resolvedIssues = complaints.where((c) =>
    c.currentStatus == 5 || c.currentStatus == 8).length;
    _totalVotes = complaints.fold(0, (sum, c) => sum + c.upvoteCount);
  }

  void _filterComplaints() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredComplaints = _complaints);
    } else {
      setState(() {
        _filteredComplaints = _complaints.where((c) =>
        c.title.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query) ||
            c.locationAddress.toLowerCase().contains(query)
        ).toList();
      });
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
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
      case 0: return 'Active';
      case 1: return 'Under Review';
      case 2: return 'Approved';
      case 3: return 'Assigned';
      case 4: return 'In Progress';
      case 5: return 'Resolved';
      case 6: return 'Verified';
      case 7: return 'Rejected';
      case 8: return 'Closed';
      default: return 'Active';
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
          'Public Issues',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadPublicComplaints,
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
              onPressed: _loadPublicComplaints,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search public issues...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPublicStat('$_totalIssues', 'Total Issues'),
                _buildPublicStat('$_activeIssues', 'Active'),
                _buildPublicStat('$_resolvedIssues', 'Resolved'),
                _buildPublicStat('$_totalVotes', 'Total Votes'),
              ],
            ),
          ),

          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No public issues found'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredComplaints.length,
              itemBuilder: (context, index) {
                return _buildPublicComplaintCard(_filteredComplaints[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Issues'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() => _filteredComplaints = _complaints);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Active'),
              onTap: () {
                setState(() {
                  _filteredComplaints = _complaints.where((c) =>
                  c.currentStatus != 5 && c.currentStatus != 8).toList();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Resolved'),
              onTap: () {
                setState(() {
                  _filteredComplaints = _complaints.where((c) =>
                  c.currentStatus == 5 || c.currentStatus == 8).toList();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
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

  Widget _buildPublicComplaintCard(Complaint complaint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Category', // You can add category name from another service
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
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
                const Spacer(),
                Text(
                  complaint.complaintNumber ?? 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
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
              ],
            ),
            const SizedBox(height: 12),

            // Interactive Stats
            Row(
              children: [
                Expanded(
                  child: _buildInteractionButton(
                    icon: Icons.thumb_up_outlined,
                    count: complaint.upvoteCount,
                    active: false,
                    onTap: () {
                      // Implement upvote functionality
                    },
                  ),
                ),
                Expanded(
                  child: _buildInteractionButton(
                    icon: Icons.comment_outlined,
                    count: 0, // Comments not implemented yet
                    active: false,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _buildInteractionButton(
                    icon: Icons.share_outlined,
                    count: 'Share',
                    active: false,
                    isText: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon')),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildInteractionButton(
                    icon: Icons.flag_outlined,
                    count: 'Report',
                    active: false,
                    isText: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reported to administrators')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Posted By Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reported by Citizen',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _getTimeAgo(complaint.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/complaint-detail',
                        arguments: complaint.complaintId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required dynamic count,
    required bool active,
    required VoidCallback onTap,
    bool isText = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            if (isText)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.blue : Colors.grey[600],
                ),
              )
            else
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.blue : Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}