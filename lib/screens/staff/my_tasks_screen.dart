// lib/screens/staff/my_tasks_screen.dart

import 'package:flutter/material.dart';
import '../../services/staff_action_service.dart';
import '../../services/AuthService.dart';
import '../../config/routes.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final StaffActionService _staffActionService = StaffActionService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _activeTasks = [];
  List<Map<String, dynamic>> _completedTasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'active';
  String? _staffId;

  // Statistics
  int _totalActive = 0;
  int _totalCompleted = 0;
  int _overdueCount = 0;
  int _inProgressCount = 0;
  int _acceptedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStaffId();
  }

  Future<void> _loadStaffId() async {
    final staffId = await _authService.getStaffId();
    setState(() {
      _staffId = staffId;
    });
    if (staffId != null) {
      _loadTasks();
    } else {
      setState(() {
        _errorMessage = 'Staff ID not found. Please login again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    if (_staffId == null) return;

    setState(() => _isLoading = true);
    try {
      // Load active tasks
      print('📡 Loading active tasks for staff: $_staffId');
      final activeData = await _staffActionService.getMyAssignments(_staffId!, status: 'active');
      print('📦 Active data: $activeData');

      final activeAssignments = activeData['Assignments'] as List? ?? [];
      final activeStats = activeData['Statistics'] ?? {};

      // Load completed tasks
      print('📡 Loading completed tasks for staff: $_staffId');
      final completedData = await _staffActionService.getMyAssignments(_staffId!, status: 'completed');
      print('📦 Completed data: $completedData');

      final completedAssignments = completedData['Assignments'] as List? ?? [];

      // Print first active task for debugging
      if (activeAssignments.isNotEmpty) {
        print('🔍 First active task: ${activeAssignments[0]}');
        print('🔍 Active task keys: ${activeAssignments[0].keys}');
      }

      setState(() {
        _activeTasks = activeAssignments.cast<Map<String, dynamic>>();
        _completedTasks = completedAssignments.cast<Map<String, dynamic>>();
        _totalActive = _activeTasks.length;
        _totalCompleted = _completedTasks.length;
        _overdueCount = activeStats['Overdue'] ?? 0;
        _inProgressCount = activeStats['InProgress'] ?? 0;
        _acceptedCount = activeStats['Accepted'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading tasks: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToTaskDetail(Map<String, dynamic> task) async {
    // Extract values with proper key names (API uses capitalized keys)
    final assignmentId = task['AssignmentId']?.toString() ?? task['assignmentId']?.toString();
    final title = task['Title']?.toString() ?? task['title']?.toString() ?? 'No Title';
    final complaintNumber = task['ComplaintNumber']?.toString() ?? task['complaintNumber']?.toString() ?? 'N/A';
    final description = task['Description']?.toString() ?? task['description']?.toString() ?? 'No description';
    final priority = task['Priority']?.toString() ?? task['priority']?.toString() ?? 'Medium';
    final categoryName = task['CategoryName']?.toString() ?? task['categoryName']?.toString() ?? 'General';
    final zoneName = task['ZoneName']?.toString() ?? task['zoneName']?.toString() ?? 'Unknown';
    final locationAddress = task['LocationAddress']?.toString() ?? task['locationAddress']?.toString() ?? '';
    final locationLatitude = task['LocationLatitude'] ?? task['locationLatitude'];
    final locationLongitude = task['LocationLongitude'] ?? task['locationLongitude'];
    final acceptedAt = task['AcceptedAt'] ?? task['acceptedAt'];
    final startedAt = task['StartedAt'] ?? task['startedAt'];
    final completedAt = task['CompletedAt'] ?? task['completedAt'];
    final status = task['Status']?.toString() ?? task['status']?.toString() ?? 'Assigned';

    final result = await Navigator.pushNamed(
      context,
      Routes.taskDetail,
      arguments: {
        'assignmentId': assignmentId,
        'staffId': _staffId,
        'title': title,
        'complaintNumber': complaintNumber,
        'description': description,
        'priority': priority,
        'categoryName': categoryName,
        'zoneName': zoneName,
        'locationAddress': locationAddress,
        'locationLatitude': locationLatitude,
        'locationLongitude': locationLongitude,
        'acceptedAt': acceptedAt,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'status': status,
      },
    );

    if (result == true && mounted) {
      _loadTasks();
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'Accepted': return 'Accepted';
      case 'InProgress': return 'In Progress';
      case 'Completed': return 'Completed';
      default: return 'Assigned';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'InProgress': return Colors.blue;
      case 'Accepted': return Colors.orange;
      default: return Colors.grey;
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
          'My Tasks',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadTasks,
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
              onPressed: _loadTasks,
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
                Expanded(child: _buildStatCard('$_totalActive', 'Active', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('$_inProgressCount', 'In Progress', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '$_overdueCount',
                    'Overdue',
                    Colors.red,
                    textColor: _overdueCount > 0 ? Colors.red : null,
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
                          'Active ($_totalActive)',
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
                          'Completed ($_totalCompleted)',
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

          // Tasks List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTasks,
              child: _selectedTab == 'active' && _activeTasks.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No active tasks', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('All tasks completed!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : _selectedTab == 'completed' && _completedTasks.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No completed tasks', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Tasks you complete will appear here', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _selectedTab == 'active' ? _activeTasks.length : _completedTasks.length,
                itemBuilder: (context, index) {
                  final task = _selectedTab == 'active'
                      ? _activeTasks[index]
                      : _completedTasks[index];
                  return _buildTaskCard(task);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, {Color? textColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor ?? color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    // Extract values with proper key names (API uses capitalized keys)
    final title = task['Title']?.toString() ?? task['title']?.toString() ?? 'No Title';
    final complaintNumber = task['ComplaintNumber']?.toString() ?? task['complaintNumber']?.toString() ?? 'No Number';
    final description = task['Description']?.toString() ?? task['description']?.toString() ?? 'No description';
    final locationAddress = task['LocationAddress']?.toString() ?? task['locationAddress']?.toString() ?? 'No address';
    final priority = task['Priority']?.toString() ?? task['priority']?.toString() ?? 'Medium';
    final status = task['Status']?.toString() ?? task['status']?.toString() ?? 'Assigned';
    final categoryName = task['CategoryName']?.toString() ?? task['categoryName']?.toString() ?? 'General';
    final zoneName = task['ZoneName']?.toString() ?? task['zoneName']?.toString() ?? 'Unknown';
    final isOverdue = task['IsOverdue'] == true || task['isOverdue'] == true;

    final priorityColor = priority == 'High'
        ? Colors.red
        : priority == 'Medium'
        ? Colors.orange
        : Colors.green;

    final statusDisplay = _getStatusDisplay(status);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue ? BorderSide(color: Colors.red, width: 1) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateToTaskDetail(task),
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
                      title,
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
                      priority,
                      style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    complaintNumber,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
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
                      locationAddress,
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
                      statusDisplay,
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.category, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        categoryName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_city, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        zoneName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
}