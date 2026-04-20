// lib/screens/Contractor/ContractorLoginScreen.dart
import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../config/routes.dart';

class ContractorLoginScreen extends StatefulWidget {
  const ContractorLoginScreen({super.key});

  @override
  State<ContractorLoginScreen> createState() => _ContractorLoginScreenState();
}

class _ContractorLoginScreenState extends State<ContractorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Use staff login endpoint for contractors
        final response = await _authService.staffLogin(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        // DEBUG: Print the full response to see what keys are available
        print('🔍 FULL API RESPONSE: $response');
        print('🔍 Response keys: ${response.keys}');

        // FIXED: Check multiple possible key names for userType (case-sensitive)
        String? userType = response['userType']?.toString().toLowerCase() ??
            response['UserType']?.toString().toLowerCase() ??
            response['type']?.toString().toLowerCase() ??
            response['role']?.toString().toLowerCase();

        print('📋 Detected UserType: $userType');

        if (userType != 'contractor') {
          throw Exception('Invalid contractor account. Please use contractor credentials. (Detected role: $userType)');
        }

        // FIXED: Try multiple key names for contractor ID
        final contractorId = response['UserId']?.toString() ??
            response['userId']?.toString() ??
            response['id']?.toString() ??
            response['Id']?.toString() ??
            response['contractorId']?.toString() ??
            response['staffId']?.toString() ??
            '';

        print('📋 Contractor ID: $contractorId');

        if (contractorId.isEmpty) {
          throw Exception('Could not retrieve contractor ID from response');
        }

        // FIXED: Try multiple key names for company name
        final companyName = response['fullName'] ??
            response['FullName'] ??
            response['companyName'] ??
            response['CompanyName'] ??
            response['name'] ??
            response['Name'] ??
            response['businessName'] ??
            'Contractor';

        print('📋 Company Name: $companyName');

        // Navigate to contractor dashboard
        Navigator.pushReplacementNamed(
          context,
          Routes.contractorDashboard,
          arguments: {
            'contractorId': contractorId,
            'companyName': companyName,
          },
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome $companyName!'),
            backgroundColor: Colors.green,
          ),
        );

      } catch (e) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        print('❌ Login error: $errorMessage');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
          'Contractor Login',
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

                // Contractor Icon
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business_center,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),

                Text(
                  'Contractor Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your assigned zones and contracts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Company Email',
                    hintText: 'contact@company.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.black),
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                    'Login as Contractor',
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
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
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