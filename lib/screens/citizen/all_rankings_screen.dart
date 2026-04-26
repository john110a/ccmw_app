// lib/screens/citizen/all_rankings_screen.dart

import 'package:flutter/material.dart';
import '../../services/leaderboard_service.dart';

class AllRankingsScreen extends StatefulWidget {
  const AllRankingsScreen({super.key});

  @override
  State<AllRankingsScreen> createState() => _AllRankingsScreenState();
}

class _AllRankingsScreenState extends State<AllRankingsScreen> with SingleTickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();

  late TabController _tabController;
  List<dynamic> _citizenLeaderboard = [];
  List<dynamic> _departmentLeaderboard = [];
  List<dynamic> _zoneLeaderboard = [];
  List<dynamic> _staffLeaderboard = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'all';

  final List<String> _periods = ['weekly', 'monthly', 'all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _leaderboardService.getCitizenLeaderboard(period: _selectedPeriod, top: 50),
        _leaderboardService.getDepartmentLeaderboard(),
        _leaderboardService.getZoneLeaderboard(),
        _leaderboardService.getStaffLeaderboard(),
      ]);

      setState(() {
        _citizenLeaderboard = results[0];
        _departmentLeaderboard = results[1];
        _zoneLeaderboard = results[2];
        _staffLeaderboard = results[3];
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadAllData();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[800]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.orange[800]!;
      default:
        return Colors.blue;
    }
  }

  Color _getPerformanceColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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
          'All Rankings',
          style: TextStyle(color: Colors.grey[900]),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Citizens', icon: Icon(Icons.people)),
            Tab(text: 'Departments', icon: Icon(Icons.business)),
            Tab(text: 'Zones', icon: Icon(Icons.location_city)),
            Tab(text: 'Staff', icon: Icon(Icons.engineering)),
          ],
        ),
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
              onPressed: _loadAllData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCitizensTab(),
          _buildDepartmentsTab(),
          _buildZonesTab(),
          _buildStaffTab(),
        ],
      ),
    );
  }

  Widget _buildCitizensTab() {
    if (_citizenLeaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No citizen data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _periods.map((period) {
              final isSelected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    period[0].toUpperCase() + period.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _changePeriod(period),
                  backgroundColor: Colors.white,
                  selectedColor: Colors.blue[700],
                  checkmarkColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _citizenLeaderboard.length,
            itemBuilder: (context, index) {
              final citizen = _citizenLeaderboard[index];
              final rank = citizen['Rank'] ?? index + 1;
              final name = citizen['FullName'] ?? 'Unknown';
              final score = citizen['ContributionScore'] ?? 0;
              final reports = citizen['ApprovedComplaints'] ?? 0;
              final resolved = citizen['ResolvedComplaints'] ?? 0;
              final badge = citizen['BadgeLevel'] ?? 'Newcomer';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _getRankColor(rank),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPerformanceColor(score.toDouble()).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getPerformanceColor(score.toDouble()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$score pts',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.report, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$reports reports',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$resolved resolved',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (rank <= 3)
                        Icon(
                          Icons.emoji_events,
                          color: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.orange),
                          size: 32,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentsTab() {
    if (_departmentLeaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No department data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _departmentLeaderboard.length,
      itemBuilder: (context, index) {
        final dept = _departmentLeaderboard[index];
        final name = dept['DepartmentName'] ?? 'Unknown';
        final performance = (dept['PerformanceScore'] ?? 0).toDouble();
        final resolutionRate = (dept['ResolutionRate'] ?? 0).toDouble();
        final avgTime = dept['AverageResolutionTimeDays'] ?? 0;
        final activeComplaints = dept['ActiveComplaints'] ?? 0;
        final privatizationStatus = dept['PrivatizationStatus'] ?? 'Public';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(performance).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: _getPerformanceColor(performance),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: privatizationStatus == 'Public'
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              privatizationStatus,
                              style: TextStyle(
                                fontSize: 10,
                                color: privatizationStatus == 'Public'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Performance',
                        '${performance.toStringAsFixed(1)}%',
                        _getPerformanceColor(performance),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Resolution Rate',
                        '${resolutionRate.toStringAsFixed(1)}%',
                        _getPerformanceColor(resolutionRate),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Avg. Time',
                        '${avgTime.toStringAsFixed(1)} days',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Active',
                        '$activeComplaints',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: performance / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(performance),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZonesTab() {
    if (_zoneLeaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No zone data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _zoneLeaderboard.length,
      itemBuilder: (context, index) {
        final zone = _zoneLeaderboard[index];
        final name = zone['ZoneName'] ?? 'Unknown';
        final zoneCode = zone['ZoneCode'] ?? '';
        final city = zone['City'] ?? 'City';
        final resolutionRate = (zone['ResolutionRate'] ?? 0).toDouble();
        final activeComplaints = zone['ActiveComplaints'] ?? 0;
        final totalComplaints = zone['TotalComplaints'] ?? 0;
        final rating = zone['PerformanceRating'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_city,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$zoneCode • $city',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(resolutionRate).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rating,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getPerformanceColor(resolutionRate),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Resolution Rate',
                        '${resolutionRate.toStringAsFixed(1)}%',
                        _getPerformanceColor(resolutionRate),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Active',
                        '$activeComplaints',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Total',
                        '$totalComplaints',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: resolutionRate / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(resolutionRate),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffTab() {
    if (_staffLeaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.engineering_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No staff data available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffLeaderboard.length,
      itemBuilder: (context, index) {
        final staff = _staffLeaderboard[index];
        final name = staff['FullName'] ?? 'Unknown';
        final department = staff['DepartmentName'] ?? 'N/A';
        final role = staff['Role'] ?? 'Field Staff';
        final performance = (staff['PerformanceScore'] ?? 0).toDouble();
        final completionRate = (staff['CompletionRate'] ?? 0).toDouble();
        final completed = staff['CompletedAssignments'] ?? 0;
        final total = staff['TotalAssignments'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getPerformanceColor(performance).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.engineering,
                        color: _getPerformanceColor(performance),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$department • $role',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Performance',
                        '${performance.toStringAsFixed(1)}%',
                        _getPerformanceColor(performance),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Completion',
                        '${completionRate.toStringAsFixed(1)}%',
                        _getPerformanceColor(completionRate),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Tasks',
                        '$completed/$total',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: performance / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(performance),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}