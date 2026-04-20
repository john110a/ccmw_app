import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../config/routes.dart';

class FieldStaffLoginScreen extends StatefulWidget {
  const FieldStaffLoginScreen({super.key});

  @override
  State<FieldStaffLoginScreen> createState() => _FieldStaffLoginScreenState();
}

class _FieldStaffLoginScreenState extends State<FieldStaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _selectedDepartment;

  // Department list for staff
  final List<Map<String, dynamic>> departments = [
    {
      'name': 'WASA - Water & Sewerage',
      'code': 'WASA',
      'staffEmails': [
        'usman.a@ccmw.gov.pk',
        'staff.wasa1@ccmw.gov.pk',
        'staff.wasa2@ccmw.gov.pk',
      ]
    },
    {
      'name': 'RWMC - Waste Management',
      'code': 'RWMC',
      'staffEmails': [
        'kashif.m@ccmw.gov.pk',
        'saima.b@ccmw.gov.pk',
        'staff.rwmc1@ccmw.gov.pk',
      ]
    },
    {
      'name': 'WAPDA - Electricity',
      'code': 'ELEC',
      'staffEmails': [
        'imran.k@ccmw.gov.pk',
        'staff.elec1@ccmw.gov.pk',
        'staff.elec2@ccmw.gov.pk',
      ]
    },
    {
      'name': 'CDA - Civic Services',
      'code': 'CDA',
      'staffEmails': [
        'alice.smith@example.com',
        'nadia.a@ccmw.gov.pk',
        'staff.cda1@ccmw.gov.pk',
      ]
    },
  ];

  // System admin can also access staff view if needed
  final String systemAdminEmail = 'admin@ccmw.gov.pk';

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final email = _emailController.text.trim();
        final isSystemAdmin = email == systemAdminEmail;

        // Perform login
        await _authService.staffLogin(email, _passwordController.text);

        if (!mounted) return;

        // Get user info after login
        String? userType = await _authService.getUserType();
        String? userName = await _authService.getUserName();
        String? staffId = await _authService.getStaffId();

        print('✅ User type after login: $userType');
        print('✅ Staff ID: $staffId');
        print('✅ User name: $userName');

        // Validate user type (allow system admin to access)
        if (!isSystemAdmin && userType?.toLowerCase() != 'field_staff') {
          await _authService.logout();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid field staff account'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // If not system admin, verify department
        if (!isSystemAdmin) {
          String? departmentName;
          String? departmentCode;

          for (var dept in departments) {
            if (dept['staffEmails'].contains(email)) {
              departmentName = dept['name'];
              departmentCode = dept['code'];
              break;
            }
          }

          if (departmentName == null) {
            await _authService.logout();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Staff email not recognized'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          await _authService.updateUserData('department_name', departmentName);
          await _authService.updateUserData('department_code', departmentCode);
        }

        // Store staff flags
        await _authService.updateUserData('is_staff', 'true');

        if (isSystemAdmin) {
          await _authService.updateUserData('is_system_admin_access', 'true');
        }

        // Navigate to staff dashboard
        Navigator.pushReplacementNamed(context, Routes.staffDashboard);

        String welcomeMessage = isSystemAdmin
            ? 'System Admin accessing Staff Portal'
            : 'Welcome ${userName ?? 'Staff'}!';

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
          'Field Staff Login',
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
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.engineering,
                    size: 48,
                    color: Colors.green,
                  ),
                ),

                Text(
                  'Field Staff Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your assigned tasks and update progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                // System Admin Note
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
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

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  style: const TextStyle(color: Colors.black),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'staff@ccmw.gov.pk',
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
                    hintText: 'Enter your password',
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
                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location Permission Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location access is required for task assignment and GPS tracking.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
                    'Login as Field Staff',
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