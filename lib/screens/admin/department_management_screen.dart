// lib/screens/admin/department_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/department_service.dart';
import '../../services/AuthService.dart';
import '../../models/department_model.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  final DepartmentService _departmentService = DepartmentService();
  final AuthService _authService = AuthService();

  List<Department> _departments = [];
  List<Map<String, dynamic>> _selectedDepartmentStaff = [];
  List<Map<String, dynamic>> _availableZones = [];

  bool _isLoading = true;
  bool _isLoadingStaff = false;
  String? _selectedDepartmentId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _departmentService.getAllDepartments();
      print('📊 Loaded ${departments.length} departments');

      // Debug print each department's performance
      for (var dept in departments) {
        print('📊 ${dept.departmentName}: Score=${dept.performanceScore}%, Active=${dept.activeComplaintsCount}, Total=${dept.totalComplaintsCount}');
      }

      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading departments: $e');
    }
  }

  Future<void> _loadDepartmentStaff(String departmentId) async {
    setState(() => _isLoadingStaff = true);
    try {
      final response = await _departmentService.getDepartmentStaff(departmentId);
      setState(() {
        _selectedDepartmentStaff = List<Map<String, dynamic>>.from(response['Staff'] ?? []);
        _selectedDepartmentId = departmentId;
        _isLoadingStaff = false;
      });

      _showStaffBottomSheet();
    } catch (e) {
      setState(() => _isLoadingStaff = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading staff: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showStaffBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                  'Department Staff',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedDepartmentStaff.length} staff members',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                Expanded(
                  child: _isLoadingStaff
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedDepartmentStaff.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No staff assigned',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add staff to this department',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: _selectedDepartmentStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _selectedDepartmentStaff[index];
                      return _buildStaffCard(staff);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddDepartmentDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    String? privatizationStatus = 'Public';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Department'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Department Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Code is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Privatization Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_center),
                  ),
                  value: privatizationStatus,
                  items: const [
                    DropdownMenuItem(value: 'Public', child: Text('Public')),
                    DropdownMenuItem(value: 'Private', child: Text('Private')),
                    DropdownMenuItem(value: 'PPP', child: Text('PPP')),
                  ],
                  onChanged: (value) => privatizationStatus = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                try {
                  await _departmentService.createDepartment({
                    'DepartmentName': nameController.text,
                    'DepartmentCode': codeController.text,
                    'Description': descriptionController.text,
                    'PrivatizationStatus': privatizationStatus,
                  });
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department created'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDepartmentDialog(Department department) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: department.departmentName);
    final codeController = TextEditingController(text: department.departmentCode ?? '');
    final descriptionController = TextEditingController(text: department.description ?? '');
    String? privatizationStatus = department.privatizationStatus ?? 'Public';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Department'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Department Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Privatization Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_center),
                  ),
                  value: privatizationStatus,
                  items: const [
                    DropdownMenuItem(value: 'Public', child: Text('Public')),
                    DropdownMenuItem(value: 'Private', child: Text('Private')),
                    DropdownMenuItem(value: 'PPP', child: Text('PPP')),
                  ],
                  onChanged: (value) => privatizationStatus = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                try {
                  await _departmentService.updateDepartment(department.departmentId, {
                    'DepartmentName': nameController.text,
                    'DepartmentCode': codeController.text,
                    'Description': descriptionController.text,
                    'PrivatizationStatus': privatizationStatus,
                  });
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Department updated'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Department department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Department'),
        content: Text('Are you sure you want to deactivate "${department.departmentName}"?\n\nThis will prevent new complaints from being assigned to this department.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _departmentService.deactivateDepartment(department.departmentId);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${department.departmentName} deactivated'), backgroundColor: Colors.orange),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showActivateConfirmDialog(Department department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Department'),
        content: Text('Are you sure you want to activate "${department.departmentName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _departmentService.activateDepartment(department.departmentId);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${department.departmentName} activated'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
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
          title: Text('Department Management', style: TextStyle(color: Colors.grey[900])),
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
          title: Text('Department Management', style: TextStyle(color: Colors.grey[900])),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    // Calculate stats
    final totalDepartments = _departments.length;
    final activeDepartments = _departments.where((d) => d.isActive).length;
    final inactiveDepartments = totalDepartments - activeDepartments;
    final avgPerformance = _departments.where((d) => d.performanceScore != null).fold<double>(0, (sum, d) => sum + (d.performanceScore ?? 0)) / (_departments.where((d) => d.performanceScore != null).length);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Department Management', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _showAddDepartmentDialog,
            tooltip: 'Add Department',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('$totalDepartments', 'Total', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('$activeDepartments', 'Active', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('$inactiveDepartments', 'Inactive', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('${avgPerformance.toStringAsFixed(1)}%', 'Avg Score', Colors.purple),
                ),
              ],
            ),
          ),

          // Departments List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _departments.length,
                itemBuilder: (context, index) {
                  final department = _departments[index];
                  return _buildDepartmentCard(department);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    final isActive = department.isActive;
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusText = isActive ? 'Active' : 'Inactive';
    final performance = department.performanceScore ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.departmentName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              department.departmentCode ?? 'No Code',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              department.privatizationStatus ?? 'Public',
                              style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (department.description != null && department.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  department.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),

            // Stats Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.assignment, 'Total: ${department.totalComplaintsCount}', Colors.blue),
                _buildInfoChip(Icons.pending, 'Active: ${department.activeComplaintsCount}', Colors.orange),
                _buildInfoChip(Icons.check_circle, 'Resolved: ${department.resolvedComplaintsCount}', Colors.green),
                _buildInfoChip(Icons.access_time, 'Avg Resolution: ${department.averageResolutionTimeDays?.toStringAsFixed(1) ?? 0}d', Colors.purple),
              ],
            ),

            const SizedBox(height: 12),

            // Performance Score Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Performance Score', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      '${performance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: performance >= 80 ? Colors.green : (performance >= 60 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: performance / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    performance >= 80 ? Colors.green : (performance >= 60 ? Colors.orange : Colors.red),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _loadDepartmentStaff(department.departmentId),
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('Staff'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDepartmentDialog(department),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirmDialog(department),
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Deactivate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showActivateConfirmDialog(department),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Activate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final isAvailable = staff['isAvailable'] ?? false;
    final pendingAssignments = staff['pendingAssignments'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAvailable ? Colors.green[100] : Colors.red[100],
          child: Text(
            (staff['fullName'] ?? 'S').substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: isAvailable ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          staff['fullName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff['role'] ?? 'Staff', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('ID: ${staff['employeeId'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Busy',
                style: TextStyle(fontSize: 10, color: isAvailable ? Colors.green : Colors.red),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$pendingAssignments pending',
              style: TextStyle(fontSize: 10, color: pendingAssignments > 3 ? Colors.red : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}