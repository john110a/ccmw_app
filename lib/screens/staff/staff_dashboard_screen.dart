import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'staff_drawer.dart';
import '../../services/AuthService.dart';
import '../../services/staff_action_service.dart';
import '../../services/locationservice.dart';
import '../../models/staff_profile_model.dart';
import '../../config/routes.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final AuthService _authService = AuthService();
  final StaffActionService _staffActionService = StaffActionService();
  final LocationService _locationService = LocationService();

  // Data variables
  List<dynamic> _assignments = [];
  List<dynamic> _nearbyComplaints = [];
  bool _isLoading = true;
  bool _isUpdatingLocation = false;
  String? _errorMessage;
  Position? _currentPosition;

  // Staff info
  String? _staffName;
  String? _staffId;
  String? _departmentName;
  String? _zoneName;
  String? _role;
  String? _employeeId;
  double? _performanceScore;

  // Statistics
  int _totalAssignments = 0;
  int _completedAssignments = 0;
  int _pendingAssignments = 0;
  int _acceptedAssignments = 0;
  int _inProgressAssignments = 0;
  double _avgResolutionTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStaffDashboard();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });
      await _updateLocation(position.latitude, position.longitude, position.accuracy);
    }
  }

  Future<void> _updateLocation(double lat, double lng, double accuracy) async {
    if (_staffId == null) return;
    setState(() => _isUpdatingLocation = true);
    try {
      await _staffActionService.updateLocation(_staffId!, lat, lng, accuracy);
      await _loadNearbyComplaints();
    } catch (e) {
      print('Location update error: $e');
    } finally {
      if (mounted) setState(() => _isUpdatingLocation = false);
    }
  }

  Future<void> _loadNearbyComplaints() async {
    if (_staffId == null) return;
    try {
      final response = await _staffActionService.getNearbyComplaints(
        _staffId!,                          // 1st: staffId
        _currentPosition!.latitude,         // 2nd: latitude
        _currentPosition!.longitude,        // 3rd: longitude
        2.0,                                // 4th: radius in km
      );
      if (mounted) {
        setState(() {
          _nearbyComplaints = response['Complaints'] ?? [];
        });
      }
    } catch (e) {
      print('Nearby complaints error: $e');
    }
  }

  Future<void> _loadStaffDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Get staff ID from AuthService
      _staffId = await _authService.getStaffId();
      if (_staffId == null) {
        // Try to get from user ID if staff ID not found
        final userId = await _authService.getUserId();
        if (userId != null) {
          // You might need to fetch staff profile by user ID
          print('Staff ID not found, User ID: $userId');
        }
        throw Exception('Staff ID not found. Please contact administrator.');
      }

      print('📡 Loading dashboard for Staff ID: $_staffId');

      // Get staff dashboard data
      final data = await _staffActionService.getMyAssignments(_staffId!);
      print('📦 Dashboard data: $data');

      // Extract staff info from response
      // Your backend returns staff info in the response
      _staffName = data['StaffName'] ??
          data['fullName'] ??
          data['FullName'] ??
          await _authService.getUserName() ??
          'Staff Member';

      _departmentName = data['DepartmentName'] ??
          data['departmentName'] ??
          await _authService.getDepartmentName() ??
          'Not Assigned';

      _role = data['Role'] ?? data['role'] ?? 'Field Staff';
      _employeeId = data['EmployeeId'] ?? data['employeeId'];
      _performanceScore = (data['PerformanceScore'] ?? data['performanceScore'] ?? 0.0).toDouble();

      // Extract statistics from the response
      final stats = data['Statistics'] ?? {};
      _totalAssignments = stats['Total'] ?? stats['totalAssignments'] ?? 0;
      _completedAssignments = stats['Completed'] ?? stats['completedAssignments'] ?? 0;
      _pendingAssignments = stats['Pending'] ?? stats['pendingAssignments'] ?? 0;
      _acceptedAssignments = stats['Accepted'] ?? 0;
      _inProgressAssignments = stats['InProgress'] ?? 0;
      _avgResolutionTime = (stats['AverageResolutionTime'] ?? stats['averageResolutionTime'] ?? 0.0).toDouble();

      // Extract assignments from the response
      _assignments = data['Assignments'] ?? [];

      // Calculate zone name from first assignment or use default
      if (_assignments.isNotEmpty && _zoneName == null) {
        final firstAssignment = _assignments.first;
        _zoneName = firstAssignment['Zone']?['ZoneName'] ??
            firstAssignment['zoneName'] ??
            'Unknown Zone';
      }

      print('✅ Dashboard loaded: $_staffName, Dept: $_departmentName');
      print('📊 Stats - Total: $_totalAssignments, Completed: $_completedAssignments, Pending: $_pendingAssignments');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading staff dashboard: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationManually() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      await _updateLocation(position.latitude, position.longitude, position.accuracy);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get location. Please enable GPS.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToTask(Map<String, dynamic> task) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.taskDetail,
      arguments: {
        'assignmentId': task['assignmentId'],
        'staffId': _staffId,
        'title': task['title'],
        'complaintNumber': task['complaintNumber'],
        'description': task['description'],
        'priority': task['priority'],
        'categoryName': task['categoryName'],
        'zoneName': task['zoneName'],
        'locationAddress': task['locationAddress'],
        'locationLatitude': task['locationLatitude'],
        'locationLongitude': task['locationLongitude'],
        'acceptedAt': task['acceptedAt'],
        'startedAt': task['startedAt'],
        'completedAt': task['completedAt'],
        'status': task['status'],
      },
    );

    if (result == true && mounted) {
      _loadStaffDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading dashboard...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStaffDashboard,
                child: const Text('Retry'),
              ),
            ],
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
        iconTheme: const IconThemeData(color: Colors.grey),
        title: Text(
          'Staff Dashboard',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isUpdatingLocation)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.gps_fixed, color: Colors.green),
              onPressed: _updateLocationManually,
              tooltip: 'Update Location',
            ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.grey),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: const StaffDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadStaffDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ========== PROFILE HEADER ==========
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
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue[300]!, width: 3),
                      ),
                      child: Icon(Icons.engineering, size: 40, color: Colors.blue[700]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _staffName ?? 'Staff Member',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (_employeeId != null)
                            Text(
                              'ID: $_employeeId',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _departmentName ?? 'Department Not Assigned',
                              style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (_zoneName != null)
                            Text(
                              '📍 $_zoneName',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ========== STATS CARDS ==========
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('$_totalAssignments', 'Total Tasks', Icons.assignment, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('$_pendingAssignments', 'Pending', Icons.pending, Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('$_completedAssignments', 'Completed', Icons.check_circle, Colors.green)),
                  ],
                ),
              ),

              // ========== NEARBY COMPLAINTS ==========
              if (_nearbyComplaints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Nearby Complaints (${_nearbyComplaints.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _nearbyComplaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _nearbyComplaints[index];
                            return _buildNearbyCard(complaint);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // ========== MY TASKS ==========
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_pendingAssignments > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_pendingAssignments pending',
                              style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_assignments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No active tasks',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You have no pending assignments',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._assignments.map((assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTaskCard(assignment),
                      )),
                  ],
                ),
              ),

              // ========== QUICK ACTIONS ==========
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildQuickActionCard(Icons.assignment, 'My Tasks', Colors.blue, () => Navigator.pushNamed(context, '/my-tasks'))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildQuickActionCard(Icons.map, 'Task Map', Colors.green, () => Navigator.pushNamed(context, '/staff-map'))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildQuickActionCard(Icons.gps_fixed, 'Update Location', Colors.orange, _updateLocationManually)),
                      ],
                    ),
                  ],
                ),
              ),

              // ========== PERFORMANCE METRICS ==========
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Performance Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCircle(
                            '${_totalAssignments > 0 ? (_completedAssignments * 100 ~/ _totalAssignments) : 0}%',
                            'Completion Rate',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCircle(
                            '${_performanceScore?.toStringAsFixed(0) ?? "0"}%',
                            'Performance',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricCircle(
                            '${_avgResolutionTime.toStringAsFixed(1)}h',
                            'Avg. Resolution',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNearbyCard(Map<String, dynamic> complaint) {
    final priority = complaint['priority'] ?? 'Medium';
    final priorityColor = priority == 'High' ? Colors.red : (priority == 'Medium' ? Colors.orange : Colors.green);
    final distance = complaint['distance'] ?? 0.0;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      complaint['complaintNumber'] ?? 'N/A',
                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(priority, style: TextStyle(fontSize: 10, color: priorityColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  complaint['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint['locationAddress'] ?? 'No address',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${distance.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> assignment) {
    final complaint = assignment['Complaint'] ?? assignment;
    final priority = complaint['Priority'] ?? assignment['priority'] ?? 'Medium';
    final priorityColor = priority == 'High' ? Colors.red : (priority == 'Medium' ? Colors.orange : Colors.green);
    final status = assignment['Status'] ?? assignment['status'] ?? 'Assigned';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToTask(assignment),
        borderRadius: BorderRadius.circular(12),
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
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority, style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'Completed' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 11, color: status == 'Completed' ? Colors.green : Colors.blue)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['Title'] ?? assignment['title'] ?? 'No Title',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint['LocationAddress'] ?? assignment['locationAddress'] ?? 'No address',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    complaint['Category']?['CategoryName'] ?? assignment['categoryName'] ?? 'General',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.location_city, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    complaint['Zone']?['ZoneName'] ?? assignment['zoneName'] ?? 'Unknown',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
      ],
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}