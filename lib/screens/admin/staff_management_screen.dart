import 'package:flutter/material.dart';
import '../../services/staff_service.dart';
import '../../services/department_service.dart';
import '../../models/staff_profile_model.dart';
import '../../models/department_model.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  final DepartmentService _departmentService = DepartmentService();

  List<StaffProfile> _staffList = [];
  List<Department> _departments = [];
  List<StaffProfile> _filteredStaff = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedAvailability;
  String _sortBy = 'name';
  String? _errorMessage;

  // Role options
  final List<String> _roleOptions = ['Field_Staff', 'Department_Admin', 'System_Admin'];
  final Map<String, String> _roleDisplayNames = {
    'Field_Staff': 'Field Staff',
    'Department_Admin': 'Department Admin',
    'System_Admin': 'System Admin',
  };

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('📡 Loading staff and departments...');

      final results = await Future.wait([
        _staffService.getAllStaff(),
        _departmentService.getAllDepartments(),
      ]);

      print('✅ Loaded ${(results[0] as List).length} staff members');
      print('✅ Loaded ${(results[1] as List).length} departments');

      setState(() {
        _staffList = results[0] as List<StaffProfile>;
        _departments = results[1] as List<Department>;
        _filteredStaff = _staffList;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStaff() {
    setState(() {
      _filteredStaff = _staffList.where((staff) {
        bool matchesSearch = _searchQuery.isEmpty ||
            (staff.fullName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (staff.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        bool matchesDepartment = _selectedDepartment == null ||
            staff.departmentId == _selectedDepartment;

        bool matchesAvailability = _selectedAvailability == null ||
            (_selectedAvailability == 'Available' && staff.isAvailable) ||
            (_selectedAvailability == 'Busy' && !staff.isAvailable);

        return matchesSearch && matchesDepartment && matchesAvailability;
      }).toList();

      _sortStaff();
    });
  }

  void _sortStaff() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredStaff.sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));
          break;
        case 'performance':
          _filteredStaff.sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
          break;
        case 'workload':
          _filteredStaff.sort((a, b) => b.pendingAssignments.compareTo(a.pendingAssignments));
          break;
      }
    });
  }

  Future<void> _addStaff(Map<String, dynamic> staffData) async {
    try {
      await _staffService.addStaff(staffData);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff added successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStaff(StaffProfile staff) async {
    try {
      await _staffService.updateStaff(staff.staffId, staff.toJson());
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAvailability(StaffProfile staff) async {
    try {
      await _staffService.toggleAvailability(staff.staffId, !staff.isAvailable);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedDepartment;
    String? selectedRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // FIXED: Department dropdown - always start with null
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department'),
                  value: null, // Always start with null
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Department')),
                    ..._departments.map((dept) => DropdownMenuItem(
                      value: dept.departmentId,
                      child: Text(dept.departmentName),
                    )),
                  ],
                  onChanged: (value) => selectedDepartment = value,
                  validator: (value) => value == null ? 'Please select a department' : null,
                ),
                const SizedBox(height: 12),

                // FIXED: Role dropdown - always start with null
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  value: null, // Always start with null
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Select Role')),
                    DropdownMenuItem(value: 'Field_Staff', child: Text('Field Staff')),
                    DropdownMenuItem(value: 'Department_Admin', child: Text('Department Admin')),
                    DropdownMenuItem(value: 'System_Admin', child: Text('System Admin')),
                  ],
                  onChanged: (value) => selectedRole = value,
                  validator: (value) => value == null ? 'Please select a role' : null,
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                _addStaff({
                  'fullName': nameController.text,
                  'email': emailController.text,
                  'phoneNumber': phoneController.text,
                  'departmentId': selectedDepartment,
                  'role': selectedRole,
                });
              }
            },
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }

  void _showStaffDetails(StaffProfile staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  staff.fullName ?? 'Unknown',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: staff.isAvailable ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.isAvailable ? 'Available' : 'Busy',
                    style: TextStyle(
                      color: staff.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_roleDisplayNames[staff.role] ?? staff.role ?? 'No Role'} • ${staff.employeeId ?? 'No ID'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              children: [
                _buildDetailCard(
                  'Total Tasks',
                  staff.totalAssignments.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildDetailCard(
                  'Completed',
                  staff.completedAssignments.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildDetailCard(
                  'Pending',
                  staff.pendingAssignments.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildDetailCard(
                  'Performance',
                  '${staff.performanceScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Performance Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: staff.performanceScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                staff.performanceScore >= 80 ? Colors.green :
                staff.performanceScore >= 60 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditStaffDialog(staff);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAvailability(staff),
                    icon: Icon(staff.isAvailable ? Icons.block : Icons.check_circle),
                    label: Text(staff.isAvailable ? 'Mark Busy' : 'Mark Available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: staff.isAvailable ? Colors.orange : Colors.green,
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

  void _showEditStaffDialog(StaffProfile staff) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff.fullName);
    String? selectedDepartment = staff.departmentId;
    String? selectedRole = staff.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Staff'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),

                // FIXED: Department dropdown - validate value exists
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Department'),
                  value: _departments.any((dept) => dept.departmentId == selectedDepartment)
                      ? selectedDepartment
                      : null,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ..._departments.map((dept) => DropdownMenuItem(
                      value: dept.departmentId,
                      child: Text(dept.departmentName),
                    )),
                  ],
                  onChanged: (value) => selectedDepartment = value,
                ),
                const SizedBox(height: 12),

                // FIXED: Role dropdown - validate value exists
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role'),
                  value: _roleOptions.contains(selectedRole) ? selectedRole : null,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'Field_Staff', child: Text('Field Staff')),
                    DropdownMenuItem(value: 'Department_Admin', child: Text('Department Admin')),
                    DropdownMenuItem(value: 'System_Admin', child: Text('System Admin')),
                  ],
                  onChanged: (value) => selectedRole = value,
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                final updatedStaff = StaffProfile(
                  staffId: staff.staffId,
                  userId: staff.userId,
                  fullName: nameController.text,
                  departmentId: selectedDepartment,
                  role: selectedRole,
                  employeeId: staff.employeeId,
                  hireDate: staff.hireDate,
                  totalAssignments: staff.totalAssignments,
                  completedAssignments: staff.completedAssignments,
                  pendingAssignments: staff.pendingAssignments,
                  averageResolutionTime: staff.averageResolutionTime,
                  performanceScore: staff.performanceScore,
                  isAvailable: staff.isAvailable,
                  email: staff.email,
                  phoneNumber: staff.phoneNumber,
                  departmentName: staff.departmentName,
                );
                _updateStaff(updatedStaff);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
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
          title: Text('Staff Management', style: TextStyle(color: Colors.grey[900])),
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
          title: Text('Staff Management', style: TextStyle(color: Colors.grey[900])),
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Staff Management', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _showAddStaffDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterStaff();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown(
                        value: _selectedDepartment,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Departments')),
                          ..._departments.map((dept) => DropdownMenuItem(
                            value: dept.departmentId,
                            child: Text(dept.departmentName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _filterStaff();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        value: _selectedAvailability,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Staff')),
                          DropdownMenuItem(value: 'Available', child: Text('Available')),
                          DropdownMenuItem(value: 'Busy', child: Text('Busy')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAvailability = value;
                            _filterStaff();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                          DropdownMenuItem(value: 'performance', child: Text('Sort by Performance')),
                          DropdownMenuItem(value: 'workload', child: Text('Sort by Workload')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                            _sortStaff();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('${_staffList.length}', 'Total Staff', Colors.blue),
                _buildSummaryStat(
                  '${_staffList.where((s) => s.isAvailable).length}',
                  'Available',
                  Colors.green,
                ),
                _buildSummaryStat(
                  '${_staffList.where((s) => !s.isAvailable).length}',
                  'Busy',
                  Colors.orange,
                ),
                _buildSummaryStat(
                  '${_staffList.fold<int>(0, (sum, s) => sum + s.pendingAssignments)}',
                  'Pending Tasks',
                  Colors.red,
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: _filteredStaff.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No staff members found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStaff.length,
              itemBuilder: (context, index) => _buildStaffCard(_filteredStaff[index]),
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Filter dropdown with proper null value validation
  Widget _buildFilterDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    // Check if the value exists in the items list
    final bool valueExists = items.any((item) => item.value == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valueExists ? value : null,
          items: items,
          onChanged: onChanged,
          isDense: true,
          hint: const Text('Select'),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStaffCard(StaffProfile staff) {
    String deptName = _departments
        .firstWhere(
          (d) => d.departmentId == staff.departmentId,
      orElse: () => Department(
        departmentId: '',
        departmentName: 'Unknown',
        departmentCode: null,
        privatizationStatus: null,
        contractorId: null,
        headAdminId: null,
        performanceScore: null,
        performanceRating: null,
        activeComplaintsCount: 0,
        resolvedComplaintsCount: 0,
        totalComplaintsCount: 0,
        averageResolutionTimeDays: null,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: null,
      ),
    )
        .departmentName;

    double completionRate = staff.totalAssignments > 0
        ? (staff.completedAssignments / staff.totalAssignments * 100)
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showStaffDetails(staff),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.blue[100], shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.blue, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(staff.fullName ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: staff.isAvailable ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$deptName • ${_roleDisplayNames[staff.role] ?? staff.role ?? 'No Role'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.assignment, size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('${staff.pendingAssignments} pending', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 12),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('${staff.performanceScore.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: completionRate >= 80 ? Colors.green[50] :
                          completionRate >= 60 ? Colors.orange[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${completionRate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: completionRate >= 80 ? Colors.green :
                            completionRate >= 60 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(staff.employeeId ?? '', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: completionRate / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 80 ? Colors.green :
                  completionRate >= 60 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}