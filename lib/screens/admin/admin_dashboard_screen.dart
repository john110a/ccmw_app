// lib/admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import '../../services/AuthService.dart';
import '../../services/dashboard_service.dart';
import '../../services/duplicate_service.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final DuplicateService _duplicateService = DuplicateService();

  // Dashboard data
  Map<String, dynamic> _dashboardData = {};

  // User data from SharedPreferences
  String? _adminName;
  String? _adminEmail;
  String? _lastLogin;

  // Statistics
  int _totalUsers = 0;
  int _totalCitizens = 0;
  int _totalStaff = 0;
  int _totalContractors = 0;
  int _totalComplaints = 0;
  int _resolvedComplaints = 0;
  int _activeComplaints = 0;
  int _pendingApprovals = 0;
  int _overdueComplaints = 0;
  int _totalDepartments = 0;
  int _totalZones = 0;
  double _avgResponseTime = 0.0;

  // Lists for top performers
  List<dynamic> _topDepartments = [];
  List<dynamic> _topZones = [];
  List<dynamic> _topContractors = [];

  // UI State
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadAdminDashboard();
    _loadUserData();
  }

  Future<void> _checkAdminAccess() async {
    final userType = await _authService.getUserType();
    if (userType != 'System_Admin' && userType != 'Department_Admin' && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getAllUserData();
    setState(() {
      _adminName = userData['userName'] ?? 'System Administrator';
      _adminEmail = userData['userEmail'] ?? 'admin@ccmw.gov.pk';
      _lastLogin = userData['lastLogin'] != null
          ? _formatLastLogin(DateTime.parse(userData['lastLogin']))
          : 'Today, 9:30 AM';
    });
  }

  String _formatLastLogin(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _loadAdminDashboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await _dashboardService.getAdminDashboard();

      setState(() {
        _dashboardData = data;

        final stats = data['Statistics'] ?? {};
        _totalUsers = stats['TotalUsers'] ?? 0;
        _totalCitizens = stats['TotalCitizens'] ?? 0;
        _totalStaff = stats['TotalStaff'] ?? 0;
        _totalContractors = stats['TotalContractors'] ?? 0;
        _totalComplaints = stats['TotalComplaints'] ?? 0;
        _resolvedComplaints = stats['ResolvedComplaints'] ?? 0;
        _activeComplaints = stats['ActiveComplaints'] ?? 0;
        _pendingApprovals = stats['PendingApprovals'] ?? 0;
        _overdueComplaints = stats['OverdueComplaints'] ?? 0;
        _totalDepartments = stats['TotalDepartments'] ?? 0;
        _totalZones = stats['TotalZones'] ?? 0;
        _avgResponseTime = (stats['AverageResponseTime'] ?? 0.0).toDouble();

        _topDepartments = data['TopDepartments'] ?? [];
        _topZones = data['TopZones'] ?? [];
        _topContractors = data['TopContractors'] ?? [];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading admin dashboard...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 50, color: Colors.red),
                ),
                const SizedBox(height: 24),
                Text(
                  'Failed to load dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAdminDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.grey),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.grey),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadAdminDashboard,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _showLogoutDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadAdminDashboard,
        color: Colors.purple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Stats Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _adminName ?? 'System Administrator',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _adminEmail ?? '',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Last login: $_lastLogin',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Online',
                                style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double cardWidth = (constraints.maxWidth - 36) / 4;
                        double cardHeight = cardWidth * 0.9;

                        return SizedBox(
                          height: cardHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCompactStatCard('$_totalComplaints', 'Total', Icons.report, Colors.blue, cardWidth),
                              _buildCompactStatCard('$_resolvedComplaints', 'Resolved', Icons.check_circle, Colors.green, cardWidth),
                              _buildCompactStatCard('$_pendingApprovals', 'Pending', Icons.pending, Colors.orange, cardWidth),
                              _buildCompactStatCard('$_overdueComplaints', 'Overdue', Icons.warning, Colors.red, cardWidth),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // QUICK ACTIONS - COMPACT GRID (ONLY RELEVANT ADMIN BUTTONS)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isSmallScreen ? 3 : 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                      children: [
                        // Complaint Management
                        _buildCompactActionCard(Icons.list_alt, 'All\nComplaints', '/admin-complaints', Colors.amber),
                        _buildCompactActionCard(Icons.approval, 'Approve\nComplaints', '/complaint-approval', Colors.green),
                        _buildCompactActionCard(Icons.assignment, 'Route\nComplaints', '/complaint-routing', Colors.blue),

                        // Duplicate Management
                        _buildCompactActionCard(Icons.search, 'Detect\nDuplicates', '/detect-duplicates', Colors.deepPurple),
                        _buildCompactActionCard(Icons.merge_type, 'Merge\nDuplicates', '/merge-duplicates', Colors.purple),
                        _buildCompactActionCard(Icons.notifications, 'Duplicate\nAlerts', '/duplicate-notifications', Colors.pink),

                        // Resolution & Verification
                        _buildCompactActionCard(Icons.verified, 'Verify\nResolutions', '/resolution-detection', Colors.green),

                        // Zone Management
                        _buildCompactActionCard(Icons.location_city, 'Zones', '/zone-management', Colors.teal),

                        // Escalation
                        _buildCompactActionCard(Icons.timeline, 'Escalate', '/escalation-workflow', Colors.red),

                        // Department & Staff
                        _buildCompactActionCard(Icons.business, 'Dept\nDashboard', '/department-dashboard', Colors.indigo),
                        _buildCompactActionCard(Icons.people, 'Staff\nManagement', '/staff-management', Colors.blueGrey),

                        // Contractor Management
                        _buildCompactActionCard(Icons.business_center, 'Contractors', '/privatization-management', Colors.orange),

                        // User Management
                        _buildCompactActionCard(Icons.people_outline, 'Users', '/user-management', Colors.lightBlue),

                        // Reports & Settings
                        _buildCompactActionCard(Icons.report, 'Reports', '/reports', Colors.blue),
                        _buildCompactActionCard(Icons.settings, 'Settings', '/system-settings', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== AUTO-DETECTED DUPLICATES WIDGET =====
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 24),
                  ),
                  title: const Text(
                    'Auto-Detected Duplicates',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: FutureBuilder<int>(
                    future: _duplicateService.getPendingClusterCount(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }
                      return Text(
                        '${snapshot.data} clusters ready for review',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      );
                    },
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/merge-duplicates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                ),
              ),

              // System Health
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Health',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildCompactHealthRow('Response Time', '${_avgResponseTime.toStringAsFixed(1)}h', Icons.access_time, Colors.blue),
                            const SizedBox(height: 12),
                            _buildCompactHealthRow('Active Users', '$_totalUsers', Icons.people, Colors.green),
                            const SizedBox(height: 12),
                            _buildCompactHealthRow('Active Complaints', '$_activeComplaints', Icons.warning, Colors.orange),
                            const SizedBox(height: 12),
                            _buildCompactHealthRow('Staff', '$_totalStaff', Icons.business, Colors.purple),
                            const SizedBox(height: 12),
                            _buildCompactHealthRow('Pending Approvals', '$_pendingApprovals', Icons.hourglass_empty, Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Activity
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildCompactActivityItem(
                      icon: Icons.business_center,
                      title: 'Contractor assigned to Zone 2',
                      subtitle: '30 min ago',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactActivityItem(
                      icon: Icons.person_add,
                      title: 'New department admin added',
                      subtitle: '2h ago',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactActivityItem(
                      icon: Icons.warning,
                      title: 'System maintenance scheduled',
                      subtitle: '4h ago',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildCompactActivityItem(
                      icon: Icons.assignment,
                      title: 'Complaint assigned to staff',
                      subtitle: '5h ago',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text(
                      '© 2024 CCMW - Complaint Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard, 'Home', Colors.purple, () {}),
            _buildNavItem(Icons.people, 'Users', Colors.grey, () {
              Navigator.pushNamed(context, '/user-management');
            }),
            _buildNavItem(Icons.business_center, 'Contract', Colors.orange, () {
              Navigator.pushNamed(context, '/privatization-management');
            }),
            _buildNavItem(Icons.report, 'Reports', Colors.grey, () {
              Navigator.pushNamed(context, '/reports');
            }),
            _buildNavItem(Icons.approval, 'Approve', Colors.green, () {
              Navigator.pushNamed(context, '/complaint-approval');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color == Colors.purple ? Colors.purple : Colors.grey),
          ),
        ],
      ),
    );
  }

  // COMPACT STAT CARD
  Widget _buildCompactStatCard(String value, String label, IconData icon, Color color, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // COMPACT ACTION CARD
  Widget _buildCompactActionCard(IconData icon, String label, String route, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // COMPACT HEALTH ROW
  Widget _buildCompactHealthRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // COMPACT ACTIVITY ITEM
  Widget _buildCompactActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}