import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';
import '../../services/staff_service.dart';
import '../../models/complaint_model.dart';
import '../../models/staff_profile_model.dart';
import '../../services/AuthService.dart';

class ComplaintRoutingScreen extends StatefulWidget {
  const ComplaintRoutingScreen({super.key});

  @override
  State<ComplaintRoutingScreen> createState() => _ComplaintRoutingScreenState();
}

class _ComplaintRoutingScreenState extends State<ComplaintRoutingScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final StaffService _staffService = StaffService();
  final AuthService _authService = AuthService();

  List<Complaint> _allComplaints = [];
  List<StaffProfile> _allStaff = [];
  List<StaffProfile> _filteredStaff = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  String? _userDepartmentId;
  String? _userDepartmentName;

  StaffProfile? _selectedStaff;
  Complaint? _selectedComplaint;

  // Changed default to 'Unassigned'
  String _selectedFilter = 'Unassigned';
  final List<String> _filterOptions = ['Unassigned', 'Approved', 'All', 'Assigned'];

  @override
  void initState() {
    super.initState();
    _checkUserRoleAndLoadData();
  }

  Future<void> _checkUserRoleAndLoadData() async {
    final userType = await _authService.getUserType();
    final departmentId = await _authService.getDepartmentId();
    final departmentName = await _authService.getDepartmentName();

    setState(() {
      _userRole = userType;
      _userDepartmentId = departmentId;
      _userDepartmentName = departmentName;
    });

    print('📡 User Role: $_userRole');
    print('📡 Department ID: $_userDepartmentId');
    print('📡 Department Name: $_userDepartmentName');

    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Complaint> complaints = [];
      List<StaffProfile> staff = [];

      if (_userRole == 'System_Admin') {
        print('📡 System Admin - Loading ALL complaints and staff');
        final results = await Future.wait([
          _assignmentService.getAllComplaintsForRouting(),
          _staffService.getAvailableStaff(),
        ]);
        complaints = results[0] as List<Complaint>;
        staff = results[1] as List<StaffProfile>;
      } else if (_userRole == 'Department_Admin') {
        if (_userDepartmentId == null) {
          throw Exception('Department Admin has no department assigned');
        }
        print('📡 Department Admin - Loading complaints and staff for: $_userDepartmentName');
        final results = await Future.wait([
          _assignmentService.getComplaints(departmentId: _userDepartmentId),
          _staffService.getAvailableStaff(_userDepartmentId),
        ]);
        complaints = results[0] as List<Complaint>;
        staff = results[1] as List<StaffProfile>;
      } else {
        throw Exception('Unauthorized to access complaint routing');
      }

      // Filter: only show Field_Staff in the staff list
      final fieldStaffOnly = staff.where((s) => s.role == 'Field_Staff').toList();

      print('✅ Loaded ${complaints.length} complaints');
      print('✅ Loaded ${fieldStaffOnly.length} field staff (filtered from ${staff.length} total)');

      if (mounted) {
        setState(() {
          _allComplaints = complaints;
          _allStaff = fieldStaffOnly;
          _filteredStaff = [];
          _selectedComplaint = null;
          _selectedStaff = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Updated: Only show unassigned complaints for relevant filters
  List<Complaint> get _filteredComplaints {
    switch (_selectedFilter) {
      case 'Unassigned':
        return _allComplaints.where((c) => c.assignedToId == null).toList();
      case 'Assigned':
        return _allComplaints.where((c) => c.assignedToId != null).toList();
      case 'Approved':
        return _allComplaints
            .where((c) => c.currentStatus == 2 && c.assignedToId == null)
            .toList();
      default: // 'All'
        return _allComplaints.where((c) => c.assignedToId == null).toList();
    }
  }

  void _onComplaintSelected(Complaint complaint) {
    setState(() {
      _selectedComplaint = complaint;
      _selectedStaff = null;

      _filteredStaff = _allStaff.where((staff) {
        final complaintDeptName = complaint.departmentName?.toString().toLowerCase().trim() ?? '';
        final staffDeptName = staff.departmentName?.toString().toLowerCase().trim() ?? '';
        return complaintDeptName == staffDeptName;
      }).toList();
    });

    print('📋 Selected complaint department: ${complaint.departmentName}');
    print('📋 Available staff in this department: ${_filteredStaff.length}');

    if (_filteredStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Field Staff available in ${complaint.departmentName ?? "this"} department'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _assignComplaint() async {
    if (_selectedComplaint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complaint first'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: Colors.red),
      );
      return;
    }

    final complaintDeptName = _selectedComplaint!.departmentName?.toString().toLowerCase().trim() ?? '';
    final staffDeptName = _selectedStaff!.departmentName?.toString().toLowerCase().trim() ?? '';

    if (complaintDeptName != staffDeptName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Department mismatch: ${_selectedComplaint!.departmentName} vs ${_selectedStaff!.departmentName}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = await _authService.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Complaint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign "${_selectedComplaint!.title}" to ${_selectedStaff!.fullName ?? 'Unknown'}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Details:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Complaint: ${_selectedComplaint!.complaintNumber ?? 'N/A'}'),
                  Text('Category: ${_selectedComplaint!.categoryName ?? 'General'}'),
                  Text('Zone: ${_selectedComplaint!.zoneName ?? 'Unknown'}'),
                  Text('Status: ${_getStatusText(_selectedComplaint!.currentStatus)}'),
                  Text('Priority: ${_selectedComplaint!.priority}'),
                  const SizedBox(height: 8),
                  Text('Staff: ${_selectedStaff!.fullName ?? 'Unknown'}'),
                  Text('Department: ${_selectedStaff!.departmentName ?? 'N/A'}'),
                  Text('Pending Tasks: ${_selectedStaff!.pendingAssignments}'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Save names BEFORE clearing state
    final assignedStaffName = _selectedStaff!.fullName ?? 'staff member';
    final assignedComplaintTitle = _selectedComplaint!.title;

    try {
      setState(() => _isLoading = true);

      await _assignmentService.assignComplaintToStaff(
        complaintId: _selectedComplaint!.complaintId,
        staffId: _selectedStaff!.staffId,
        assignedById: userId,
        notes: 'Assigned by ${_userRole == 'System_Admin' ? 'System Admin' : 'Department Admin'}',
      );

      if (!mounted) return;

      // Clear selection BEFORE reload
      setState(() {
        _selectedComplaint = null;
        _selectedStaff = null;
        _filteredStaff = [];
      });

      // Reload fresh data — assigned complaint won't come back
      await _loadData();

      if (!mounted) return;

      // Use saved names (state already cleared)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$assignedComplaintTitle" assigned to $assignedStaffName successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectComplaint(Complaint complaint) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Complaint'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Enter reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        await _assignmentService.rejectComplaint(complaint.complaintId, reason);
        if (!mounted) return;

        setState(() {
          _selectedComplaint = null;
          _selectedStaff = null;
          _filteredStaff = [];
        });

        await _loadData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint rejected successfully'), backgroundColor: Colors.red),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
      case 6: return 'Closed';
      case 7: return 'Rejected';
      default: return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.lightBlue;
      case 3: return Colors.purple;
      case 4: return Colors.indigo;
      case 5: return Colors.green;
      case 6: return Colors.grey;
      case 7: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getDepartmentColor(String? departmentName) {
    switch (departmentName?.toLowerCase()) {
      case 'sanitation':
      case 'rwmc - waste management':
        return Colors.green;
      case 'water & sewerage':
      case 'wasa - water & sewerage':
        return Colors.blue;
      case 'electricity':
      case 'wapda - electricity':
        return Colors.amber;
      case 'civic services':
      case 'cda - civic services':
        return Colors.orange;
      case 'parks & recreation':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            _userRole == 'System_Admin'
                ? 'Complaint Routing (All Departments)'
                : 'Complaint Routing - $_userDepartmentName',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Complaint Routing', style: TextStyle(color: Colors.grey[900])),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text(_errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredComplaints = _filteredComplaints;
    final hasSelectedComplaint = _selectedComplaint != null;
    final hasMatchingStaff = _filteredStaff.isNotEmpty;

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
          _userRole == 'System_Admin'
              ? 'Complaint Routing (All Departments)'
              : 'Complaint Routing - $_userDepartmentName',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          if (_userRole == 'Department_Admin')
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Dept: ${_userDepartmentName ?? "Unknown"}',
                style: TextStyle(fontSize: 12, color: Colors.green[700]),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                items: _filterOptions.map((filter) {
                  return DropdownMenuItem(value: filter, child: Text(filter));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFilter = value;
                      _selectedComplaint = null;
                      _selectedStaff = null;
                      _filteredStaff = [];
                    });
                  }
                },
                icon: const Icon(Icons.filter_list, size: 18),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row - Updated to show accurate counts
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildRoutingStat('${_allComplaints.length}', 'Total')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoutingStat(
                    '${_allComplaints.where((c) => c.assignedToId == null).length}',
                    'Unassigned',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildRoutingStat('${_allStaff.length}', 'Field Staff')),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Showing: $_selectedFilter (${filteredComplaints.length})',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_allComplaints.length} total complaints',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      // Complaints Panel
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_selectedFilter Complaints',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Tap a complaint to see matching staff',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 16),
                              Expanded(
                                child: filteredComplaints.isEmpty
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('No unassigned complaints available',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                                    : ListView.builder(
                                  itemCount: filteredComplaints.length,
                                  itemBuilder: (context, index) =>
                                      _buildComplaintCard(filteredComplaints[index]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Container(width: 1, color: Colors.grey[300]),

                      // Staff Panel
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Field Staff',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                hasSelectedComplaint
                                    ? 'Staff in ${_selectedComplaint!.departmentName ?? "matching"} department'
                                    : 'Select a complaint to see available staff',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: !hasSelectedComplaint
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Select a complaint first',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                                    : !hasMatchingStaff
                                    ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline,
                                          size: 48, color: Colors.orange[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Field Staff available in\n${_selectedComplaint!.departmentName ?? "this"} department',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                                      ),
                                    ],
                                  ),
                                )
                                    : ListView.builder(
                                  itemCount: _filteredStaff.length,
                                  itemBuilder: (context, index) =>
                                      _buildStaffCard(_filteredStaff[index]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_selectedFilter Complaints',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (filteredComplaints.isEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('No unassigned complaints available',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                              else
                                ...filteredComplaints.map((c) => _buildComplaintCard(c)),
                            ],
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Field Staff',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                hasSelectedComplaint
                                    ? 'Staff in ${_selectedComplaint!.departmentName ?? "matching"} department'
                                    : 'Select a complaint first',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              if (!hasSelectedComplaint)
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Select a complaint first',
                                          style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                )
                              else if (!hasMatchingStaff)
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.people_outline, size: 48, color: Colors.orange[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Field Staff available in\n${_selectedComplaint!.departmentName ?? "this"} department',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.orange[700]),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._filteredStaff.map((s) => _buildStaffCard(s)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedComplaint == null
                            ? 'No complaint selected'
                            : _selectedComplaint!.title,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedStaff == null
                            ? 'No staff selected'
                            : _selectedStaff!.fullName ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _selectedComplaint == null
                      ? null
                      : () => _rejectComplaint(_selectedComplaint!),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedComplaint != null && _selectedStaff != null
                      ? _assignComplaint
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Assign Complaint'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutingStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final isSelected = _selectedComplaint?.complaintId == complaint.complaintId;
    final priorityColor = complaint.priority == 'High'
        ? Colors.red
        : complaint.priority == 'Medium'
        ? Colors.orange
        : Colors.green;
    final statusColor = _getStatusColor(complaint.currentStatus);
    final departmentColor = _getDepartmentColor(complaint.departmentName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => _onComplaintSelected(complaint),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(complaint.priority,
                        style: TextStyle(
                            fontSize: 10,
                            color: priorityColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: departmentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(complaint.departmentName ?? 'No Dept',
                        style: TextStyle(
                            fontSize: 10,
                            color: departmentColor,
                            fontWeight: FontWeight.w500)),
                  ),
                  Text(_getStatusText(complaint.currentStatus),
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: Text(complaint.categoryName ?? 'General',
                        style: const TextStyle(fontSize: 10)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                    child: Text(complaint.zoneName ?? 'Unknown',
                        style: TextStyle(fontSize: 10, color: Colors.blue[700])),
                  ),
                  Text(complaint.complaintNumber ?? 'N/A',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(complaint.locationAddress,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                  Icon(Icons.thumb_up, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${complaint.upvoteCount}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffProfile staff) {
    final isSelected = _selectedStaff?.staffId == staff.staffId;
    final isAvailable = staff.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: isAvailable ? () => setState(() => _selectedStaff = staff) : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.blue[100], shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: _getDepartmentColor(staff.departmentName).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(staff.departmentName ?? 'No Dept',
                            style: TextStyle(
                                fontSize: 10,
                                color: _getDepartmentColor(staff.departmentName),
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.assignment, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text('${staff.pendingAssignments} tasks',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${staff.performanceScore.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    isAvailable ? 'Available' : 'Busy',
                    style: TextStyle(
                        fontSize: 10,
                        color: isAvailable ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}