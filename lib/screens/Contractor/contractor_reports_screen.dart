import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/contractor_service.dart';
import '../../services/authservice.dart';

class ContractorReportsScreen extends StatefulWidget {
  const ContractorReportsScreen({super.key});

  @override
  State<ContractorReportsScreen> createState() => _ContractorReportsScreenState();
}

class _ContractorReportsScreenState extends State<ContractorReportsScreen> {
  final ContractorService _contractorService = ContractorService();
  final AuthService _authService = AuthService();

  List<dynamic> _performanceHistory = [];
  Map<String, dynamic> _performanceSummary = {};
  bool _isLoading = true;
  String? _contractorId;
  String? _errorMessage;
  String _selectedPeriod = '6months'; // 6months, 1year, all

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _contractorId = await _authService.getContractorId();
      if (_contractorId == null) {
        throw Exception('Contractor ID not found');
      }

      final dashboard = await _contractorService.getContractorDashboard(_contractorId!);

      setState(() {
        _performanceSummary = dashboard['Statistics'] ?? {};
        _performanceHistory = dashboard['RecentPerformance'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _getPerformanceSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _performanceHistory.length; i++) {
      final score = _performanceHistory[i]['performanceScore']?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), score));
    }
    return spots;
  }

  List<FlSpot> _getSLASpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _performanceHistory.length; i++) {
      final sla = _performanceHistory[i]['slaComplianceRate']?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), sla));
    }
    return spots;
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Performance Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${report['reviewPeriodStart']?.toString().substring(0, 10)} - ${report['reviewPeriodEnd']?.toString().substring(0, 10)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildReportCard(
                      'Complaints Overview',
                      [
                        'Assigned: ${report['complaintsAssigned'] ?? 0}',
                        'Resolved: ${report['complaintsResolved'] ?? 0}',
                        'On Time: ${report['resolvedOnTime'] ?? 0}',
                      ],
                      Icons.assignment,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildReportCard(
                      'SLA Compliance',
                      [
                        'Rate: ${report['slaComplianceRate']?.toStringAsFixed(1) ?? 0}%',
                        'Citizen Rating: ${report['citizenRating']?.toStringAsFixed(1) ?? 0}/5',
                      ],
                      Icons.speed,
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildReportCard(
                      'Performance Score',
                      [
                        'Score: ${report['performanceScore']?.toStringAsFixed(1) ?? 0}%',
                        'Penalties: PKR ${report['penaltiesAmount']?.toStringAsFixed(0) ?? 0}',
                        'Bonuses: PKR ${report['bonusAmount']?.toStringAsFixed(0) ?? 0}',
                      ],
                      Icons.trending_up,
                      Colors.orange,
                    ),
                    if (report['reviewNotes'] != null) ...[
                      const SizedBox(height: 16),
                      _buildReportCard(
                        'Review Notes',
                        [report['reviewNotes']],
                        Icons.note,
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, List<String> details, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(detail, style: const TextStyle(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Performance Reports'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Performance Reports'),
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Performance Reports'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Performance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(_performanceSummary['resolutionRate'] ?? 0).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Resolution Rate', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_performanceSummary['totalZones'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Zones Managed', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_performanceSummary['totalActiveComplaints'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Active', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${_performanceSummary['totalResolvedComplaints'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Resolved', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_performanceHistory.isNotEmpty ? _performanceHistory.first['performanceScore']?.toStringAsFixed(0) ?? '0' : '0'}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Current Score', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Performance Chart
              if (_performanceHistory.isNotEmpty) ...[
                const Text(
                  'Performance Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < _performanceHistory.length) {
                                      return Text(
                                        _performanceHistory[index]['reviewPeriodEnd']
                                            ?.toString().substring(5, 7) ?? '',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getPerformanceSpots(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Performance Score Trend (Last 6 months)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // SLA Compliance Chart
              if (_performanceHistory.isNotEmpty) ...[
                const Text(
                  'SLA Compliance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < _performanceHistory.length) {
                                      return Text(
                                        _performanceHistory[index]['reviewPeriodEnd']
                                            ?.toString().substring(5, 7) ?? '',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getSLASpots(),
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('SLA Compliance Trend', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Performance History List
              const Text(
                'Performance History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_performanceHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No performance records found'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _performanceHistory.length,
                  itemBuilder: (context, index) {
                    final report = _performanceHistory[index];
                    final score = (report['performanceScore'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _showReportDetails(report),
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
                                    decoration: BoxDecoration(
                                      color: score >= 80 ? Colors.green[100] : score >= 60 ? Colors.orange[100] : Colors.red[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      score >= 80 ? Icons.trending_up : score >= 60 ? Icons.warning : Icons.trending_down,
                                      color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${report['reviewPeriodStart']?.toString().substring(0, 7)} - ${report['reviewPeriodEnd']?.toString().substring(0, 7)}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Complaints: ${report['complaintsAssigned'] ?? 0} assigned, ${report['complaintsResolved'] ?? 0} resolved',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${score.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (report['slaComplianceRate'] ?? 0) >= 90 ? Colors.green[50] : Colors.red[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'SLA: ${report['slaComplianceRate']?.toStringAsFixed(0) ?? 0}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: (report['slaComplianceRate'] ?? 0) >= 90 ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: score / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}