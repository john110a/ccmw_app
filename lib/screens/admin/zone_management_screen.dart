import 'package:flutter/material.dart';
import 'zone_drawing_screen.dart';
import '../../services/zone_service.dart';
import '../../models/zone_model.dart';

class ZoneManagementScreen extends StatefulWidget {
  const ZoneManagementScreen({super.key});

  @override
  State<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends State<ZoneManagementScreen> {
  final ZoneService _zoneService = ZoneService();

  List<Zone> _zones = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() => _isLoading = true);
    try {
      final zones = await _zoneService.getAllZones();
      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatZoneData(Zone zone, String field) {
    switch (field) {
      case 'area':
      // FIXED: Added null check for totalAreaSqKm
        if (zone.totalAreaSqKm != null) {
          return '${zone.totalAreaSqKm!.toStringAsFixed(1)} sq km';
        }
        return 'N/A';
      case 'population':
        return zone.population?.toString() ?? '0';
      case 'staffCount':
        return '0'; // You'll need to calculate this from API
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'Zone Management',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
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
            'Zone Management',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadZones,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
          'Zone Management',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ZoneDrawingScreen()),
              ).then((_) => _loadZones());
            },
            tooltip: 'Draw New Zone on Map',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () => _addNewZone(),
            tooltip: 'Add Zone Manually',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadZones,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildZoneStat('${_zones.length}', 'Total Zones', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildZoneStat(
                    '${_zones.length}',
                    'Active',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildZoneStat(
                    '0',
                    'With Contractor',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Zones List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadZones,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _zones.length,
                itemBuilder: (context, index) {
                  final zone = _zones[index];
                  return _buildZoneCard(zone);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ZoneDrawingScreen()),
          ).then((_) => _loadZones());
        },
        icon: const Icon(Icons.draw),
        label: const Text('Draw Zone'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildZoneStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildZoneCard(Zone zone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showZoneDetails(zone),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      zone.zoneName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Zone Info - FIXED with null safety
              Row(
                children: [
                  _buildZoneInfoItem(
                      Icons.map,
                      zone.totalAreaSqKm != null
                          ? '${zone.totalAreaSqKm!.toStringAsFixed(1)} sq km'
                          : 'N/A'
                  ),
                  const SizedBox(width: 16),
                  _buildZoneInfoItem(
                      Icons.people,
                      zone.population?.toString() ?? '0'
                  ),
                  const SizedBox(width: 16),
                  _buildZoneInfoItem(Icons.engineering, '0 staff'),
                ],
              ),
              const SizedBox(height: 12),

              // Manager Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zone Manager',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${zone.city ?? 'City'} • 0 active',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _editZone(zone),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Contractor Info Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.business_center,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contractor: Not Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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

  Widget _buildZoneInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showZoneDetails(Zone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.zoneName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailItem('Zone ID', zone.zoneId),
              _buildDetailItem('Zone Number', zone.zoneNumber.toString()),
              _buildDetailItem('City', zone.city ?? 'N/A'),
              _buildDetailItem('Province', zone.province ?? 'N/A'),
              // FIXED: Added null safety for area
              _buildDetailItem(
                  'Area',
                  zone.totalAreaSqKm != null
                      ? '${zone.totalAreaSqKm!.toStringAsFixed(1)} sq km'
                      : 'N/A'
              ),
              _buildDetailItem('Population', zone.population?.toString() ?? '0'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _addNewZone() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Zone'),
        content: const Text('Use the "Draw Zone" button to create zones on map'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editZone(Zone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Zone'),
        content: const Text('Edit functionality coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}