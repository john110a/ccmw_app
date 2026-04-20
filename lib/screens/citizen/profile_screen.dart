import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Map<String, dynamic> _userData = {};
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load from SharedPreferences first
      final localData = await _authService.getAllUserData();

      // Get fresh data from API
      final userId = await _authService.getUserId();
      if (userId != null) {
        final apiUser = await _userService.getUserById(userId);

        setState(() {
          _user = apiUser;
          _userData = localData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData = localData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your data will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement account deletion API
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getMemberSince() {
    if (_user?.createdAt != null) {
      final months = DateTime.now().difference(_user!.createdAt).inDays ~/ 30;
      if (months < 1) return 'Member this month';
      return 'Member since ${months} month${months > 1 ? 's' : ''} ago';
    }
    return 'Member since Oct 2024'; // fallback
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
          'My Profile',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadUserData,
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
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue[300]!,
                        width: 3,
                      ),
                    ),
                    child: _userData['profilePhoto'] != null
                        ? ClipOval(
                      child: Image.network(
                        _userData['profilePhoto'],
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      _userData['userName']?[0]?.toUpperCase() ??
                          _user?.fullName?[0]?.toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _userData['userName'] ?? _user?.fullName ?? 'Ahmad Ali',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData['userEmail'] ?? _user?.email ?? 'ahmad.ali@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMemberSince(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                          '${_userData['totalComplaints'] ?? 12}',
                          'Reports'
                      ),
                      _buildStatItem(
                          '${_userData['totalUpvotes'] ?? 45}',
                          'Upvotes'
                      ),
                      _buildStatItem(
                          '${_userData['resolvedComplaints'] ?? 8}',
                          'Resolved'
                      ),
                    ],
                  ),

                  // Badge Level
                  if (_userData['badgeLevel'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(_userData['badgeLevel']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getBadgeIcon(_userData['badgeLevel']),
                              color: _getBadgeColor(_userData['badgeLevel']),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _userData['badgeLevel'],
                              style: TextStyle(
                                color: _getBadgeColor(_userData['badgeLevel']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // ===== FIXED: Personal Information with async navigation =====
                  _buildListTile(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    onTap: () async {
                      // Navigate and wait for result
                      final result = await Navigator.pushNamed(
                          context,
                          '/personal-information'
                      );

                      // If data was updated, refresh the profile
                      if (result == true) {
                        _loadUserData();
                      }
                    },
                  ),
                  _buildListTile(
                    icon: Icons.location_on_outlined,
                    title: 'Address & Zones',
                    subtitle: _userData['zoneName'] ?? 'Zone not set',
                    onTap: () {
                      Navigator.pushNamed(context, '/address-and-zones');
                    },
                  ),
                  _buildListTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, '/notification-settings');
                    },
                  ),
                  _buildListTile(
                    icon: Icons.security_outlined,
                    title: 'Privacy & Security',
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy-and-security');
                    },
                  ),
                  _buildListTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pushNamed(context, '/help-and-support');
                    },
                  ),
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: 'About CCMW',
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  // Feedback option
                  _buildListTile(
                    icon: Icons.rate_review,
                    title: 'Feedback',
                    onTap: () {
                      Navigator.pushNamed(context, '/feedback');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    titleColor: Colors.red,
                    onTap: _showLogoutDialog,
                  ),
                  _buildListTile(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: titleColor ?? Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: titleColor ?? Colors.grey[900],
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold': return Icons.emoji_events;
      case 'silver': return Icons.workspace_premium;
      case 'bronze': return Icons.military_tech;
      default: return Icons.star;
    }
  }

  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      case 'bronze': return Colors.brown;
      default: return Colors.blue;
    }
  }
}