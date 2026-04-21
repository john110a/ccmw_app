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

  // Form controllers for adding contractor
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _contractValueController = TextEditingController();
  final TextEditingController _performanceBondController = TextEditingController();
  final TextEditingController _performanceScoreController = TextEditingController();
  final TextEditingController _slaComplianceController = TextEditingController();

  DateTime? _selectedContractStart;
  DateTime? _selectedContractEnd;

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
        print('✅ Loaded ${_availableZones.length} zones from database');
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

  // =====================================================
  // FIXED: _assignContractorToZone with validation
  // =====================================================
  Future<void> _assignContractorToZone(String contractorId, String zoneId) async {
    // Validate zoneId
    if (zoneId.isEmpty || zoneId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Invalid zone ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      print('📡 Assigning contractor $contractorId to zone $zoneId');

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

      Navigator.pop(context);
      await _loadZonesOnly();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contractor assigned successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addContractor() async {
    if (_companyNameController.text.isEmpty) {
      _showErrorDialog('Please enter company name');
      return;
    }
    if (_registrationNumberController.text.isEmpty) {
      _showErrorDialog('Please enter registration number');
      return;
    }
    if (_contactPersonController.text.isEmpty) {
      _showErrorDialog('Please enter contact person name');
      return;
    }
    if (_contactPhoneController.text.isEmpty) {
      _showErrorDialog('Please enter contact phone');
      return;
    }
    if (_contactEmailController.text.isEmpty) {
      _showErrorDialog('Please enter contact email');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Please enter password');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }
    if (_selectedContractStart == null) {
      _showErrorDialog('Please select contract start date');
      return;
    }
    if (_selectedContractEnd == null) {
      _showErrorDialog('Please select contract end date');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final requestData = {
        'companyName': _companyNameController.text.trim(),
        'companyRegistrationNumber': _registrationNumberController.text.trim(),
        'contactPersonName': _contactPersonController.text.trim(),
        'contactPersonPhone': _contactPhoneController.text.trim(),
        'email': _contactEmailController.text.trim(),
        'password': _passwordController.text.trim(),
        'companyAddress': _companyAddressController.text.trim(),
        'contractStart': _selectedContractStart!.toIso8601String(),
        'contractEnd': _selectedContractEnd!.toIso8601String(),
        'contractValue': double.tryParse(_contractValueController.text) ?? 0,
        'performanceBond': double.tryParse(_performanceBondController.text) ?? 0,
        'performanceScore': double.tryParse(_performanceScoreController.text) ?? 0,
        'slaComplianceRate': double.tryParse(_slaComplianceController.text) ?? 0,
      };

      await _contractorService.createContractorWithPassword(requestData);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contractor added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _clearContractorForm();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog('Failed to add contractor: $e');
    }
  }

  Future<void> _updateContractor(Contractor contractor) async {
    _companyNameController.text = contractor.companyName;
    _registrationNumberController.text = contractor.companyRegistrationNumber ?? '';
    _contactPersonController.text = contractor.contactPersonName ?? '';
    _contactPhoneController.text = contractor.contactPersonPhone ?? '';
    _contactEmailController.text = contractor.contactEmail ?? '';
    _companyAddressController.text = contractor.companyAddress ?? '';
    _contractValueController.text = contractor.contractValue?.toString() ?? '';
    _performanceBondController.text = contractor.performanceBond?.toString() ?? '';
    _performanceScoreController.text = contractor.performanceScore?.toString() ?? '';
    _slaComplianceController.text = contractor.slaComplianceRate?.toString() ?? '';
    _selectedContractStart = contractor.contractStart;
    _selectedContractEnd = contractor.contractEnd;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contractor'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_companyNameController, 'Company Name', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(_registrationNumberController, 'Registration Number', Icons.numbers),
                const SizedBox(height: 12),
                _buildTextField(_contactPersonController, 'Contact Person', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(_contactPhoneController, 'Phone Number', Icons.phone),
                const SizedBox(height: 12),
                _buildTextField(_contactEmailController, 'Email', Icons.email),
                const SizedBox(height: 12),
                _buildTextField(_companyAddressController, 'Address', Icons.location_on),
                const SizedBox(height: 12),
                _buildDatePicker('Contract Start', _selectedContractStart, (date) {
                  setState(() => _selectedContractStart = date);
                }),
                const SizedBox(height: 12),
                _buildDatePicker('Contract End', _selectedContractEnd, (date) {
                  setState(() => _selectedContractEnd = date);
                }),
                const SizedBox(height: 12),
                _buildTextField(_contractValueController, 'Contract Value (Rs.)', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_performanceBondController, 'Performance Bond (Rs.)', Icons.security, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_performanceScoreController, 'Performance Score (%)', Icons.star, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_slaComplianceController, 'SLA Compliance (%)', Icons.timer, isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final updatedContractor = Contractor(
                  contractorId: contractor.contractorId,
                  companyName: _companyNameController.text.trim(),
                  companyRegistrationNumber: _registrationNumberController.text.trim(),
                  contactPersonName: _contactPersonController.text.trim(),
                  contactPersonPhone: _contactPhoneController.text.trim(),
                  contactEmail: _contactEmailController.text.trim(),
                  companyAddress: _companyAddressController.text.trim(),
                  contractStart: _selectedContractStart!,
                  contractEnd: _selectedContractEnd!,
                  contractValue: double.tryParse(_contractValueController.text) ?? 0,
                  performanceBond: double.tryParse(_performanceBondController.text) ?? 0,
                  performanceScore: double.tryParse(_performanceScoreController.text) ?? 0,
                  slaComplianceRate: double.tryParse(_slaComplianceController.text) ?? 0,
                  isActive: true,
                  createdAt: contractor.createdAt,
                  updatedAt: DateTime.now(),
                );

                await _contractorService.updateContractor(contractor.contractorId, updatedContractor);

                if (!mounted) return;
                Navigator.pop(context);
                await _loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contractor updated successfully'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                _showErrorDialog('Failed to update contractor: $e');
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateContractor(Contractor contractor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Contractor'),
        content: Text('Are you sure you want to deactivate ${contractor.companyName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        await _contractorService.deleteContractor(contractor.contractorId);

        if (!mounted) return;
        Navigator.pop(context);
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${contractor.companyName} deactivated successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorDialog('Failed to deactivate contractor: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearContractorForm() {
    _companyNameController.clear();
    _registrationNumberController.clear();
    _contactPersonController.clear();
    _contactPhoneController.clear();
    _contactEmailController.clear();
    _passwordController.clear();
    _companyAddressController.clear();
    _contractValueController.clear();
    _performanceBondController.clear();
    _performanceScoreController.clear();
    _slaComplianceController.clear();
    _selectedContractStart = null;
    _selectedContractEnd = null;
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      obscureText: label.toLowerCase().contains('password'),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null) onSelected(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(selectedDate != null ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}' : 'Select date'),
      ),
    );
  }

  void _showAddContractorDialog() {
    _clearContractorForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Contractor'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.75,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_companyNameController, 'Company Name', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(_registrationNumberController, 'Registration Number', Icons.numbers),
                const SizedBox(height: 12),
                _buildTextField(_contactPersonController, 'Contact Person', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(_contactPhoneController, 'Phone Number', Icons.phone),
                const SizedBox(height: 12),
                _buildTextField(_contactEmailController, 'Email', Icons.email),
                const SizedBox(height: 12),
                _buildTextField(_passwordController, 'Password', Icons.lock),
                const SizedBox(height: 12),
                _buildTextField(_companyAddressController, 'Address', Icons.location_on),
                const SizedBox(height: 12),
                _buildDatePicker('Contract Start', _selectedContractStart, (date) {
                  setState(() => _selectedContractStart = date);
                }),
                const SizedBox(height: 12),
                _buildDatePicker('Contract End', _selectedContractEnd, (date) {
                  setState(() => _selectedContractEnd = date);
                }),
                const SizedBox(height: 12),
                _buildTextField(_contractValueController, 'Contract Value (Rs.)', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_performanceBondController, 'Performance Bond (Rs.)', Icons.security, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_performanceScoreController, 'Initial Performance Score (%)', Icons.star, isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_slaComplianceController, 'SLA Compliance (%)', Icons.timer, isNumber: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addContractor,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add Contractor'),
          ),
        ],
      ),
    );
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

    return Scaffold(
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
            onPressed: _showAddContractorDialog,
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                            onPressed: () => _updateContractor(contractor),
                            tooltip: 'Edit',
                          ),
                          if (contractor.isActive == true)
                            IconButton(
                              icon: const Icon(Icons.block, size: 20, color: Colors.red),
                              onPressed: () => _deactivateContractor(contractor),
                              tooltip: 'Deactivate',
                            ),
                        ],
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

  // =====================================================
  // FIXED: _showAssignContractorDialog with proper zoneId extraction
  // =====================================================
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

    // Debug: Print zone object to see available keys
    print('🔍 Zone object: $zone');
    print('🔍 Zone keys: ${zone.keys}');

    // Try multiple possible key names for zoneId
    final zoneId = zone['zoneId'] ??
        zone['id'] ??
        zone['ZoneId'] ??
        zone['Id'] ??
        zone['zone_id'];

    final zoneName = zone['zoneName'] ??
        zone['name'] ??
        zone['ZoneName'] ??
        'Zone';

    print('🔍 Extracted Zone ID: $zoneId');
    print('🔍 Zone Name: $zoneName');

    if (zoneId == null || zoneId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid zone data: Zone ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Contractor to $zoneName'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
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
                    _assignContractorToZone(contractor.contractorId, zoneId.toString());
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
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _passwordController.dispose();
    _companyAddressController.dispose();
    _contractValueController.dispose();
    _performanceBondController.dispose();
    _performanceScoreController.dispose();
    _slaComplianceController.dispose();
    super.dispose();
  }
}