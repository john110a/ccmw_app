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
        _errorMessage = 'Staff ID not found';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    if (_staffId == null) return;

    setState(() => _isLoading = true);
    try {
      // Load active tasks
      final activeData = await _staffActionService.getMyAssignments(_staffId!, status: 'active');
      final assignments = activeData['Assignments'] as List? ?? [];

      // Load completed tasks
      final completedData = await _staffActionService.getMyAssignments(_staffId!, status: 'completed');
      final completedAssignments = completedData['Assignments'] as List? ?? [];

      setState(() {
        _activeTasks = assignments.cast<Map<String, dynamic>>();
        _completedTasks = completedAssignments.cast<Map<String, dynamic>>();
        _totalActive = _activeTasks.length;
        _totalCompleted = _completedTasks.length;
        _overdueCount = _activeTasks.where((t) => t['isOverdue'] == true).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToTaskDetail(Map<String, dynamic> task) async {
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
                Expanded(child: _buildStatCard('$_totalCompleted', 'Completed', Colors.green)),
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
    final priorityColor = task['priority'] == 'High'
        ? Colors.red
        : task['priority'] == 'Medium'
        ? Colors.orange
        : Colors.green;

    final status = task['status'] ?? 'Assigned';
    final statusDisplay = _getStatusDisplay(status);
    final statusColor = status == 'Completed' ? Colors.green
        : status == 'InProgress' ? Colors.blue
        : status == 'Accepted' ? Colors.orange
        : Colors.grey;

    final isOverdue = task['isOverdue'] == true;

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
                      task['title'] ?? 'No Title',
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
                      task['priority'] ?? 'Medium',
                      style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    task['complaintNumber'] ?? 'No Number',
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
                task['description'] ?? 'No description',
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
                      task['locationAddress'] ?? 'No address',
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
                        task['categoryName'] ?? 'General',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_city, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        task['zoneName'] ?? 'Unknown',
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