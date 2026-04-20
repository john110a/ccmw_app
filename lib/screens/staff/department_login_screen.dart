import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../config/routes.dart';

class DepartmentLoginScreen extends StatefulWidget {
  const DepartmentLoginScreen({super.key});

  @override
  State<DepartmentLoginScreen> createState() => _DepartmentLoginScreenState();
}

class _DepartmentLoginScreenState extends State<DepartmentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedDepartment;

  // Department list with their corresponding admin emails
  final List<Map<String, dynamic>> departments = [
    {
      'name': 'WASA - Water & Sewerage',
      'adminEmail': 'water.admin@ccmw.gov.pk',
      'code': 'WASA'
    },
    {
      'name': 'RWMC - Waste Management',
      'adminEmail': 'sanitation.admin@ccmw.gov.pk',
      'code': 'RWMC'
    },
    {
      'name': 'WAPDA - Electricity',
      'adminEmail': 'electric.admin@ccmw.gov.pk',
      'code': 'LESCO'
    },
    {
      'name': 'CDA - Civic Services',
      'adminEmail': 'cda.admin@ccmw.gov.pk',
      'code': 'CDA'
    },
  ];

  // System admin can access any department
  final String systemAdminEmail = 'admin@ccmw.gov.pk';

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final selectedDept = _selectedDepartment;
        if (selectedDept == null) {
          throw Exception('Please select your department');
        }

        final email = _emailController.text.trim();
        final isSystemAdmin = email == systemAdminEmail;

        // Find the selected department details
        final department = departments.firstWhere(
              (dept) => dept['name'] == selectedDept,
        );

        // For non-system admin, verify they belong to the selected department
        if (!isSystemAdmin && email != department['adminEmail']) {
          throw Exception(
              'This email is not authorized for ${department['name']}. '
                  'Please contact your system administrator.'
          );
        }

        // Perform login
        await _authService.staffLogin(email, _passwordController.text);

        if (!mounted) return;

        // Get user info after login
        String? userType = await _authService.getUserType();
        String? userName = await _authService.getUserName();

        print('✅ User type after login: $userType');
        print('✅ User name after login: $userName');

        // Validate user type (allow system admin to access)
        if (!isSystemAdmin && userType?.toLowerCase() != 'department_admin') {
          await _authService.logout();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid department admin account'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Store department info in SharedPreferences for later use
        await _authService.updateUserData('department_name', department['name']);
        await _authService.updateUserData('department_code', department['code']);
        await _authService.updateUserData('department_admin_email', department['adminEmail']);

        // Store if this is system admin accessing department
        if (isSystemAdmin) {
          await _authService.updateUserData('is_system_admin_access', 'true');
        }

        // Navigate to department dashboard
        Navigator.pushReplacementNamed(context, Routes.departmentDashboard);

        String welcomeMessage = isSystemAdmin
            ? 'System Admin accessing ${department['name']}'
            : 'Welcome ${userName ?? 'Admin'} to ${department['name']}!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(welcomeMessage),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.isEmpty ? 'Invalid account' : errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Department Login',
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),

                Text(
                  'Department Administrator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage departmental complaints and staff',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                // System Admin Note
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'System Admin can use: admin@ccmw.gov.pk',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Department Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Department',
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _selectedDepartment,
                  items: [
                    for (var dept in departments)
                      DropdownMenuItem<String>(
                        value: dept['name'] as String,
                        child: Text(dept['name'] as String),
                      )
                  ],
                  onChanged: _isLoading ? null : (String? newValue) {
                    setState(() {
                      _selectedDepartment = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  style: const TextStyle(color: Colors.black),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Department Email',
                    hintText: 'dept.admin@ccmw.gov.pk',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  style: const TextStyle(color: Colors.black),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter department password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Login to Department',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back Button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back to Role Selection',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}