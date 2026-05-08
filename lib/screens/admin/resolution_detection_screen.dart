// lib/screens/admin/resolution_detection_screen.dart
import 'package:flutter/material.dart';
import '../../services/resolution_service.dart';
import '../../models/resolution_model.dart';
import '../../services/AuthService.dart';
import '../../utils/image_utils.dart';

class ResolutionDetectionScreen extends StatefulWidget {
  const ResolutionDetectionScreen({super.key});

  @override
  State<ResolutionDetectionScreen> createState() => _ResolutionDetectionScreenState();
}

class _ResolutionDetectionScreenState extends State<ResolutionDetectionScreen>
    with SingleTickerProviderStateMixin {
  final ResolutionService _resolutionService = ResolutionService();
  final AuthService _authService = AuthService();

  List<Resolution> _allSubmissions = [];
  List<Resolution> _pendingSubmissions = [];
  List<Resolution> _verifiedSubmissions = [];
  List<Map<String, dynamic>> _flaggedComplaints = [];

  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  int _pendingCount = 0;
  int _verifiedCount = 0;
  int _flaggedCount = 0;
  int _totalResolutions = 0;
  int _thisMonth = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubmissions(),
      _loadStats(),
      _loadFlaggedComplaints(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _resolutionService.getResolutionStats();
      if (mounted) {
        setState(() {
          _totalResolutions = stats['TotalResolutions'] ?? 0;
          _thisMonth = stats['ThisMonth'] ?? 0;
          _pendingCount = stats['PendingResolutions'] ?? 0;
          _verifiedCount = stats['VerifiedResolutions'] ?? 0;
          _flaggedCount = stats['FlaggedResolutions'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  Future<void> _loadFlaggedComplaints() async {
    try {
      final flaggedComplaints = await _resolutionService.getFlaggedComplaints();
      if (mounted) {
        // Debug: Print first complaint to see field names
        if (flaggedComplaints.isNotEmpty) {
          print('=== Flagged Complaint Data ===');
          print(flaggedComplaints[0]);
          print('Keys: ${flaggedComplaints[0].keys.toList()}');
        }
        setState(() {
          _flaggedComplaints = flaggedComplaints;
          _flaggedCount = flaggedComplaints.length;
        });
        print('✅ Loaded $_flaggedCount flagged complaints');
      }
    } catch (e) {
      print('❌ Error loading flagged complaints: $e');
    }
  }

  Future<void> _loadSubmissions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📡 Loading all resolutions...');

      final allResolutions = await _resolutionService.getPendingResolutions();
      final allData = await _resolutionService.getAllResolutions(pageSize: 100);
      final allFromApi = allData['Resolutions'] ?? [];

      List<Resolution> combined = List.from(allResolutions);

      for (var res in allFromApi) {
        if (!combined.any((r) => r.id == res['Id'])) {
          combined.add(Resolution.fromJson(res));
        }
      }

      _pendingSubmissions = combined.where((s) => s.status.toLowerCase() == 'pending').toList();
      _verifiedSubmissions = combined.where((s) => s.status.toLowerCase() == 'verified').toList();
      _allSubmissions = combined;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('✅ Loaded: Pending: ${_pendingSubmissions.length}, Verified: ${_verifiedSubmissions.length}');
    } catch (e) {
      print('❌ Error loading submissions: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifySubmission(String submissionId) async {
    try {
      setState(() => _isLoading = true);

      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      await _resolutionService.verifyResolution(submissionId, notes: 'Verified by admin');

      if (!mounted) return;

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolution verified successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _flagSubmission(String submissionId, String reason) async {
    try {
      setState(() => _isLoading = true);

      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      await _resolutionService.flagResolution(
        submissionId,
        reason,
        notes: 'Flagged by admin',
      );

      if (!mounted) return;

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolution flagged for review'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsGenuine(Map<String, dynamic> complaint) async {
    try {
      setState(() => _isLoading = true);

      final adminId = await _authService.getUserId();
      final complaintId = complaint['ComplaintId'] ?? complaint['complaintId'];

      final success = await _resolutionService.verifyGenuineComplaint(
        complaintId,
        adminId: adminId,
        notes: 'Admin reviewed and marked as genuine',
      );

      if (success && mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint marked as genuine'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAsFake(Map<String, dynamic> complaint) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Confirm Fake Complaint'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will give the citizen a strike. After 3 strikes, they will be banned.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for marking as fake...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter a reason' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context);

              setState(() => _isLoading = true);
              try {
                final adminId = await _authService.getUserId();
                final complaintId = complaint['ComplaintId'] ?? complaint['complaintId'];

                final result = await _resolutionService.markAsFakeComplaint(
                  complaintId,
                  adminId: adminId,
                  reason: reasonController.text,
                  notes: 'Admin confirmed as fake complaint',
                );

                if (result['success'] == true && mounted) {
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Complaint marked as fake'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Fake'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Full Resolution Photo', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Failed to load image', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFlagDialog(String submissionId) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Flag Resolution'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you flagging this resolution?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                _flagSubmission(submissionId, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(String submissionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Verify Resolution'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm that the issue has been properly resolved as shown in the after photo?',
            ),
            const SizedBox(height: 16),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifySubmission(submissionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // FIXED: Build flagged complaint card with PascalCase support
  Widget _buildFlaggedComplaintCard(Map<String, dynamic> complaint) {
    // Support both PascalCase (backend) and camelCase (fallback)
    final complaintId = complaint['ComplaintId'] ?? complaint['complaintId'];
    final complaintNumber = complaint['ComplaintNumber'] ?? complaint['complaintNumber'] ?? 'N/A';
    final title = complaint['Title'] ?? complaint['title'] ?? 'No Title';
    final description = complaint['Description'] ?? complaint['description'] ?? 'No description';
    final location = complaint['Location'] ?? complaint['location'] ?? 'Unknown Location';
    final category = complaint['Category'] ?? complaint['category'] ?? 'General';
    final citizenName = complaint['CitizenName'] ?? complaint['citizenName'] ?? 'Unknown';
    final submittedAt = complaint['SubmittedAt'] ?? complaint['submittedAt'] ?? 'Unknown';
    final beforePhoto = complaint['BeforePhotoUrl'] ?? complaint['beforePhotoUrl'];
    final afterPhoto = complaint['AfterPhotoUrl'] ?? complaint['afterPhotoUrl'];
    final flagReason = complaint['FlagReason'] ?? complaint['flagReason'] ?? 'Flagged for review';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
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
                    Text(
                      complaintNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FLAGGED',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(category, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoComparison('BEFORE', beforePhoto, Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPhotoComparison('AFTER', afterPhoto, Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flagReason,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Citizen: $citizenName', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Submitted: $submittedAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsGenuine(complaint),
                        icon: const Icon(Icons.verified, size: 18),
                        label: const Text('Mark Genuine'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmAsFake(complaint),
                        icon: const Icon(Icons.warning, size: 18),
                        label: const Text('Confirm Fake'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allSubmissions.isEmpty && _flaggedComplaints.isEmpty) {
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
            'Resolution Verification',
            style: TextStyle(color: Colors.grey[900]),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _allSubmissions.isEmpty) {
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
            'Resolution Verification',
            style: TextStyle(color: Colors.grey[900]),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
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
                  'Error loading resolutions',
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resolution Verification',
          style: TextStyle(color: Colors.grey[900]),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Pending ($_pendingCount)'),
            Tab(text: 'Verified ($_verifiedCount)'),
            Tab(text: 'Flagged ($_flaggedCount)', icon: const Icon(Icons.flag, size: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
                Expanded(child: _buildStatCard('$_pendingCount', 'Pending', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('$_verifiedCount', 'Verified', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('$_flaggedCount', 'Flagged', Colors.red)),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review before/after photos and verify complaint resolutions manually. Flagged complaints need admin review.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubmissionList(_pendingSubmissions, isPendingTab: true),
                _buildSubmissionList(_verifiedSubmissions, isPendingTab: false),
                _buildFlaggedComplaintsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedComplaintsList() {
    if (_flaggedComplaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No flagged complaints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Flagged complaints that need review will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flaggedComplaints.length,
      itemBuilder: (context, index) {
        return _buildFlaggedComplaintCard(_flaggedComplaints[index]);
      },
    );
  }

  Widget _buildSubmissionList(List<Resolution> submissions, {bool isPendingTab = true}) {
    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.pending_actions : Icons.verified,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? 'No pending resolutions' : 'No verified resolutions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              isPendingTab ? 'All resolved complaints have been verified' : 'Verified resolutions will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (isPendingTab) ...[
              const SizedBox(height: 16),
              Text(
                'Total resolved this month: $_thisMonth',
                style: TextStyle(fontSize: 14, color: Colors.blue[600]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        return _buildSubmissionCard(submissions[index]);
      },
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSubmissionCard(Resolution submission) {
    final statusColor = submission.status == 'Pending' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
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
                    Text(
                      submission.complaintNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        submission.status,
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  submission.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      child: Text(submission.category, style: const TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(submission.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoComparison('BEFORE', submission.beforePhotoUrl, statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPhotoComparison('AFTER', submission.afterPhotoUrl, statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Resolution Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    submission.resolutionNotes,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Resolved by: ${submission.resolvedBy}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Submitted: ${submission.submittedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),

                if (submission.status == 'Pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showFlagDialog(submission.id),
                          icon: const Icon(Icons.flag, size: 18),
                          label: const Text('Flag'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVerifyDialog(submission.id),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoComparison(String label, String? imageUrl, Color statusColor) {
    String fullImageUrl = '';
    if (imageUrl != null && imageUrl.isNotEmpty) {
      fullImageUrl = ImageUtils.getFullImageUrl(imageUrl);
    }

    return GestureDetector(
      onTap: () {
        if (fullImageUrl.isNotEmpty) {
          _showFullScreenImage(fullImageUrl);
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
        ),
        child: fullImageUrl.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Failed to load $label image: $fullImageUrl');
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Failed to load',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'No image available',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}