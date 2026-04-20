import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/dashboard_service.dart';
import '../../services/AuthService.dart';
import '../../models/user_model.dart';
import '../../models/complaint_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DashboardService _dashboardService = DashboardService();
  final AuthService _authService = AuthService();

  // Data variables
  Map<String, dynamic> _dashboardData = {};
  User? _currentUser;
  List<Complaint> _recentComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Statistics
  int _totalComplaints = 0;
  int _resolvedComplaints = 0;
  int _pendingComplaints = 0;
  int _approvedComplaints = 0;

  // User data from SharedPreferences
  String? _userName;
  String? _profilePhoto;
  String? _zoneName;
  String? _badgeLevel;

  // ===== ADDED: Location variables =====
  String? _currentAddress;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUserData();
    _getCurrentLocation(); // ===== ADDED =====
  }

  // ===== ADDED: Get user's current location =====
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services disabled';
          _isLocationLoading = false;
        });
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permission denied';
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Location permissions permanently denied';
          _isLocationLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress = '${place.street}, ${place.locality}';
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Location unavailable';
        _isLocationLoading = false;
      });
      print('Error getting location: $e');
    }
  }

  // Load user data from AuthService
  Future<void> _loadUserData() async {
    _userName = _authService.currentUserName ?? await _authService.getUserName();
    _profilePhoto = _authService.currentProfilePhoto ?? await _authService.getProfilePhoto();
    _zoneName = await _authService.getZoneName();
    _badgeLevel = await _authService.getBadgeLevel();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        _handleLogout();
        return;
      }

      // Load dashboard data from API
      final data = await _dashboardService.getCitizenDashboard(userId);

      setState(() {
        _dashboardData = data;
        _currentUser = User.fromJson(data['User'] ?? {});

        // Extract statistics
        final stats = data['Statistics'] ?? {};
        _totalComplaints = stats['TotalComplaints'] ?? 0;
        _resolvedComplaints = stats['ResolvedComplaints'] ?? 0;
        _pendingComplaints = stats['PendingComplaints'] ?? 0;
        _approvedComplaints = stats['ApprovedComplaints'] ?? 0;

        // Extract recent complaints
        final complaints = data['RecentComplaints'] as List? ?? [];
        _recentComplaints = complaints
            .map((c) => Complaint.fromJson(c))
            .take(3)
            .toList();

        _isLoading = false;
      });
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

  // ===== ADDED: Navigate to notifications screen =====
  void _navigateToNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // ← YOUR ORIGINAL BACKGROUND
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
          ? _buildErrorScreen()
          : _buildHomeContent(),
    );
  }

  // ========== DRAWER (YOUR ORIGINAL CODE - UNCHANGED) ==========
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header with User Info
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: _profilePhoto != null
                              ? NetworkImage(_profilePhoto!)
                              : (_currentUser?.profilePhotoUrl != null
                              ? NetworkImage(_currentUser!.profilePhotoUrl!)
                              : null),
                          child: _profilePhoto == null && _currentUser?.profilePhotoUrl == null
                              ? Text(
                            _userName?[0] ?? _currentUser?.fullName?[0] ?? 'C',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName ?? _currentUser?.fullName ?? 'Citizen',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentUser?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDrawerStat('$_totalComplaints', 'Total'),
                      const VerticalDivider(color: Colors.white30),
                      _buildDrawerStat('$_resolvedComplaints', 'Resolved'),
                      const VerticalDivider(color: Colors.white30),
                      _buildDrawerStat('$_pendingComplaints', 'Pending'),
                    ],
                  ),
                  if (_badgeLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getBadgeIcon(_badgeLevel!),
                              size: 14,
                              color: _getBadgeColor(_badgeLevel!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _badgeLevel!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getBadgeColor(_badgeLevel!),
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

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/home',
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline,
                    label: 'Report Issue',
                    route: '/report-issue',
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment_outlined,
                    label: 'My Complaints',
                    route: '/my-complaints',
                  ),
                  _buildDrawerItem(
                    icon: Icons.map_outlined,
                    label: 'Community Map',
                    route: '/community-map',
                  ),
                  _buildDrawerItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Leaderboard',
                    route: '/leaderboard',
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    label: 'Public Issues',
                    route: '/public-complaints',
                  ),
                  _buildDrawerItem(
                    icon: Icons.check_circle_outline,
                    label: 'Approval Status',
                    route: '/approval-status',
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    route: '/notifications',
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    route: '/profile',
                  ),

                  const Divider(height: 32, thickness: 1),

                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/personal-information',
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    route: '/help-and-support',
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    label: 'About',
                    route: '/about',
                  ),

                  const Divider(height: 32, thickness: 1),

                  // Logout
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for badge
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

  Widget _buildDrawerStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[800],
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route != '/home') {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }

  // ========== LOADING SCREEN (YOUR ORIGINAL) ==========
  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ERROR SCREEN (YOUR ORIGINAL) ==========
  Widget _buildErrorScreen() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Failed to load dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== MAIN HOME CONTENT ==========
  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // App Bar with Gradient - YOUR ORIGINAL (UPDATED with clickable notification)
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF2196F3),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userName?.split(' ').first ??
                                    _currentUser?.fullName?.split(' ').first ??
                                    'Citizen',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // ===== UPDATED: Clickable Notification Badge =====
                          GestureDetector(
                            onTap: _navigateToNotifications,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.notifications,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('$_totalComplaints', 'Total Reports')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('$_resolvedComplaints', 'Resolved')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatCard('$_pendingComplaints', 'Pending')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Body Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Report Issue Button - YOUR ORIGINAL
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/report-issue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Report New Issue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Zone Card with User's Current Location
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue[100]!, width: 1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isLocationLoading ? Icons.location_searching : Icons.location_on,
                          color: const Color(0xFF2196F3),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLocationLoading ? 'Getting location...' : 'Your Location',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentAddress ?? _zoneName ?? 'Unknown location',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!_isLocationLoading)
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.blue[700], size: 20),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Refresh location',
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Title - YOUR ORIGINAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quick Actions Grid - YOUR ORIGINAL
              _buildQuickActionsGrid(),

              const SizedBox(height: 24),

              // Recent Activity Title - YOUR ORIGINAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/my-complaints');
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent Complaints List - YOUR ORIGINAL
              _buildRecentComplaints(),
            ]),
          ),
        ),
      ],
    );
  }

  // ===== YOUR ORIGINAL METHODS (UNCHANGED) =====
  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'icon': Icons.map_outlined, 'label': 'Map', 'route': '/community-map'},
      {'icon': Icons.assignment_outlined, 'label': 'My Complaints', 'route': '/my-complaints'},
      {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'route': '/leaderboard'},
      {'icon': Icons.person_outlined, 'label': 'Profile', 'route': '/profile'},
      {'icon': Icons.people_outlined, 'label': 'Public Issues', 'route': '/public-complaints'},
      {'icon': Icons.check_circle_outlined, 'label': 'Approval Status', 'route': '/approval-status'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          route: action['route'] as String,
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue[50]!,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentComplaints() {
    if (_recentComplaints.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No recent complaints',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Report an issue to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentComplaints.map((complaint) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildComplaintItem(complaint),
        );
      }).toList(),
    );
  }

  Widget _buildComplaintItem(Complaint complaint) {
    return Card(
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/complaint-detail',
            arguments: complaint.complaintId,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: complaint.getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(complaint.currentStatus),
                  color: complaint.getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            complaint.locationAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: complaint.getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            complaint.getStatusString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: complaint.getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(complaint.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 0: return Icons.hourglass_empty;
      case 1: return Icons.visibility;
      case 2: return Icons.check_circle;
      case 3: return Icons.person;
      case 4: return Icons.build;
      case 5: return Icons.done_all;
      case 6: return Icons.verified;
      case 7: return Icons.cancel;
      case 8: return Icons.lock;
      default: return Icons.assignment;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}