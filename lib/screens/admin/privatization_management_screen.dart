// lib/screens/admin/privatization_management_screen.dart
import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/contractor_service.dart';
import '../../models/contractor_model.dart';

class PrivatizationManagementScreen extends StatefulWidget {
  const PrivatizationManagementScreen({super.key});

  @override
  State<PrivatizationManagementScreen> createState() => _PrivatizationManagementScreenState();
}

class _PrivatizationManagementScreenState extends State<PrivatizationManagementScreen> with SingleTickerProviderStateMixin {
  final ContractorService _contractorService = ContractorService();
  final AuthService _authService = AuthService();

  List<Contractor> _contractors = [];
  List<Map<String, dynamic>> _availableZones = [];
  bool _isLoading = true;
  bool _isLoadingZones = false;
  String? _errorMessage;
  String? _zonesErrorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading contractors and available zones...');

      // Load contractors and zones in parallel
      final results = await Future.wait([
        _contractorService.getAllContractors().catchError((e) {
          print('❌ Error loading contractors: $e');
          return <Contractor>[];
        }),
        _contractorService.getAvailableZones().catchError((e) {
          print('❌ Error loading zones: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      if (mounted) {
        setState(() {
          _contractors = results[0] as List<Contractor>;
          _availableZones = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });

        print('✅ Loaded ${_contractors.length} contractors');
        print('✅ Loaded ${_availableZones.length} available zones');
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadZonesOnly() async {
    setState(() {
      _isLoadingZones = true;
      _zonesErrorMessage = null;
    });

    try {
      final zones = await _contractorService.getAvailableZones();
      if (mounted) {
        setState(() {
          _availableZones = List<Map<String, dynamic>>.from(zones);
          _isLoadingZones = false;
        });
      }
    } catch (e) {
      print('❌ Error loading zones: $e');
      if (mounted) {
        setState(() {
          _zonesErrorMessage = e.toString();
          _isLoadingZones = false;
        });
      }
    }
  }

  Future<void> _assignContractorToZone(String contractorId, String zoneId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      await _contractorService.assignContractorToZone(
        contractorId: contractorId,
        zoneId: zoneId,
        assignedBy: userId,
        contractStart: DateTime.now(),
        contractEnd: DateTime.now().add(const Duration(days: 365)),
        serviceType: 'Garbage Collection',
        contractValue: 1000000,
        performanceBond: 50000,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Refresh zones only
      await _loadZonesOnly();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contractor assigned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Privatization Management'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Privatization Management'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Privatization Management'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: () => _showAddContractorDialog(),
              tooltip: 'Add Contractor',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Contractors'),
              Tab(text: 'Zone Assignments'),
              Tab(text: 'Active Tenders'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContractorsTab(),
            _buildZoneAssignmentsTab(),
            _buildTendersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildContractorsTab() {
    if (_contractors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No contractors found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a contractor to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddContractorDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contractor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contractors.length,
      itemBuilder: (context, index) {
        final contractor = _contractors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _showContractorDetails(contractor),
            borderRadius: BorderRadius.circular(12),
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
                          contractor.companyName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (contractor.isActive ?? true) ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (contractor.isActive ?? true) ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: (contractor.isActive ?? true) ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contractor.contactPersonName ?? 'No contact person',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        contractor.contactPersonPhone ?? 'No phone',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contractor.contactEmail ?? 'No email',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Performance: ${contractor.performanceScore?.toStringAsFixed(1) ?? '0'}%',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${contractor.contractorId.substring(0, 8)}...',
                          style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (contractor.performanceScore ?? 0) / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (contractor.performanceScore ?? 0) >= 90
                          ? Colors.green
                          : (contractor.performanceScore ?? 0) >= 70
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoneAssignmentsTab() {
    if (_isLoadingZones) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_zonesErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_zonesErrorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadZonesOnly,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableZones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No zones available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'All zones may already have contractors assigned',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadZonesOnly,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadZonesOnly,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableZones.length,
        itemBuilder: (context, index) {
          final zone = _availableZones[index];
          final hasContractor = zone['hasContractor'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasContractor ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: hasContractor ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone['zoneName'] ?? 'Unknown Zone',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Zone #${zone['zoneNumber'] ?? 'N/A'} • ${zone['city'] ?? 'City'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Active Complaints: ${zone['activeComplaints'] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (_contractors.isEmpty)
                        const Text(
                          'No contractors available',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _showAssignContractorDialog(zone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasContractor ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(hasContractor ? 'Reassign' : 'Assign'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTendersTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tenders Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showContractorDetails(Contractor contractor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
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
                  contractor.companyName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (contractor.isActive ?? true) ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (contractor.isActive ?? true) ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: (contractor.isActive ?? true) ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('Contractor ID', contractor.contractorId),
                      _buildDetailRow('Registration #', contractor.companyRegistrationNumber ?? 'N/A'),
                      _buildDetailRow('Contact Person', contractor.contactPersonName ?? 'N/A'),
                      _buildDetailRow('Phone', contractor.contactPersonPhone ?? 'N/A'),
                      _buildDetailRow('Email', contractor.contactEmail ?? 'N/A'),
                      _buildDetailRow('Address', contractor.companyAddress ?? 'N/A'),
                      const SizedBox(height: 16),
                      const Text(
                        'Contract Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Start Date', _formatDate(contractor.contractStart)),
                      _buildDetailRow('End Date', _formatDate(contractor.contractEnd)),
                      _buildDetailRow('Contract Value', 'Rs. ${contractor.contractValue?.toStringAsFixed(0) ?? '0'}'),
                      _buildDetailRow('Performance Bond', 'Rs. ${contractor.performanceBond?.toStringAsFixed(0) ?? '0'}'),
                      _buildDetailRow('Performance Score', '${contractor.performanceScore?.toStringAsFixed(1) ?? '0'}%'),
                      _buildDetailRow('SLA Compliance', '${contractor.slaComplianceRate?.toStringAsFixed(1) ?? '0'}%'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddContractorDialog() {
    // This would be implemented to add new contractors
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add contractor feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAssignContractorDialog(Map<String, dynamic> zone) {
    if (_contractors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contractors available to assign'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Contractor to ${zone['zoneName']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: _contractors.isEmpty
              ? const Center(child: Text('No contractors available'))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: _contractors.length,
            itemBuilder: (context, index) {
              final contractor = _contractors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(contractor.companyName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact: ${contractor.contactPersonName ?? 'N/A'}'),
                      Text('Performance: ${contractor.performanceScore?.toStringAsFixed(1) ?? '0'}%'),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: (contractor.isActive ?? true) ? Colors.green[100] : Colors.red[100],
                    child: Icon(
                      Icons.business,
                      color: (contractor.isActive ?? true) ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _assignContractorToZone(contractor.contractorId, zone['zoneId']);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}