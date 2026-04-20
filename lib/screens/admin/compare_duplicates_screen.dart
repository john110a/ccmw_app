// lib/screens/admin/compare_duplicates_screen.dart
import 'package:flutter/material.dart';
import '../../services/duplicate_service.dart';
import '../../services/AuthService.dart';
import '../../models/complaint_model.dart';

class CompareDuplicatesScreen extends StatefulWidget {
  final String complaintId1;
  final String complaintId2;

  const CompareDuplicatesScreen({
    super.key,
    required this.complaintId1,
    required this.complaintId2,
  });

  @override
  State<CompareDuplicatesScreen> createState() => _CompareDuplicatesScreenState();
}

class _CompareDuplicatesScreenState extends State<CompareDuplicatesScreen> {
  final DuplicateService _duplicateService = DuplicateService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _comparison;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final comparison = await _duplicateService.compareComplaints(
        complaintId1: widget.complaintId1,
        complaintId2: widget.complaintId2,
      );
      if (mounted) {
        setState(() {
          _comparison = comparison;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToMerge() async {
    final userId = await _authService.getUserId();
    if (userId == null || !mounted) return;

    final result = await Navigator.pushNamed(
      context,
      '/merge-duplicates',
      arguments: {
        'primaryId': widget.complaintId1,
        'duplicateIds': [widget.complaintId2],
        'mergedByUserId': userId,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
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
            'Compare Complaints',
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
            'Compare Complaints',
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
                onPressed: _loadComparison,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isLikelyDuplicate = _comparison?['Comparison']?['IsLikelyDuplicate'] ?? false;
    final totalScore = _comparison?['Comparison']?['SimilarityScores']?['Total']?.toDouble() ?? 0;

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
          'Compare Complaints',
          style: TextStyle(color: Colors.grey[900]),
        ),
        actions: [
          if (isLikelyDuplicate)
            IconButton(
              icon: const Icon(Icons.merge, color: Colors.blue),
              onPressed: _navigateToMerge,
              tooltip: 'Merge these complaints',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Similarity Score Card
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
                  const Text(
                    'Similarity Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${totalScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(totalScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLikelyDuplicate ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLikelyDuplicate ? 'Likely Duplicate' : 'Not a Duplicate',
                      style: TextStyle(
                        fontSize: 14,
                        color: isLikelyDuplicate ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Distance and Time
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
                  _buildComparisonRow(
                    'Distance',
                    '${_comparison?['Comparison']?['DistanceMeters'] ?? 0} meters',
                    _comparison?['Comparison']?['SimilarityScores']?['Location']?.toDouble() ?? 0,
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Time Difference',
                    '${_comparison?['Comparison']?['TimeDifferenceHours'] ?? 0} hours',
                    _comparison?['Comparison']?['SimilarityScores']?['Time']?.toDouble() ?? 0,
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Category',
                    _comparison?['Comparison']?['SameCategory'] == true ? 'Same' : 'Different',
                    _comparison?['Comparison']?['SimilarityScores']?['Category']?.toDouble() ?? 0,
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Description',
                    'Text Similarity',
                    _comparison?['Comparison']?['SimilarityScores']?['Description']?.toDouble() ?? 0,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Complaint 1
            Text(
              'Complaint 1',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildComplaintCard(_comparison?['Complaint1']),

            const SizedBox(height: 16),

            // Complaint 2
            Text(
              'Complaint 2',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildComplaintCard(_comparison?['Complaint2']),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, double score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(value),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getScoreColor(score).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic>? complaint) {
    if (complaint == null) return const SizedBox();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint['Title'] ?? 'No Title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              complaint['Description'] ?? 'No description',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(DateTime.parse(complaint['CreatedAt'])),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}