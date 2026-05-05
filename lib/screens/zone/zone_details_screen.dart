import 'package:flutter/material.dart';

class ZoneDetailsScreen extends StatelessWidget {
  const ZoneDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final zone = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    // Handle both PascalCase (backend) and camelCase (frontend) property names
    final zoneName = zone['ZoneName'] ?? zone['zoneName'] ?? 'Unknown Zone';
    final activeComplaints = (zone['ActiveComplaints'] ?? zone['activeComplaints'] ?? 0) as int;
    final resolvedComplaints = (zone['ResolvedComplaints'] ?? zone['resolvedComplaints'] ?? 0) as int;
    final zoneNumber = zone['ZoneNumber']?.toString() ?? zone['zoneNumber']?.toString() ?? 'N/A';
    final city = zone['City'] ?? zone['city'] ?? 'N/A';
    final province = zone['Province'] ?? zone['province'] ?? 'N/A';
    final serviceType = zone['ServiceType'] ?? zone['serviceType'] ?? 'N/A';
    final hasContractor = zone['hasContractor'] ?? zone['HasContractor'] ?? false;
    final assignmentId = zone['AssignmentId']?.toString() ?? zone['assignmentId']?.toString() ?? '';
    final contractStart = zone['ContractStart'] ?? zone['contractStart'];
    final contractEnd = zone['ContractEnd'] ?? zone['contractEnd'];
    final contractValue = zone['ContractValue'] ?? zone['contractValue'];
    final performanceBond = zone['PerformanceBond'] ?? zone['performanceBond'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          zoneName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh logic
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Zone Stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildZoneStat('$activeComplaints', 'Active', Icons.pending),
                  _buildZoneStat(zoneNumber.toString(), 'Zone #', Icons.map),
                  _buildZoneStat(hasContractor ? 'Yes' : 'No', 'Contractor', Icons.business),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zone Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Zone Name', zoneName),
                          _buildInfoRow('Zone Number', zoneNumber.toString()),
                          _buildInfoRow('City', city),
                          _buildInfoRow('Province', province),
                          _buildInfoRow('Service Type', serviceType),
                          _buildInfoRow(
                            'Contractor Assigned',
                            hasContractor ? 'Yes' : 'No',
                            valueColor: hasContractor ? Colors.green : Colors.red,
                          ),
                          _buildInfoRow(
                            'Active Complaints',
                            '$activeComplaints',
                            valueColor: activeComplaints > 0 ? Colors.orange : Colors.green,
                          ),
                          if (resolvedComplaints > 0)
                            _buildInfoRow(
                              'Resolved Complaints',
                              '$resolvedComplaints',
                              valueColor: Colors.green,
                            ),
                          if (contractValue != null)
                            _buildInfoRow('Contract Value', 'Rs. ${_formatNumber(contractValue)}'),
                          if (performanceBond != null)
                            _buildInfoRow('Performance Bond', 'Rs. ${_formatNumber(performanceBond)}'),
                          if (contractStart != null)
                            _buildInfoRow('Contract Start', _formatDate(contractStart)),
                          if (contractEnd != null)
                            _buildInfoRow('Contract End', _formatDate(contractEnd)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Active Complaints Section
                  const Text(
                    'Active Complaints',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (activeComplaints == 0)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, size: 48, color: Colors.green),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Complaints',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This zone is currently complaint-free!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                  // This would be populated with actual complaints from API
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeComplaints,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red[100],
                              child: const Icon(Icons.warning, color: Colors.red, size: 16),
                            ),
                            title: Text('Complaint #${index + 1}'),
                            subtitle: const Text('Status: Pending'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Navigate to complaint details
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('View'),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Upload photos logic
                            _showMessage(context, 'Upload Photos feature coming soon');
                          },
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Upload Photos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Generate report logic
                            _showReportDialog(context, zoneName, activeComplaints, resolvedComplaints);
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('Generate Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // View All Complaints Button
                  if (activeComplaints > 0)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showMessage(context, 'View all complaints feature coming soon');
                        },
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View All Complaints'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      }
    } catch (e) {
      return date.toString();
    }
    return 'N/A';
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    try {
      final num value = number is num ? number : num.parse(number.toString());
      return value.toStringAsFixed(2);
    } catch (e) {
      return number.toString();
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showReportDialog(BuildContext context, String zoneName, int activeComplaints, int resolvedComplaints) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zone: $zoneName'),
              const SizedBox(height: 8),
              Text('Active Complaints: $activeComplaints'),
              Text('Resolved Complaints: $resolvedComplaints'),
              if (activeComplaints + resolvedComplaints > 0)
                Text(
                  'Resolution Rate: ${((resolvedComplaints / (activeComplaints + resolvedComplaints)) * 100).toStringAsFixed(1)}%',
                ),
              const SizedBox(height: 16),
              const Text('Report will be generated for:'),
              const SizedBox(height: 8),
              const Text('• Current zone status'),
              const Text('• Active complaints summary'),
              const Text('• Performance metrics'),
              const Text('• Resolution timeline'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report generation started')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }
}