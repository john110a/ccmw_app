import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../services/AuthService.dart';
import '../../models/complaint_model.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final AuthService _authService = AuthService();

  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _processingIds = {};

  // Filter and sort state
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filterOptions = [
    'All',
    'Submitted',
    'Pending',
    'Approved',
    'Assigned',
    'In Progress',
    'Resolved',
    'Closed',
    'Rejected',
    'Fake',      // ← NEW: filter for fake complaints
    'No Zone',
  ];
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Priority', 'Upvotes'];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading all complaints for admin...');
      final complaints = await _complaintService.getAllComplaints();
      print('✅ Loaded ${complaints.length} complaints');

      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading complaints: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // =====================================================
  // MARK AS FAKE
  // =====================================================
  Future<void> _markAsFake(Complaint complaint) async {
    if (_processingIds.contains(complaint.complaintId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.purple, size: 28),
            SizedBox(width: 12),
            Text('Mark as Fake Complaint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will add 1 strike to "${complaint.citizenName ?? 'citizen'}"\'s account.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3 strikes = account ban',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark as Fake'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _processingIds.add(complaint.complaintId);
    });

    try {
      final adminId = await _authService.getUserId();
      if (adminId == null) throw Exception('Admin not logged in');

      await _complaintService.markAsFake(complaint.complaintId, adminId);

      if (!mounted) return;

      await _loadComplaints();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint marked as fake. Citizen strike increased.'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Error marking as fake: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(complaint.complaintId);
        });
      }
    }
  }

  // =====================================================
  // STATS COUNTS FOR SUMMARY BAR
  // =====================================================
  int get _noZoneCount =>
      _complaints.where((c) => c.zoneName == null || c.zoneName!.isEmpty).length;

  int get _pendingApprovalCount =>
      _complaints.where((c) => c.currentStatus == 0).length;

  int get _fakeCount =>
      _complaints.where((c) => c.isFake == true).length;

  // =====================================================
  // FILTER + SORT
  // =====================================================
  List<Complaint> get _filteredAndSortedComplaints {
    List<Complaint> filtered = _complaints.where((complaint) {
      final matchesSearch = _searchQuery.isEmpty ||
          complaint.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          complaint.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (complaint.complaintNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      bool matchesFilter;
      if (_selectedFilter == 'All') {
        matchesFilter = true;
      } else if (_selectedFilter == 'No Zone') {
        matchesFilter = complaint.zoneName == null || complaint.zoneName!.isEmpty;
      } else if (_selectedFilter == 'Fake') {
        matchesFilter = complaint.isFake == true;
      } else {
        matchesFilter = _getStatusText(complaint.currentStatus) == _selectedFilter;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort
    switch (_selectedSort) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Priority':
        filtered.sort((a, b) {
          final priorityOrder = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3};
          return (priorityOrder[a.priority] ?? 4).compareTo(priorityOrder[b.priority] ?? 4);
        });
        break;
      case 'Upvotes':
        filtered.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
        break;
    }

    return filtered;
  }

  // =====================================================
  // HELPERS
  // =====================================================
  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Submitted';
      case 1: return 'Pending';
      case 2: return 'Approved';
      case 3: return 'Assigned';
      case 4: return 'In Progress';
      case 5: return 'Resolved';
      case 6: return 'Closed';
      case 7: return 'Rejected';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    if (status == 7) return Colors.red;
    switch (status) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.lightBlue;
      case 3: return Colors.purple;
      case 4: return Colors.indigo;
      case 5: return Colors.green;
      case 6: return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical': return Colors.deepOrange;
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  bool _hasZone(Complaint complaint) =>
      complaint.zoneName != null && complaint.zoneName!.isNotEmpty;

  // =====================================================
  // COMPLAINT DETAIL BOTTOM SHEET
  // =====================================================
  void _showComplaintDetails(Complaint complaint) {
    final isFake = complaint.isFake == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isFake)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.warning, size: 16, color: Colors.purple),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  complaint.complaintNumber ?? 'No Number',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Divider(height: 24),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Fake banner
                      if (isFake) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.purple, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Marked as FAKE complaint',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Zone warning banner
                      if (!_hasZone(complaint)) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.amber[800], size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No zone assigned — this complaint will not appear on the map until a zone is set.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Details
                      _buildDetailRow(
                        'Status',
                        _getStatusText(complaint.currentStatus),
                        color: _getStatusColor(complaint.currentStatus),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Priority',
                        complaint.priority,
                        color: _getPriorityColor(complaint.priority),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Category',
                        complaint.categoryName ?? 'Not set',
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Zone',
                        _hasZone(complaint)
                            ? complaint.zoneName!
                            : '⚠ No zone assigned',
                        color: _hasZone(complaint) ? Colors.blue : Colors.amber[800],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Department',
                        complaint.departmentName ?? 'Not set',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Location', complaint.locationAddress),
                      const SizedBox(height: 12),
                      _buildDetailRow('Created', _formatDate(complaint.createdAt)),
                      const SizedBox(height: 12),
                      _buildDetailRow('Upvotes', '${complaint.upvoteCount}'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Views', '${complaint.viewCount}'),
                      const SizedBox(height: 16),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(complaint.description,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          if (!isFake) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _processingIds.contains(complaint.complaintId) ? null : () => _markAsFake(complaint),
                                icon: _processingIds.contains(complaint.complaintId)
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.warning, size: 18),
                                label: Text(_processingIds.contains(complaint.complaintId) ? 'Processing...' : 'Mark Fake'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.purple,
                                  side: const BorderSide(color: Colors.purple),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                  context,
                                  '/complaint-routing',
                                  arguments: {'complaintId': complaint.complaintId},
                                );
                              },
                              icon: const Icon(Icons.assignment),
                              label: const Text('Assign'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BUILD
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All Complaints',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadComplaints,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
        children: [
          // Summary alert bar
          if (_noZoneCount > 0 || _pendingApprovalCount > 0 || _fakeCount > 0)
            _buildSummaryBar(),

          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search complaints...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final isNoZone = filter == 'No Zone';
                  final isFake = filter == 'Fake';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        isNoZone && _noZoneCount > 0
                            ? 'No Zone ($_noZoneCount)'
                            : isFake && _fakeCount > 0
                            ? 'Fake ($_fakeCount)'
                            : filter,
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      backgroundColor: isFake
                          ? Colors.purple[50]
                          : isNoZone
                          ? Colors.amber[50]
                          : Colors.grey[100],
                      selectedColor: isFake
                          ? Colors.purple[100]
                          : isNoZone
                          ? Colors.amber[100]
                          : Colors.blue[100],
                      checkmarkColor: isFake ? Colors.purple[800] : isNoZone ? Colors.amber[800] : Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isFake ? Colors.purple[800] : isNoZone ? Colors.amber[800] : Colors.blue)
                            : (isFake ? Colors.purple[700] : isNoZone ? Colors.amber[700] : Colors.grey[800]),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Sort bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredAndSortedComplaints.length} of ${_complaints.length} complaints',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    DropdownButton<String>(
                      value: _selectedSort,
                      items: _sortOptions
                          .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSort = v);
                      },
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filteredAndSortedComplaints.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadComplaints,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredAndSortedComplaints.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(_filteredAndSortedComplaints[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SUMMARY ALERT BAR
  // =====================================================
  Widget _buildSummaryBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_pendingApprovalCount > 0) ...[
              _buildSummaryChip(
                icon: Icons.pending_actions,
                label: '$_pendingApprovalCount pending approval',
                color: Colors.blue,
                onTap: () => setState(() => _selectedFilter = 'Submitted'),
              ),
              const SizedBox(width: 8),
            ],
            if (_noZoneCount > 0)
              _buildSummaryChip(
                icon: Icons.location_off,
                label: '$_noZoneCount without zone',
                color: Colors.amber[700]!,
                onTap: () => setState(() => _selectedFilter = 'No Zone'),
              ),
            if (_fakeCount > 0)
              _buildSummaryChip(
                icon: Icons.warning,
                label: '$_fakeCount fake complaints',
                color: Colors.purple,
                onTap: () => setState(() => _selectedFilter = 'Fake'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // COMPLAINT CARD
  // =====================================================
  Widget _buildComplaintCard(Complaint complaint) {
    final hasZone = _hasZone(complaint);
    final isFake = complaint.isFake == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFake
            ? BorderSide(color: Colors.purple.shade300, width: 2)
            : hasZone
            ? BorderSide.none
            : BorderSide(color: Colors.amber.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () => _showComplaintDetails(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isFake)
                          Icon(Icons.warning, size: 14, color: Colors.purple),
                        if (isFake) const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(complaint.currentStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFake)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FAKE',
                        style: TextStyle(fontSize: 9, color: Colors.purple[800], fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint.currentStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(complaint.currentStatus),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(complaint.currentStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Chips row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildChip(
                    complaint.priority,
                    _getPriorityColor(complaint.priority).withOpacity(0.12),
                    _getPriorityColor(complaint.priority),
                  ),
                  _buildChip(
                    complaint.categoryName ?? 'No Category',
                    Colors.grey[200]!,
                    Colors.grey[700]!,
                  ),
                  _buildChip(
                    hasZone ? complaint.zoneName! : '⚠ No Zone',
                    isFake ? Colors.purple[50]! : (hasZone ? Colors.blue[50]! : Colors.amber[50]!),
                    isFake ? Colors.purple[700]! : (hasZone ? Colors.blue[700]! : Colors.amber[800]!),
                  ),
                  Text(
                    complaint.complaintNumber ?? 'No #',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // No-zone warning banner
              if (!hasZone && !isFake) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, size: 13, color: Colors.amber[800]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No zone assigned — won\'t appear on map',
                          style: TextStyle(fontSize: 11, color: Colors.amber[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Fake banner on card
              if (isFake) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 13, color: Colors.purple),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Marked as FAKE complaint',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Stats row
              Row(
                children: [
                  Icon(Icons.thumb_up, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${complaint.upvoteCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 14),
                  Icon(Icons.remove_red_eye, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${complaint.viewCount}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 14),
                  Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(_formatDate(complaint.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),

              // Assigned banner
              if (complaint.assignedToId != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 13, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          complaint.assignedToName ?? 'Assigned to staff member',
                          style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
    );
  }

  // =====================================================
  // EMPTY / ERROR STATES
  // =====================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No complaints found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text('Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading complaints',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 8),
            Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadComplaints,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FILTER DIALOG
  // =====================================================
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Complaints'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('By Status',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _filterOptions.map((filter) {
                final isNoZone = filter == 'No Zone';
                final isFake = filter == 'Fake';
                return ChoiceChip(
                  label: Text(
                    isNoZone && _noZoneCount > 0
                        ? 'No Zone ($_noZoneCount)'
                        : isFake && _fakeCount > 0
                        ? 'Fake ($_fakeCount)'
                        : filter,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: _selectedFilter == filter,
                  selectedColor: isFake ? Colors.purple[100] : (isNoZone ? Colors.amber[100] : Colors.blue[100]),
                  onSelected: (_) {
                    setState(() => _selectedFilter = filter);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedFilter = 'All');
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}