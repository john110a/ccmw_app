import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/staff_action_service.dart';
import '../../models/staff_profile_model.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final AuthService _authService = AuthService();
  final StaffActionService _staffActionService = StaffActionService();

  bool _isLoading = true;
  String? _errorMessage;

  // Staff data
  String? _staffName;
  String? _staffId;
  String? _employeeId;
  String? _departmentName;
  String? _zoneName;
  String? _role;
  String? _email;
  String? _phoneNumber;
  DateTime? _hireDate;
  double? _performanceScore;
  int _totalAssignments = 0;
  int _completedAssignments = 0;
  int _pendingAssignments = 0;

  @override
  void initState() {
    super.initState();
    _loadStaffProfile();
  }

  Future<void> _loadStaffProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get staff ID from AuthService
      _staffId = await _authService.getStaffId();

      if (_staffId == null) {
        throw Exception('Staff ID not found. Please contact administrator.');
      }

      print('📡 Loading profile for Staff ID: $_staffId');

      // Get staff dashboard data which includes staff info
      final dashboardData = await _staffActionService.getStaffDashboard(_staffId!);

      // Extract staff info from dashboard response
      final staff = dashboardData['Staff'] ?? {};
      final stats = dashboardData['Statistics'] ?? {};

      _staffName = staff['FullName'] ?? await _authService.getUserName() ?? 'Staff Member';
      _employeeId = staff['EmployeeId'] ?? _staffId?.substring(0, 8);
      _departmentName = staff['DepartmentName'] ?? await _authService.getDepartmentName() ?? 'Not Assigned';
      _role = staff['Role'] ?? 'Field Staff';
      _email = staff['Email'] ?? await _authService.getUserEmail() ?? 'No email';
      _phoneNumber = staff['PhoneNumber'] ?? await _authService.getUserPhone() ?? 'No phone';

      // Get performance data
      final performanceData = await _staffActionService.getStaffPerformance(_staffId!);
      final performance = performanceData['Performance'] ?? {};

      _performanceScore = (performance['PerformanceScore'] ?? 0.0).toDouble();
      _totalAssignments = performance['TotalAssignments'] ?? 0;
      _completedAssignments = performance['CompletedAssignments'] ?? 0;
      _pendingAssignments = performance['PendingAssignments'] ?? 0;

      // Get zone from first active assignment or from staff data
      final activeAssignments = dashboardData['ActiveAssignments'] ?? [];
      if (activeAssignments.isNotEmpty) {
        final firstAssignment = activeAssignments.first;
        _zoneName = firstAssignment['ZoneName'] ??
            firstAssignment['Zone']?['ZoneName'] ??
            'Unknown Zone';
      } else {
        _zoneName = 'No Zone Assigned';
      }

      // Try to get hire date from staff profile (you may need to add this endpoint)
      // For now, we'll use a placeholder or fetch from user data
      _hireDate = DateTime.now().subtract(const Duration(days: 365)); // Placeholder

      print('✅ Profile loaded: $_staffName, Dept: $_departmentName');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading staff profile: $e');
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Profile',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Profile',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStaffProfile,
                child: const Text('Retry'),
              ),
            ],
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
          'My Profile',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadStaffProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with Avatar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue[300]!, width: 3),
                    ),
                    child: Icon(
                      Icons.engineering,
                      size: 50,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _staffName ?? 'Staff Member',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _role ?? 'Field Staff',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_employeeId != null)
                    Text(
                      'ID: $_employeeId',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Contact Information Section
            Container(
              margin: const EdgeInsets.all(16),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.email, color: Colors.grey[600]),
                    title: const Text('Email'),
                    subtitle: Text(_email ?? 'No email'),
                    trailing: IconButton(
                      icon: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
                      onPressed: () {
                        // Copy to clipboard
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.grey[600]),
                    title: const Text('Phone'),
                    subtitle: Text(_phoneNumber ?? 'No phone'),
                    trailing: IconButton(
                      icon: Icon(Icons.call, size: 18, color: Colors.grey[400]),
                      onPressed: () {
                        // Make phone call
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Work Information Section
            Container(
              margin: const EdgeInsets.all(16),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Work Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.business, color: Colors.grey[600]),
                    title: const Text('Department'),
                    subtitle: Text(_departmentName ?? 'Not Assigned'),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.grey[600]),
                    title: const Text('Zone'),
                    subtitle: Text(_zoneName ?? 'Not Assigned'),
                  ),
                  if (_hireDate != null)
                    ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.grey[600]),
                      title: const Text('Hire Date'),
                      subtitle: Text('${_hireDate!.day}/${_hireDate!.month}/${_hireDate!.year}'),
                    ),
                ],
              ),
            ),

            // Performance Statistics Section
            Container(
              margin: const EdgeInsets.all(16),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Performance Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('$_totalAssignments', 'Total Tasks', Colors.blue),
                        _buildStatColumn('$_completedAssignments', 'Completed', Colors.green),
                        _buildStatColumn('$_pendingAssignments', 'Pending', Colors.orange),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Performance Score'),
                            Text(
                              '${_performanceScore?.toStringAsFixed(1) ?? "0"}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getPerformanceColor(_performanceScore ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_performanceScore ?? 0) / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getPerformanceColor(_performanceScore ?? 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Completion Rate'),
                            Text(
                              '${_totalAssignments > 0 ? (_completedAssignments * 100 ~/ _totalAssignments) : 0}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _totalAssignments > 0 ? _completedAssignments / _totalAssignments : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

  Color _getPerformanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}