// lib/screens/admin/complaint_approval_screen.dart
import 'package:flutter/material.dart';
import '../../services/complaint_service.dart';
import '../../models/complaint_model.dart';

class ComplaintApprovalScreen extends StatefulWidget {
  const ComplaintApprovalScreen({super.key});

  @override
  State<ComplaintApprovalScreen> createState() => _ComplaintApprovalScreenState();
}

class _ComplaintApprovalScreenState extends State<ComplaintApprovalScreen> {
  final ComplaintService _complaintService = ComplaintService();

  List<Complaint> _pendingComplaints = [];
  bool _isLoading = true;
  Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPendingComplaints();
  }

  Future<void> _loadPendingComplaints() async {
    setState(() => _isLoading = true);

    try {
      final allComplaints = await _complaintService.getAllComplaints();

      print('📡 Total complaints: ${allComplaints.length}');

      // DEBUG: Print each complaint's ID
      for (var c in allComplaints) {
        print('   ID: "${c.complaintId}" - Title: ${c.title} - Status: ${c.currentStatus}');
      }

      _pendingComplaints = allComplaints
          .where((c) =>  c.submissionStatus == 0)
          .toList();

      print('✅ Pending approvals: ${_pendingComplaints.length}');

      // DEBUG: Print pending IDs
      for (var c in _pendingComplaints) {
        print('   PENDING ID: "${c.complaintId}" - Title: ${c.title}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading pending complaints: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveComplaint(String complaintId) async {
    print('🔍 DEBUG - Received complaintId: "$complaintId"');
    print('🔍 DEBUG - complaintId length: ${complaintId.length}');
    print('🔍 DEBUG - is empty? ${complaintId.isEmpty}');

    if (complaintId.isEmpty) {
      print('❌ ERROR: complaintId is empty! Cannot approve.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid complaint ID'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_processingIds.contains(complaintId)) return;

    setState(() {
      _processingIds.add(complaintId);
    });

    try {
      print('📡 Approving complaint: $complaintId');
      await _complaintService.updateStatus(complaintId, 'Approved');

      if (!mounted) return;

      await _loadPendingComplaints();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint approved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error approving complaint: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving complaint: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(complaintId);
        });
      }
    }
  }

  Future<void> _rejectComplaint(String complaintId) async {
    print('🔍 DEBUG - Reject complaintId: "$complaintId"');

    if (complaintId.isEmpty) {
      print('❌ ERROR: complaintId is empty! Cannot reject.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid complaint ID'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_processingIds.contains(complaintId)) return;

    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Reject Complaint'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.black),
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a rejection reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (shouldReject == true && reasonController.text.trim().isNotEmpty) {
      setState(() {
        _processingIds.add(complaintId);
      });

      try {
        print('📡 Rejecting complaint: $complaintId');
        print('📡 Reason: ${reasonController.text}');

        await _complaintService.updateStatus(complaintId, 'Rejected');

        if (!mounted) return;

        await _loadPendingComplaints();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint rejected: ${reasonController.text}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('❌ Error rejecting complaint: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting complaint: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _processingIds.remove(complaintId);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadPendingComplaints,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingComplaints.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'No pending approvals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'All complaints have been reviewed',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPendingComplaints,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _pendingComplaints[index];
          final isProcessing = _processingIds.contains(complaint.complaintId);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          complaint.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          complaint.categoryName ?? 'General',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: complaint.priority == 'High'
                              ? Colors.red[50]
                              : complaint.priority == 'Medium'
                              ? Colors.orange[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          complaint.priority,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: complaint.priority == 'High'
                                ? Colors.red
                                : complaint.priority == 'Medium'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          complaint.zoneName ?? 'Unknown Zone',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          complaint.complaintNumber ?? 'No #',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          complaint.locationAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : () => _rejectComplaint(complaint.complaintId),
                          icon: isProcessing
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.close, size: 18),
                          label: Text(isProcessing ? 'Processing...' : 'Reject'),
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
                          onPressed: isProcessing ? null : () => _approveComplaint(complaint.complaintId),
                          icon: isProcessing
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.check, size: 18),
                          label: Text(isProcessing ? 'Processing...' : 'Approve'),
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
              ),
            ),
          );
        },
      ),
    );
  }
}