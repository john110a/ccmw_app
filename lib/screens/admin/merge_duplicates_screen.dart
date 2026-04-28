// lib/screens/admin/merge_duplicates_screen.dart
import 'package:flutter/material.dart';
import '../../services/duplicate_service.dart';
import '../../services/AuthService.dart';
import '../../models/duplicate_cluster_model.dart';
import '../../models/complaint_photo_model.dart';

class MergeDuplicatesScreen extends StatefulWidget {
  const MergeDuplicatesScreen({super.key});

  @override
  State<MergeDuplicatesScreen> createState() => _MergeDuplicatesScreenState();
}

class _MergeDuplicatesScreenState extends State<MergeDuplicatesScreen> {
  final DuplicateService _duplicateService = DuplicateService();
  final AuthService _authService = AuthService();

  List<DuplicateCluster> _clusters = [];
  bool _isLoading = true;
  bool _isMerging = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading duplicate clusters...');
      final clusters = await _duplicateService.getDuplicateClusters();
      print('✅ Loaded ${clusters.length} clusters');

      setState(() {
        _clusters = clusters;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading clusters: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _getCurrentUserId() async {
    final userId = await _authService.getUserId();
    return userId ?? '00000000-0000-0000-0000-000000000000';
  }

  Future<void> _processAllComplaints() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing all complaints...'),
                  SizedBox(height: 8),
                  Text('This may take a moment', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );

      print('⚡ Processing all complaints to find duplicates...');
      final success = await _duplicateService.forceProcessComplaints();

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        await _loadClusters();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Processing completed! Check for clusters.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Processing failed. Check backend.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _toggleComplaintSelection(String clusterId, String complaintId) {
    setState(() {
      final cluster = _clusters.firstWhere((c) => c.clusterId == clusterId);
      cluster.toggleSelection(complaintId);
    });
  }

  Future<void> _mergeCluster(DuplicateCluster cluster) async {
    if (_isMerging) return;

    final selected = cluster.getSelectedComplaints();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 complaints to merge'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the primary complaint (first selected)
    final primaryComplaint = selected.first;
    final duplicateIds = selected.skip(1).map((c) => c.complaintId).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Complaints'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merge ${selected.length} complaints?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary complaint will be:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // Primary complaint image if available
                  if (_getPhotoUrl(primaryComplaint) != null)
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _getPhotoUrl(primaryComplaint)!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📌 ${primaryComplaint.complaintNumber ?? 'Unknown'}',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                primaryComplaint.complaint?.title ?? 'No title',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '📌 ${primaryComplaint.complaintNumber ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  if (primaryComplaint.complaint?.title != null && _getPhotoUrl(primaryComplaint) == null)
                    Text(
                      primaryComplaint.complaint!.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMerging = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Merging complaints...'),
                ],
              ),
            ),
          ),
        ),
      );

      final userId = await _getCurrentUserId();

      print('📡 Merging ${selected.length} complaints...');
      print('📌 Primary: ${primaryComplaint.complaintId}');
      print('📌 Duplicates: $duplicateIds');

      final result = await _duplicateService.mergeDuplicates(
        primaryComplaintId: primaryComplaint.complaintId,
        duplicateComplaintIds: duplicateIds,
        mergedByUserId: userId,
        radiusMeters: 100,
      );

      print('✅ Merge result: $result');

      if (!mounted) return;
      Navigator.pop(context);
      await _loadClusters();

      setState(() => _isMerging = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${selected.length} complaints merged successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Merge error: $e');

      if (!mounted) return;

      try {
        Navigator.pop(context);
      } catch (_) {}

      setState(() => _isMerging = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _debugCheckDuplicates() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking duplicates...'),
            ],
          ),
        ),
      );

      print('🔍 Running duplicate detection debug...');

      final stats = await _duplicateService.getDuplicateStats();
      print('📊 Stats: $stats');

      print('⚡ Trying to force process...');
      final forced = await _duplicateService.forceProcessComplaints();
      print('⚡ Force process result: $forced');

      await _loadClusters();

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📊 Duplicate Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total Clusters: ${stats['TotalClusters'] ?? 0}'),
                Text('Total Duplicates: ${stats['TotalDuplicates'] ?? 0}'),
                Text('Pending Review: ${stats['PendingReview'] ?? 0}'),
                Text('Auto Detected Today: ${stats['AutoDetectedToday'] ?? 0}'),
                const Divider(height: 24),
                const Text('⚡ Force Process:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(forced ? '✅ Successfully triggered' : '❌ Failed to trigger'),
                const Divider(height: 24),
                const Text('📋 Clusters Loaded:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_clusters.length} clusters found'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get photo URL from various sources
  String? _getPhotoUrl(DuplicateEntry entry) {
    // Try from entry.thumbnailPhotoUrl
    if (entry.thumbnailPhotoUrl != null && entry.thumbnailPhotoUrl!.isNotEmpty) {
      return entry.thumbnailPhotoUrl;
    }
    // Try from complaint.firstPhotoUrl
    if (entry.complaint?.firstPhotoUrl != null && entry.complaint!.firstPhotoUrl!.isNotEmpty) {
      return entry.complaint!.firstPhotoUrl;
    }
    // Try from complaint.complaintPhotos
    if (entry.complaint?.complaintPhotos.isNotEmpty == true) {
      return entry.complaint!.complaintPhotos.first.photoUrl;
    }
    // Try from entry.photos
    if (entry.photos.isNotEmpty) {
      return entry.photos.first.photoUrl;
    }
    return null;
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
            'Merge Duplicates',
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
            'Merge Duplicates',
            style: TextStyle(color: Colors.grey[900]),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadClusters,
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
                  'Error loading clusters',
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
                  onPressed: _loadClusters,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Merge Duplicates',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: _debugCheckDuplicates,
            tooltip: 'Debug Duplicates',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadClusters,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Similar complaints grouped by location and category. Select duplicates to merge.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          if (_clusters.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        'No duplicate clusters found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Process All" to scan for duplicates',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _debugCheckDuplicates,
                            icon: const Icon(Icons.search),
                            label: const Text('Check Stats'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _processAllComplaints,
                            icon: _isProcessing
                                ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.play_arrow),
                            label: Text(_isProcessing ? 'Processing...' : 'Process All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _clusters.length,
                itemBuilder: (context, index) {
                  return _buildClusterCard(_clusters[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClusterCard(DuplicateCluster cluster) {
    final selectedCount = cluster.getSelectedCount();
    final isAllSelected = selectedCount == cluster.duplicateEntries.length;

    final categoryName = cluster.primaryComplaint?.categoryName ?? 'Unknown Category';
    final zoneName = cluster.primaryComplaint?.zoneName ?? 'Unknown Zone';
    final primaryTitle = cluster.primaryComplaint?.title ?? 'No title';
    final primaryCitizen = cluster.primaryComplaint?.citizenName ?? 'Unknown';
    final primaryUpvotes = cluster.primaryComplaint?.upvoteCount ?? 0;

    // Get primary complaint photo
    String? primaryPhotoUrl;
    if (cluster.duplicateEntries.isNotEmpty) {
      primaryPhotoUrl = _getPhotoUrl(cluster.duplicateEntries.first);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
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
                  children: [
                    const Icon(Icons.merge_type, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Possible Duplicates',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cluster.totalComplaintsMerged} complaints',
                        style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(categoryName, style: const TextStyle(fontSize: 12)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(zoneName, style: const TextStyle(fontSize: 12)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${cluster.locationLatitude.toStringAsFixed(4)}, ${cluster.locationLongitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (primaryPhotoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            primaryPhotoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.image, size: 24, color: Colors.grey),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Primary: $primaryTitle',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Submitted by: $primaryCitizen',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$primaryUpvotes upvotes',
                          style: TextStyle(fontSize: 10, color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Complaints List
          ...cluster.duplicateEntries.map((entry) => _buildComplaintItem(entry, cluster.clusterId)),

          // Merge Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isAllSelected,
                      onChanged: _isMerging ? null : (value) {
                        for (var entry in cluster.duplicateEntries) {
                          cluster.toggleSelection(entry.complaintId);
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select All ($selectedCount/${cluster.duplicateEntries.length})',
                      style: TextStyle(fontSize: 14, color: _isMerging ? Colors.grey : Colors.black),
                    ),
                    const Spacer(),
                    Text(
                      'Total upvotes: ${cluster.totalCombinedUpvotes}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isMerging ? null : () => _mergeCluster(cluster),
                    icon: const Icon(Icons.call_merge),
                    label: _isMerging
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Merge Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintItem(DuplicateEntry entry, String clusterId) {
    final complaint = entry.complaint;
    final photoUrl = _getPhotoUrl(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: entry.isSelected,
            onChanged: _isMerging ? null : (value) {
              _toggleComplaintSelection(clusterId, entry.complaintId);
            },
          ),
          const SizedBox(width: 12),
          // Complaint thumbnail image with loading indicator
          if (photoUrl != null && photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 30, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      complaint?.complaintNumber ?? 'Unknown',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${complaint?.upvoteCount ?? 0}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  complaint?.title ?? 'No title',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  complaint?.description ?? 'No description',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          complaint?.citizenName ?? 'Unknown',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(complaint?.createdAt ?? DateTime.now()),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (entry.similarityScore > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.compare_arrows, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.similarityScore.toStringAsFixed(0)}% match',
                            style: TextStyle(
                              fontSize: 11,
                              color: DuplicateService.getSimilarityColor(entry.similarityScore),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (entry.photos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera, size: 10, color: Colors.blue),
                            const SizedBox(width: 2),
                            Text(
                              '${entry.photos.length}',
                              style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}