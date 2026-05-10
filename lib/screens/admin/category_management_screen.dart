// lib/screens/admin/category_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../services/department_service.dart';
import '../../models/category_model.dart';
import '../../models/department_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  final DepartmentService _departmentService = DepartmentService();

  List<Category> _categories = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedDepartmentFilter;
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categoriesData = await _categoryService.getAllCategories();
      final departments = await _departmentService.getAllDepartments();

      print('📊 Raw categories data: $categoriesData');

      setState(() {
        _categories = categoriesData.map((json) => Category.fromJson(json)).toList();
        _departments = departments;
        _isLoading = false;
      });

      print('✅ Loaded ${_categories.length} categories');
      for (var cat in _categories) {
        print('   - ${cat.categoryName} | Dept: ${cat.departmentId} | Active: ${cat.isActive}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading categories: $e');
    }
  }

  List<Category> _getFilteredCategories() {
    var filtered = _categories;

    // Filter by department
    if (_selectedDepartmentFilter != null && _selectedDepartmentFilter != 'all') {
      filtered = filtered.where((c) => c.departmentId == _selectedDepartmentFilter).toList();
    }

    // Filter by status
    if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
      final isActive = _selectedStatusFilter == 'active';
      filtered = filtered.where((c) => c.isActive == isActive).toList();
    }

    return filtered;
  }

  void _showAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final iconNameController = TextEditingController();
    final colorCodeController = TextEditingController();
    String? selectedDepartmentId;
    int priorityWeight = 1;
    int expectedHours = 24;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      value: selectedDepartmentId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select Department')),
                        ..._departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept.departmentId,
                            child: Text(dept.departmentName),
                          );
                        }),
                      ],
                      onChanged: (value) => setDialogState(() => selectedDepartmentId = value),
                      validator: (value) => value == null ? 'Department is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Category Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                        helperText: 'Unique code like "GARBAGE", "WATER_LEAK"',
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Code is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: iconNameController,
                      decoration: const InputDecoration(
                        labelText: 'Icon Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                        helperText: 'Material icon name (e.g., "delete", "water_drop")',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: colorCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Color Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens),
                        helperText: 'Hex color like "#4CAF50"',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: priorityWeight.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Priority Weight',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.priority_high),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => priorityWeight = int.tryParse(value) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: expectedHours.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Resolution Hours',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => expectedHours = int.tryParse(value) ?? 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
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
                    if (selectedDepartmentId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a department'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    try {
                      await _categoryService.createCategory({
                        'CategoryName': nameController.text,
                        'CategoryCode': codeController.text.toUpperCase(),
                        'Description': descriptionController.text,
                        'IconName': iconNameController.text.isNotEmpty ? iconNameController.text : 'category',
                        'ColorCode': colorCodeController.text.isNotEmpty ? colorCodeController.text : '#2196F3',
                        'PriorityWeight': priorityWeight,
                        'ExpectedResolutionTimeHours': expectedHours,
                        'DepartmentId': selectedDepartmentId,
                        'IsActive': true,
                      });
                      await _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category created'), backgroundColor: Colors.green),
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
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.categoryName);
    final codeController = TextEditingController(text: category.categoryCode);
    final descriptionController = TextEditingController(text: category.description);
    final iconNameController = TextEditingController(text: category.iconName);
    final colorCodeController = TextEditingController(text: category.colorCode);
    String? selectedDepartmentId = category.departmentId;
    int priorityWeight = category.priorityWeight;
    int expectedHours = category.expectedResolutionTimeHours;
    bool isActive = category.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Category'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      value: selectedDepartmentId,
                      items: _departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept.departmentId,
                          child: Text(dept.departmentName),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedDepartmentId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Category Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: iconNameController,
                      decoration: const InputDecoration(
                        labelText: 'Icon Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.image),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: colorCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Color Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: priorityWeight.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Priority Weight',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.priority_high),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => priorityWeight = int.tryParse(value) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: expectedHours.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Resolution Hours',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => expectedHours = int.tryParse(value) ?? 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Inactive categories won\'t appear in citizen reports'),
                      value: isActive,
                      onChanged: (value) => setDialogState(() => isActive = value),
                      activeColor: Colors.green,
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
                      await _categoryService.updateCategory(category.categoryId, {
                        'CategoryName': nameController.text,
                        'CategoryCode': codeController.text,
                        'Description': descriptionController.text,
                        'IconName': iconNameController.text,
                        'ColorCode': colorCodeController.text,
                        'PriorityWeight': priorityWeight,
                        'ExpectedResolutionTimeHours': expectedHours,
                        'DepartmentId': selectedDepartmentId,
                        'IsActive': isActive,
                      });
                      await _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated'), backgroundColor: Colors.green),
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
          );
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.categoryName}"?\n\nThis will affect existing complaints under this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _categoryService.deleteCategory(category.categoryId);
                await _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${category.categoryName} deleted'), backgroundColor: Colors.red),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.category;
    switch (iconName.toLowerCase()) {
      case 'delete': return Icons.delete;
      case 'water_drop': return Icons.water_drop;
      case 'lightbulb': return Icons.lightbulb;
      case 'road': return Icons.change_circle;
      case 'report_problem': return Icons.report_problem;
      case 'construction': return Icons.construction;
      case 'electrical_services': return Icons.electrical_services;
      case 'water_damage': return Icons.water_damage;
      case 'park': return Icons.park;
      case 'warning': return Icons.warning;
      case 'circle': return Icons.circle;
      default: return Icons.category;
    }
  }

  Color _getColorFromCode(String? colorCode) {
    if (colorCode == null) return Colors.blue;
    try {
      String hex = colorCode.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();
    final activeCount = filteredCategories.where((c) => c.isActive).length;
    final inactiveCount = filteredCategories.length - activeCount;

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
          title: Text('Category Management', style: TextStyle(color: Colors.grey[900])),
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
          title: Text('Category Management', style: TextStyle(color: Colors.grey[900])),
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
        title: Text('Category Management', style: TextStyle(color: Colors.grey[900])),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Add Category',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats & Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard('${filteredCategories.length}', 'Total', Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('$activeCount', 'Active', Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('$inactiveCount', 'Inactive', Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedDepartmentFilter,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Departments')),
                          ..._departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept.departmentId,
                              child: Text(dept.departmentName),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _selectedDepartmentFilter = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: _selectedStatusFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Status')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (value) => setState(() => _selectedStatusFilter = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Categories List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: filteredCategories.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No categories found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a category',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final department = _departments.firstWhere(
                        (d) => d.departmentId == category.departmentId,
                    orElse: () => Department(
                      departmentId: '',
                      departmentName: 'Unknown',
                      departmentCode: '',
                      activeComplaintsCount: 0,
                      resolvedComplaintsCount: 0,
                      totalComplaintsCount: 0,
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return _buildCategoryCard(category, department);
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

  Widget _buildCategoryCard(Category category, Department department) {
    final isActive = category.isActive;
    final statusColor = isActive ? Colors.green : Colors.red;
    final statusText = isActive ? 'Active' : 'Inactive';
    final iconColor = _getColorFromCode(category.colorCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(category.iconName),
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.categoryName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              category.categoryCode ?? 'No Code',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (category.description != null && category.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  category.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDetailChip(Icons.business, department.departmentName),
                _buildDetailChip(Icons.priority_high, 'Priority: ${category.priorityWeight}'),
                _buildDetailChip(Icons.timer, '${category.expectedResolutionTimeHours}h'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditCategoryDialog(category),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmDialog(category),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
}