import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/contractor_service.dart';
import '../../models/contractor_model.dart';
import '../../config/routes.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() => _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  final AuthService _authService = AuthService();
  final ContractorService _contractorService = ContractorService();

  // Data variables
  Contractor? _contractor;
  List<dynamic> _assignedZones = [];
  List<dynamic> _performanceHistory = [];

  // UI State
  bool _isLoading = true;
  String? _errorMessage;

  // Statistics
  int _totalZones = 0;
  int _totalActiveComplaints = 0;
  int _totalResolvedComplaints = 0;
  double _resolutionRate = 0.0;
  double _avgPerformanceScore = 0.0;
  double _slaComplianceRate = 0.0;
  DateTime? _contractStart;
  DateTime? _contractEnd;
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadContractorDashboard();
  }

  Future<void> _checkAccess() async {
    final isContractor = await _authService.isContractor();
    if (!isContractor && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _loadContractorDashboard() async {
    setState(() => _isLoading = true);

    try {
      final contractorId = await _authService.getContractorId();
      if (contractorId == null) {
        throw Exception('Contractor ID not found');
      }

      final data = await _contractorService.getContractorDashboard(contractorId);

      setState(() {
        // Extract contractor info
        final contractorData = data['Contractor'] ?? {};
        _contractor = Contractor.fromJson(contractorData);

        // Extract statistics
        final stats = data['Statistics'] ?? {};
        _totalZones = stats['TotalZones'] ?? 0;
        _totalActiveComplaints = stats['TotalActiveComplaints'] ?? 0;
        _totalResolvedComplaints = stats['TotalResolvedComplaints'] ?? 0;
        _resolutionRate = (stats['ResolutionRate'] ?? 0.0).toDouble();

        // Extract from contractor
        _avgPerformanceScore = _contractor?.performanceScore?.toDouble() ?? 0.0;
        _slaComplianceRate = _contractor?.slaComplianceRate?.toDouble() ?? 0.0;
        _contractStart = _contractor?.contractStart;
        _contractEnd = _contractor?.contractEnd;

        if (_contractEnd != null) {
          _daysRemaining = _contractEnd!.difference(DateTime.now()).inDays;
          if (_daysRemaining < 0) _daysRemaining = 0;
        }

        // Extract assigned zones
        _assignedZones = data['Zones'] ?? [];

        // Extract performance history
        _performanceHistory = data['RecentPerformance'] ?? [];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getPerformanceColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading contractor dashboard...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadContractorDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _contractor?.companyName ?? 'Contractor Dashboard',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadContractorDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Company Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business_center,
                          size: 40,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _contractor?.companyName ?? 'Company Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${_contractor?.contractorId?.substring(0, 8) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCompanyStat('$_totalZones', 'Zones', Icons.location_city),
                      _buildCompanyStat('${_avgPerformanceScore.toStringAsFixed(1)}%', 'Performance', Icons.trending_up),
                      _buildCompanyStat('$_totalActiveComplaints', 'Active Tasks', Icons.assignment),
                    ],
                  ),
                ],
              ),
            ),

            // Contract Info Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contract Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'SLA Compliance',
                              '${_slaComplianceRate.toStringAsFixed(1)}%',
                              Icons.timer,
                              _slaComplianceRate >= 90 ? Colors.green : Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Resolution Rate',
                              '${_resolutionRate.toStringAsFixed(1)}%',
                              Icons.check_circle,
                              _resolutionRate >= 80 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Start Date',
                              _formatDate(_contractStart),
                              Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'End Date',
                              _formatDate(_contractEnd),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      if (_daysRemaining > 0) ...[
                        const Divider(height: 24),
                        LinearProgressIndicator(
                          value: _daysRemaining / 365,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _daysRemaining < 30 ? Colors.orange : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_daysRemaining days remaining in contract',
                          style: TextStyle(
                            fontSize: 12,
                            color: _daysRemaining < 30 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildQuickActionCard(
                        icon: Icons.assignment,
                        label: 'View Tasks',
                        color: Colors.blue,
                        onTap: () => Navigator.pushNamed(context, '/contractor-tasks'),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionCard(
                        icon: Icons.photo_camera,
                        label: 'Upload Photos',
                        color: Colors.green,
                        onTap: () => Navigator.pushNamed(context, '/contractor-photos'),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionCard(
                        icon: Icons.description,
                        label: 'Reports',
                        color: Colors.orange,
                        onTap: () => Navigator.pushNamed(context, '/contractor-reports'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Assigned Zones Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Assigned Zones ($_totalZones)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _assignedZones.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No zones assigned'),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _assignedZones.length,
                    itemBuilder: (context, index) {
                      return _buildZoneCard(_assignedZones[index]);
                    },
                  ),
                ],
              ),
            ),

            // Performance History
            if (_performanceHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _performanceHistory.length,
                            itemBuilder: (context, index) {
                              final history = _performanceHistory[index];
                              final score = (history['performanceScore'] ?? 0).toDouble();
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getPerformanceColor(score).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${score.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getPerformanceColor(score),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      history['reviewPeriodEnd']?.toString().substring(0, 7) ?? '',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.assignment, color: Colors.grey),
              onPressed: () => Navigator.pushNamed(context, '/contractor-tasks'),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.grey),
              onPressed: () => Navigator.pushNamed(context, '/contractor-photos'),
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.grey),
              onPressed: () => Navigator.pushNamed(context, '/contractor-profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final activeComplaints = zone['activeComplaints'] ?? 0;
    final performance = zone['performance'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.contractorZoneDetails,
            arguments: zone,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      zone['zoneName'] ?? 'Unknown Zone',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeComplaints > 20
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeComplaints Active',
                      style: TextStyle(
                        fontSize: 10,
                        color: activeComplaints > 20 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    zone['serviceType'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    zone['city'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          '$activeComplaints',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resolved', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          '${zone['resolvedComplaints'] ?? 0}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Performance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          '$performance%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getPerformanceColor(performance.toDouble()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}