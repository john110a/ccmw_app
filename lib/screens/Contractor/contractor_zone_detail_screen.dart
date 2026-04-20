// lib/screens/Contractor/contractor_zone_detail_screen.dart
import 'package:flutter/material.dart';
import '../../services/contractor_service.dart';
import '../../models/complaint_model.dart';

class ContractorZoneDetailScreen extends StatefulWidget {
  const ContractorZoneDetailScreen({super.key});

  @override
  State<ContractorZoneDetailScreen> createState() => _ContractorZoneDetailScreenState();
}

class _ContractorZoneDetailScreenState extends State<ContractorZoneDetailScreen> {
  final ContractorService _contractorService = ContractorService();

  Map<String, dynamic>? _zone;
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Active', 'Resolved', 'In Progress'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _zone == null) {
      setState(() {
        _zone = args;
        _isLoading = false;
      });
      _loadZoneComplaints();
    }
  }

  Future<void> _loadZoneComplaints() async {
    if (_zone == null) return;

    setState(() => _isLoading = true);
    try {
      final complaints = await _contractorService.getZoneComplaints(_zone!['zoneId']);
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Complaint> get _filteredComplaints {
    if (_selectedFilter == 'All') return _complaints;
    if (_selectedFilter == 'Active') {
      return _complaints.where((c) =>
      c.currentStatus != 5 && c.currentStatus != 6 && c.currentStatus != 8
      ).toList();
    }
    if (_selectedFilter == 'Resolved') {
      return _complaints.where((c) => c.currentStatus == 5 || c.currentStatus == 6).toList();
    }
    if (_selectedFilter == 'In Progress') {
      return _complaints.where((c) => c.currentStatus == 4).toList();
    }
    return _complaints;
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.lightBlue;
      case 3: return Colors.purple;
      case 4: return Colors.indigo;
      case 5: return Colors.green;
      case 6: return Colors.teal;
      case 7: return Colors.red;
      case 8: return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _showComplaintDetails(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              complaint.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              complaint.complaintNumber ?? 'No Number',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            _buildDetailRow('Status', _getStatusText(complaint.currentStatus),
                color: _getStatusColor(complaint.currentStatus)),
            _buildDetailRow('Priority', complaint.priority,
                color: complaint.priority == 'High' ? Colors.red : Colors.orange),
            _buildDetailRow('Category', complaint.categoryName ?? 'General'),
            _buildDetailRow('Location', complaint.locationAddress),
            _buildDetailRow('Submitted', _formatDate(complaint.createdAt)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to resolution upload
                  Navigator.pushNamed(
                    context,
                    '/resolution-upload',
                    arguments: {
                      'complaintId': complaint.complaintId,
                      'complaintTitle': complaint.title,
                    },
                  );
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text('Upload Resolution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (_zone == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Zone Details', style: TextStyle(color: Colors.grey[900])),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeCount = _complaints.where((c) =>
    c.currentStatus != 5 && c.currentStatus != 6 && c.currentStatus != 8
    ).length;
    final resolvedCount = _complaints.where((c) =>
    c.currentStatus == 5 || c.currentStatus == 6
    ).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_zone!['zoneName'] ?? 'Zone Details', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadZoneComplaints,
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('${_complaints.length}', 'Total', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('$activeCount', 'Active', Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('$resolvedCount', 'Resolved', Colors.green),
                ),
              ],
            ),
          ),

          // Contract Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business_center, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Contract Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildContractRow('Service Type', _zone!['serviceType'] ?? 'N/A'),
                _buildContractRow('Contract Period',
                    '${_zone!['contractStart']?.toString().split('T')[0] ?? 'N/A'} - ${_zone!['contractEnd']?.toString().split('T')[0] ?? 'N/A'}'),
                _buildContractRow('Contract Value', 'Rs. ${_zone!['contractValue']?.toString() ?? '0'}'),
                _buildContractRow('Performance Bond', 'Rs. ${_zone!['performanceBond']?.toString() ?? '0'}'),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue[100],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredComplaints.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No complaints found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadZoneComplaints,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = _filteredComplaints[index];
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

  Widget _buildContractRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final statusColor = _getStatusColor(complaint.currentStatus);
    final priorityColor = complaint.priority == 'High'
        ? Colors.red
        : complaint.priority == 'Medium'
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showComplaintDetails(complaint),
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
                      style: TextStyle(fontSize: 11, color: priorityColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(complaint.currentStatus),
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.thumb_up, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${complaint.upvoteCount}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}