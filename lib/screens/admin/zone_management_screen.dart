// lib/screens/admin/zone_management_screen.dart
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

  List<Zone> _mainZones = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _expandedZones = {};

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() => _isLoading = true);
    try {
      final zones = await _zoneService.getZoneHierarchy();
      setState(() {
        _mainZones = zones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleExpand(String zoneId) {
    setState(() {
      if (_expandedZones.contains(zoneId)) {
        _expandedZones.remove(zoneId);
      } else {
        _expandedZones.add(zoneId);
      }
    });
  }

  // ===== FIXED: Use ZoneDrawingScreen for Adding Sub-Zone =====
  Future<void> _addSubZone(Zone parentZone) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneDrawingScreen(
          isSubZone: true,
          parentZone: parentZone,
        ),
      ),
    );
    if (result == true) {
      _loadZones();
    }
  }

  // ===== FIXED: Draw Main Zone =====
  void _drawMainZone() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ZoneDrawingScreen(
          isSubZone: false,
          parentZone: null,
        ),
      ),
    ).then((_) => _loadZones());
  }

  void _editZone(Zone zone) {
    // TODO: Implement edit zone functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  Future<void> _deleteSubZone(Zone subZone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-Zone'),
        content: Text('Are you sure you want to delete "${subZone.zoneName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _zoneService.deleteSubZone(subZone.zoneId);
      if (success) {
        _loadZones();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${subZone.zoneName} deleted'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete sub-zone'), backgroundColor: Colors.red),
        );
      }
    }
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
              Row(
                children: [
                  Icon(
                    zone.isMainZone ? Icons.location_city : Icons.location_on,
                    color: zone.isMainZone ? Colors.blue : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      zone.zoneName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: zone.isMainZone ? Colors.blue[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      zone.zoneTypeDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: zone.isMainZone ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailItem('Zone ID', zone.zoneId),
              _buildDetailItem('Zone Number', zone.zoneNumber.toString()),
              _buildDetailItem('Zone Code', zone.zoneCode ?? 'N/A'),
              _buildDetailItem('City', zone.city ?? 'N/A'),
              _buildDetailItem('Province', zone.province ?? 'N/A'),
              _buildDetailItem(
                'Area',
                zone.totalAreaSqKm != null
                    ? '${zone.totalAreaSqKm!.toStringAsFixed(1)} sq km'
                    : 'N/A',
              ),
              _buildDetailItem('Population', zone.population?.toString() ?? '0'),
              _buildDetailItem('Active Complaints', zone.activeComplaintsCount?.toString() ?? '0'),
              _buildDetailItem('Total Complaints', zone.totalComplaintsCount?.toString() ?? '0'),
              _buildDetailItem('Performance', zone.performanceRating ?? 'N/A'),
              if (zone.isSubZone && zone.parentZoneId != null)
                _buildDetailItem('Parent Zone', 'Loading...'),
              const SizedBox(height: 16),
              if (zone.isSubZone)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteSubZone(zone),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete Sub-Zone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
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
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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

    int totalMainZones = _mainZones.length;
    int totalSubZones = _mainZones.fold(0, (sum, zone) => sum + (zone.subZones?.length ?? 0));
    int totalActive = _mainZones.where((z) => z.isActive).length;

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
            onPressed: _drawMainZone,
            tooltip: 'Draw Main Zone on Map',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadZones,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildZoneStat('$totalMainZones', 'Main Zones', Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildZoneStat('$totalSubZones', 'Sub-Zones', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildZoneStat('$totalActive', 'Active', Colors.green),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadZones,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mainZones.length,
                itemBuilder: (context, index) {
                  final mainZone = _mainZones[index];
                  return _buildMainZoneCard(mainZone);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _drawMainZone,
        icon: const Icon(Icons.draw),
        label: const Text('Draw Main Zone'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildZoneStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainZoneCard(Zone mainZone) {
    final isExpanded = _expandedZones.contains(mainZone.zoneId);
    final hasSubZones = mainZone.hasSubZones;
    final subZones = mainZone.subZones ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showZoneDetails(mainZone),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, color: Colors.blue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                mainZone.zoneName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (hasSubZones)
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.blue,
                              ),
                              onPressed: () => _toggleExpand(mainZone.zoneId),
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue, size: 20),
                            onPressed: () => _addSubZone(mainZone),
                            tooltip: 'Add Sub-Zone',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _editZone(mainZone),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.code, mainZone.zoneCode ?? 'No Code'),
                      _buildInfoChip(Icons.location_on, mainZone.city ?? 'City'),
                      _buildInfoChip(
                        Icons.area_chart,
                        mainZone.totalAreaSqKm != null
                            ? '${mainZone.totalAreaSqKm!.toStringAsFixed(1)} km²'
                            : 'N/A',
                      ),
                      if (hasSubZones)
                        _buildInfoChip(
                          Icons.folder,
                          '${subZones.length} Sub-Zones',
                          color: Colors.green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded && hasSubZones)
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: subZones.map((subZone) => _buildSubZoneCard(subZone)).toList(),
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildStatChip(Icons.assignment, 'Total: ${mainZone.totalComplaintsCount ?? 0}'),
                const SizedBox(width: 8),
                _buildStatChip(Icons.pending, 'Active: ${mainZone.activeComplaintsCount ?? 0}'),
                const SizedBox(width: 8),
                _buildStatChip(Icons.people, 'Staff: 0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubZoneCard(Zone subZone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _showZoneDetails(subZone),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subZone.zoneName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.green),
                        onPressed: () => _editZone(subZone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _deleteSubZone(subZone),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.code, subZone.zoneCode ?? 'No Code', small: true),
                  _buildInfoChip(Icons.area_chart,
                      subZone.totalAreaSqKm != null
                          ? '${subZone.totalAreaSqKm!.toStringAsFixed(1)} km²'
                          : 'N/A',
                      small: true),
                  _buildInfoChip(Icons.people, 'Pop: ${subZone.population ?? 0}', small: true),
                  _buildInfoChip(Icons.assignment, 'Complaints: ${subZone.totalComplaintsCount ?? 0}', small: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool small = false, Color? color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}