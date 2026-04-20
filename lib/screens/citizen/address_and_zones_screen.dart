import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/zone_service.dart';
import '../../models/zone_model.dart';

class AddressAndZonesScreen extends StatefulWidget {
  const AddressAndZonesScreen({super.key});

  @override
  State<AddressAndZonesScreen> createState() => _AddressAndZonesScreenState();
}

class _AddressAndZonesScreenState extends State<AddressAndZonesScreen> {
  final AuthService _authService = AuthService();
  final ZoneService _zoneService = ZoneService();

  final _addressController = TextEditingController();

  List<Zone> _zones = [];
  String? _selectedZoneId;
  String? _currentZoneName;
  String? _currentAddress;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load zones from API
      final zones = await _zoneService.getAllZones();

      // Load user data from SharedPreferences
      final userData = await _authService.getAllUserData();

      setState(() {
        _zones = zones;
        _currentZoneName = userData['zoneName'];
        _currentAddress = userData['userAddress'];
        _addressController.text = userData['userAddress'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // Update address in SharedPreferences
      await _authService.updateUserData('user_address', _addressController.text.trim());

      // If zone changed, update zone
      if (_selectedZoneId != null) {
        final selectedZone = _zones.firstWhere((z) => z.zoneId == _selectedZoneId);
        await _authService.updateUserData('zone_id', _selectedZoneId!);
        await _authService.updateUserData('zone_name', selectedZone.zoneName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Address & Zones'),
        centerTitle: true,
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
                color: Color(0xFF2196F3),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCurrentZoneCard(),
            const SizedBox(height: 16),
            _buildAddressCard(),
            const SizedBox(height: 16),
            _buildZoneSelectorCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentZoneCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_city,
                color: Color(0xFF2196F3),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Current Zone',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentZoneName ?? 'Not assigned',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
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

  Widget _buildAddressCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              style: TextStyle(color: Colors.black),
              controller: _addressController,
              maxLines: 3,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: 'Enter your complete address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.location_on_outlined, color: Color(0xFF2196F3)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelectorCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select your residential zone',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF2196F3)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              hint: const Text('Select Zone'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Keep current zone --'),
                ),
                ..._zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone.zoneId,
                    child: Text(zone.zoneName),
                  );
                }),
              ],
              onChanged: !_isSaving
                  ? (value) => setState(() => _selectedZoneId = value)
                  : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changing your zone will affect which complaints you see and where you can report issues.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                        height: 1.4,
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

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
