import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/user_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final data = await _authService.getAllUserData();
    final userId = await _authService.getUserId();

    if (userId != null) {
      try {
        final user = await _userService.getUserById(userId);
        setState(() {
          _userData = data;
          _nameController.text = user.fullName ?? data['userName'] ?? '';
          _emailController.text = user.email ?? data['userEmail'] ?? '';
          _phoneController.text = user.phoneNumber ?? data['userPhone'] ?? '';
          _cnicController.text = user.cnic ?? data['userCnic'] ?? '';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _userData = data;
          _nameController.text = data['userName'] ?? '';
          _emailController.text = data['userEmail'] ?? '';
          _phoneController.text = data['userPhone'] ?? '';
          _cnicController.text = data['userCnic'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // Update via API
      await _userService.updateUser(userId, {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      });

      // Update local SharedPreferences
      await _authService.updateUserData('user_name', _nameController.text.trim());
      await _authService.updateUserData('user_phone', _phoneController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // 🔥 IMPORTANT: Return true to indicate data was updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle route arguments with type safety
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    if (routeArgs != null && _userData.isEmpty) {
      if (routeArgs is Map<String, dynamic>) {
        _userData = routeArgs;
        _nameController.text = routeArgs['userName']?.toString() ?? '';
        _emailController.text = routeArgs['userEmail']?.toString() ?? '';
        _phoneController.text = routeArgs['userPhone']?.toString() ?? '';
        _cnicController.text = routeArgs['userCnic']?.toString() ?? '';
      } else if (routeArgs is Map) {
        final Map<String, dynamic> castedArgs = {};
        (routeArgs as Map).forEach((key, value) {
          castedArgs[key.toString()] = value;
        });
        _userData = castedArgs;
        _nameController.text = castedArgs['userName']?.toString() ?? '';
        _emailController.text = castedArgs['userEmail']?.toString() ?? '';
        _phoneController.text = castedArgs['userPhone']?.toString() ?? '';
        _cnicController.text = castedArgs['userCnic']?.toString() ?? '';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white, // Keeping your original background color
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Information',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'Save',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              style: const TextStyle(color: Colors.black),
              controller: _nameController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              style: const TextStyle(color: Colors.black),
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Your email address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
                helperText: 'Email cannot be changed',
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              style: const TextStyle(color: Colors.black),
              controller: _phoneController,
              enabled: !_isSaving,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // CNIC (Read-only)
            TextFormField(
              style: const TextStyle(color: Colors.black),
              controller: _cnicController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'CNIC Number',
                hintText: 'Your CNIC number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.badge_outlined),
                helperText: 'CNIC cannot be changed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your personal information is securely stored and only used for verification purposes.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    super.dispose();
  }
}