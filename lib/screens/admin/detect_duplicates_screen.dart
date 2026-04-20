// lib/screens/admin/detect_duplicates_screen.dart
import 'package:flutter/material.dart';
import '../../services/duplicate_service.dart';
import '../../services/zone_service.dart';
import '../../models/zone_model.dart';

class DetectDuplicatesScreen extends StatefulWidget {
  const DetectDuplicatesScreen({super.key});

  @override
  State<DetectDuplicatesScreen> createState() => _DetectDuplicatesScreenState();
}

class _DetectDuplicatesScreenState extends State<DetectDuplicatesScreen> {
  final DuplicateService _duplicateService = DuplicateService();
  final ZoneService _zoneService = ZoneService();

  List<dynamic> _potentialDuplicates = [];
  List<Zone> _zones = [];
  String? _selectedZoneId;
  double? _selectedLat;
  double? _selectedLng;
  double _radiusMeters = 100;
  int _hoursThreshold = 24;
  String? _selectedComplaintId;

  bool _isLoading = false;
  bool _isLoadingZones = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      print('📡 Loading zones from database...');
      final zones = await _zoneService.getAllZones();
      print('✅ Loaded ${zones.length} zones');

      if (mounted) {
        setState(() {
          _zones = zones;
          _isLoadingZones = false;
        });
      }
    } catch (e) {
      print('❌ Error loading zones: $e');
      if (mounted) {
        setState(() {
          _isLoadingZones = false;
          _errorMessage = 'Failed to load zones: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading zones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _detectDuplicates() async {
    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location or zone')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _duplicateService.detectPotentialDuplicates(
        lat: _selectedLat,
        lng: _selectedLng,
        radiusMeters: _radiusMeters,
        hoursThreshold: _hoursThreshold,
      );

      if (mounted) {
        setState(() {
          _potentialDuplicates = result['PotentialDuplicates'] ?? [];
          _isLoading = false;
        });

        if (_potentialDuplicates.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No potential duplicates found'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${_potentialDuplicates.length} potential duplicates'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error detecting duplicates: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _compareComplaint(dynamic item) {
    if (!mounted) return;

    final complaint = item['Complaint'];
    final complaintId = complaint['ComplaintId']?.toString();

    if (complaintId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid complaint data'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedComplaintId == null) {
      // First selection
      setState(() {
        _selectedComplaintId = complaintId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${complaint['Title']} - Tap another to compare'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Second selection - navigate to compare
      Navigator.pushNamed(
        context,
        '/compare-duplicates',
        arguments: {
          'complaintId1': _selectedComplaintId,
          'complaintId2': complaintId,
        },
      ).then((result) {
        if (result == true && mounted) {
          // Refresh after merge
          _detectDuplicates();
        }
        if (mounted) {
          setState(() => _selectedComplaintId = null);
        }
      }).catchError((e) {
        if (mounted) {
          setState(() => _selectedComplaintId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedComplaintId = null;
    });
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
          'Detect Duplicates',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          if (_selectedComplaintId != null)
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Form Card
            Container(
              margin: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Criteria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold ,color: Colors.black),
                  ),
                  const SizedBox(height: 16),

                  // Zone Dropdown
                  _isLoadingZones
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Zone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    value: _zones.any((zone) => zone.zoneId == _selectedZoneId)
                        ? _selectedZoneId
                        : null,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Custom Location'),
                      ),
                      if (_zones.isNotEmpty)
                        ..._zones.map((zone) => DropdownMenuItem<String>(
                          value: zone.zoneId,
                          child: Text(zone.zoneName),
                        )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedZoneId = value;
                        if (value != null && _zones.isNotEmpty) {
                          try {
                            final zone = _zones.firstWhere((z) => z.zoneId == value);
                            _selectedLat = zone.centerLatitude?.toDouble();
                            _selectedLng = zone.centerLongitude?.toDouble();
                          } catch (e) {
                            print('Zone not found: $e');
                          }
                        } else {
                          _selectedLat = null;
                          _selectedLng = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Latitude/Longitude Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pin_drop),
                          ),
                          initialValue: _selectedLat?.toString() ?? '',
                          onChanged: (value) => _selectedLat = double.tryParse(value),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pin_drop),
                          ),
                          initialValue: _selectedLng?.toString() ?? '',
                          onChanged: (value) => _selectedLng = double.tryParse(value),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Radius and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Radius (meters)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.radar),
                          ),
                          initialValue: _radiusMeters.toString(),
                          onChanged: (value) => _radiusMeters = double.tryParse(value) ?? 100,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Time (hours)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          initialValue: _hoursThreshold.toString(),
                          onChanged: (value) => _hoursThreshold = int.tryParse(value) ?? 24,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detect Button
                  ElevatedButton(
                    onPressed: _isLoadingZones ? null : _detectDuplicates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Detect Duplicates',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Selection Banner
            if (_selectedComplaintId != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected complaint. Tap another complaint to compare.',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _clearSelection,
                    ),
                  ],
                ),
              ),

            // Results Section
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _detectDuplicates,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_potentialDuplicates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No potential duplicates found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search criteria',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Found ${_potentialDuplicates.length} potential duplicates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _potentialDuplicates.length,
          itemBuilder: (context, index) {
            final item = _potentialDuplicates[index];
            final complaint = item['Complaint'];
            final similarityScore = (item['SimilarityScore'] ?? 0).toDouble();
            final distanceMeters = (item['DistanceMeters'] ?? 0).toDouble();
            final timeDiffHours = (item['TimeDiffHours'] ?? 0).toDouble();
            final isSelected = _selectedComplaintId == complaint['ComplaintId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => _compareComplaint(item),
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
                              complaint['Title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(similarityScore).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${similarityScore.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getScoreColor(similarityScore),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint['Description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistance(distanceMeters),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeDiff(timeDiffHours),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Selected - tap another complaint to compare',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.grey;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km away';
    }
  }

  String _formatTimeDiff(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)} minutes difference';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hours difference';
    } else {
      return '${(hours / 24).toStringAsFixed(1)} days difference';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Detect Duplicates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Select a zone or enter coordinates'),
            const SizedBox(height: 8),
            const Text('2. Set radius (how far to search)'),
            const SizedBox(height: 8),
            const Text('3. Set time threshold (how recent)'),
            const SizedBox(height: 8),
            const Text('4. Click "Detect Duplicates"'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('To merge:'),
            const SizedBox(height: 8),
            const Text('• Tap first complaint to select'),
            const SizedBox(height: 8),
            const Text('• Tap second complaint to compare'),
            const SizedBox(height: 8),
            const Text('• Click "Merge" on comparison screen'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}