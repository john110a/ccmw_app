// lib/screens/admin/department_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/dashboard_service.dart';
import '../../services/department_service.dart'; // ADD THIS IMPORT
import '../../models/department_model.dart';
import '../../models/staff_profile_model.dart';

class DepartmentDashboardScreen extends StatefulWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  State<DepartmentDashboardScreen> createState() => _DepartmentDashboardScreenState();
}

class _DepartmentDashboardScreenState extends State<DepartmentDashboardScreen> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final DepartmentService _departmentService = DepartmentService(); // ADD THIS

  // Data variables
  Department? _department;
  List<StaffProfile> _topStaff = [];
  List<Map<String, dynamic>> _recentComplaints = [];

  // UI State
  bool _isLoading = true;
  String? _errorMessage;

  // Statistics
  int _totalComplaints = 0;
  int _activeComplaints = 0;
  int _pendingApprovals = 0;
  int _resolvedThisMonth = 0;
  double _performanceScore = 0.0;
  double _avgResolutionTime = 0.0;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadDepartmentDashboard();
  }

  Future<void> _checkAccess() async {
    final isStaff = await _authService.isStaff();
    final userType = await _authService.getUserType();

    print('📡 DepartmentDashboard - UserType: $userType, isStaff: $isStaff');

    // Allow System_Admin to access department dashboard
    if (userType == 'System_Admin') {
      print('✅ System Admin accessing department dashboard');
      return;
    }

    // For other users, check if they have access
    if (!isStaff && userType != 'Department_Admin' && mounted) {
      print('❌ Access denied - redirecting to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadDepartmentDashboard() async {
    setState(() => _isLoading = true);

    try {
      final userType = await _authService.getUserType();
      String? departmentId;

      // FIXED: Handle System Admin properly
      if (userType == 'System_Admin') {
        print('✅ System Admin - fetching first available department');

        // Get all departments and use the first one
        final departments = await _departmentService.getAllDepartments();
        if (departments.isNotEmpty) {
          departmentId = departments.first.departmentId;
          print('📌 Using department: ${departments.first.departmentName} (${departments.first.departmentId})');
        } else {
          throw Exception('No departments found in the system');
        }
      } else {
        // For department admin, get their department ID
        departmentId = await _authService.getDepartmentId();
        if (departmentId == null) {
          throw Exception('Department ID not found. Please ensure you are assigned to a department.');
        }
        print('📌 Department Admin - Department ID: $departmentId');
      }

      print('📡 Fetching dashboard data for department: $departmentId');
      final data = await _dashboardService.getDepartmentDashboard(departmentId);
      print('✅ Dashboard data received');

      setState(() {
        // Extract department info
        final deptData = data['Department'] ?? {};
        _department = Department.fromJson(deptData);

        // Extract statistics
        final stats = data['Statistics'] ?? {};
        _totalComplaints = stats['TotalComplaints'] ?? 0;
        _activeComplaints = stats['ActiveComplaints'] ?? 0;
        _pendingApprovals = stats['PendingApprovals'] ?? 0;
        _resolvedThisMonth = stats['ResolvedThisMonth'] ?? 0;
        _performanceScore = (stats['PerformanceScore'] ?? 0.0).toDouble();
        _avgResolutionTime = (stats['AverageResolutionTimeDays'] ?? 0.0).toDouble();

        // Extract top staff
        final staffList = data['TopStaff'] as List? ?? [];
        _topStaff = staffList.map((s) => StaffProfile.fromJson(s)).toList();

        // Extract recent complaints
        final complaints = data['RecentComplaints'] as List? ?? [];
        _recentComplaints = complaints.map((c) => Map<String, dynamic>.from(c)).toList();

        _isLoading = false;
      });

      print('📊 Stats loaded - Total: $_totalComplaints, Active: $_activeComplaints');
    } catch (e) {
      print('❌ Error loading department dashboard: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
            'Department Dashboard',
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
          title: Text(
            'Department Dashboard',
            style: TextStyle(color: Colors.grey[900]),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadDepartmentDashboard,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDepartmentDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          'Department Dashboard',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.grey),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadDepartmentDashboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Department Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cleaning_services,
                          size: 32,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _department?.departmentName ?? 'Department',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Performance Score: ${_performanceScore.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Overview
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        '$_totalComplaints',
                        'Total',
                        Icons.report,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        '$_activeComplaints',
                        'Active',
                        Icons.pending,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        '$_pendingApprovals',
                        'Pending Approval',
                        Icons.hourglass_empty,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        '$_resolvedThisMonth',
                        'Resolved (Month)',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.assignment_turned_in,
                          label: 'Assign\nComplaints',
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(context, '/complaint-routing'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickActionButton(
                          icon: Icons.verified,
                          label: 'Verify\nResolutions',
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/resolution-detection'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickActionButton(
                          icon: Icons.merge_type,
                          label: 'Merge\nDuplicates',
                          color: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, '/merge-duplicates'),
                        ),
                        const SizedBox(width: 12),
                        _buildQuickActionButton(
                          icon: Icons.people,
                          label: 'Staff\nManagement',
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(context, '/staff-management'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent Complaints
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Complaints',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ..._recentComplaints.map((complaint) => _buildComplaintItem(complaint)),
                  if (_recentComplaints.isEmpty)
                    const Center(child: Text('No recent complaints')),
                ],
              ),
            ),

            // Staff Performance
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Performing Staff',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  ..._topStaff.map((staff) => _buildStaffPerformanceItem(staff)),
                  if (_topStaff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No staff data available')),
                    ),
                ],
              ),
            ),

            // Department Metrics
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Department Metrics',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Avg. Resolution Time',
                              '${_avgResolutionTime.toStringAsFixed(1)} days',
                              Icons.access_time,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildMetricItem(
                              'Performance Score',
                              '${_performanceScore.toStringAsFixed(1)}%',
                              Icons.trending_up,
                              _performanceScore >= 80 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... rest of your existing methods remain exactly the same
  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintItem(Map<String, dynamic> complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(complaint['status'] ?? 'Pending'),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['title'] ?? 'No title',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // Category - ✅ UPDATED
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint['categoryName'] ?? complaint['category'] ?? 'General',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    // Zone - ✅ UPDATED
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint['zoneName'] ?? complaint['zone'] ?? 'Unknown',
                        style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                      ),
                    ),
                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (complaint['priority'] == 'High' ? Colors.red[50] : Colors.orange[50]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint['priority'] ?? 'Medium',
                        style: TextStyle(
                          fontSize: 10,
                          color: complaint['priority'] == 'High' ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                complaint['assignedTo'] ?? 'Unassigned',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPerformanceItem(StaffProfile staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName ?? 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    const Icon(Icons.assignment, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${staff.completedAssignments} completed',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${staff.performanceScore.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: staff.isAvailable ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              staff.isAvailable ? 'Available' : 'Busy',
              style: TextStyle(
                fontSize: 10,
                color: staff.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'in progress': return Colors.purple;
      case 'resolved': return Colors.green;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }
}