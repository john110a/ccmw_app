// lib/models/complaint_status_history_model.dart
import 'package:flutter/material.dart';

class ComplaintStatusHistory {
  final String historyId;
  final String complaintId;
  final String? previousStatus;
  final String newStatus;
  final String? changedById;
  final DateTime changedAt;
  final String? changeReason;
  final String? notes;

  // Optional fields that might be useful
  final String? changedByName;
  final String? complaintNumber;
  final String? complaintTitle;

  ComplaintStatusHistory({
    required this.historyId,
    required this.complaintId,
    this.previousStatus,
    required this.newStatus,
    this.changedById,
    required this.changedAt,
    this.changeReason,
    this.notes,
    this.changedByName,
    this.complaintNumber,
    this.complaintTitle,
  });

  factory ComplaintStatusHistory.fromJson(Map<String, dynamic> json) {
    return ComplaintStatusHistory(
      historyId: json['historyId']?.toString() ??
          json['HistoryId']?.toString() ??
          json['history_id']?.toString() ?? '',

      complaintId: json['complaintId']?.toString() ??
          json['ComplaintId']?.toString() ??
          json['complaint_id']?.toString() ?? '',

      previousStatus: json['previousStatus']?.toString() ??
          json['PreviousStatus']?.toString() ??
          json['old_status']?.toString(),

      newStatus: json['newStatus']?.toString() ??
          json['NewStatus']?.toString() ??
          json['new_status']?.toString() ?? '',

      changedById: json['changedById']?.toString() ??
          json['ChangedById']?.toString() ??
          json['changed_by']?.toString(),

      changedAt: _parseDateTime(json['changedAt'] ??
          json['ChangedAt'] ??
          json['changed_at']),

      changeReason: json['changeReason']?.toString() ??
          json['ChangeReason']?.toString() ??
          json['change_reason']?.toString(),

      notes: json['notes']?.toString() ??
          json['Notes']?.toString(),

      changedByName: json['changedByName']?.toString() ??
          json['ChangedByName']?.toString() ??
          json['changed_by_name']?.toString(),

      complaintNumber: json['complaintNumber']?.toString() ??
          json['ComplaintNumber']?.toString() ??
          json['complaint_number']?.toString(),

      complaintTitle: json['complaintTitle']?.toString() ??
          json['ComplaintTitle']?.toString() ??
          json['complaint_title']?.toString(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'history_id': historyId,
      'complaint_id': complaintId,
      'old_status': previousStatus,
      'new_status': newStatus,
      'changed_by': changedById,
      'changed_at': changedAt.toIso8601String(),
      'ChangeReason': changeReason,
      'Notes': notes,
      'changed_by_name': changedByName,
      'complaint_number': complaintNumber,
      'complaint_title': complaintTitle,
    };
  }

  // ========== STATUS HELPER METHODS ==========

  // Helper method to get display status
  String getDisplayStatus() {
    return newStatus;
  }

  // Helper method to check if this is a specific status
  bool isStatus(String status) {
    return newStatus.toLowerCase() == status.toLowerCase();
  }

  // ========== DATE FORMATTING METHODS ==========

  // Helper method to get formatted date
  String getFormattedDate({bool showTime = true}) {
    if (showTime) {
      return '${_getDaySuffix(changedAt.day)} ${_getMonthName(changedAt.month)} ${changedAt.year}, ${changedAt.hour.toString().padLeft(2, '0')}:${changedAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${_getDaySuffix(changedAt.day)} ${_getMonthName(changedAt.month)} ${changedAt.year}';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  // Helper method to get relative time
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(changedAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // ========== STATUS COLOR & ICON METHODS ==========

  // Get color based on status
  Color getStatusColor() {
    final status = newStatus.toLowerCase();

    if (status.contains('submitted') || status.contains('pending'))
      return Colors.orange;
    if (status.contains('review') || status.contains('verification'))
      return Colors.purple;
    if (status.contains('approved'))
      return Colors.green;
    if (status.contains('assigned'))
      return Colors.blue;
    if (status.contains('progress') || status.contains('working'))
      return Colors.indigo;
    if (status.contains('resolved') || status.contains('completed'))
      return Colors.green;
    if (status.contains('verified'))
      return Colors.teal;
    if (status.contains('rejected') || status.contains('declined'))
      return Colors.red;
    if (status.contains('closed'))
      return Colors.grey;

    return Colors.blue;
  }

  // Get icon based on status
  IconData getStatusIcon() {
    final status = newStatus.toLowerCase();

    if (status.contains('submitted') || status.contains('pending'))
      return Icons.hourglass_empty;
    if (status.contains('review') || status.contains('verification'))
      return Icons.visibility;
    if (status.contains('approved'))
      return Icons.check_circle;
    if (status.contains('assigned'))
      return Icons.person;
    if (status.contains('progress') || status.contains('working'))
      return Icons.build;
    if (status.contains('resolved') || status.contains('completed'))
      return Icons.done_all;
    if (status.contains('verified'))
      return Icons.verified;
    if (status.contains('rejected') || status.contains('declined'))
      return Icons.cancel;
    if (status.contains('closed'))
      return Icons.lock;

    return Icons.pending;
  }

  // Get status badge color (lighter version for backgrounds)
  Color getStatusBackgroundColor() {
    return getStatusColor().withOpacity(0.1);
  }

  // ========== UTILITY METHODS ==========

  // Check if status changed from previous
  bool hasStatusChanged() {
    return previousStatus != null && previousStatus != newStatus;
  }

  // Get change description
  String getChangeDescription() {
    if (previousStatus == null) {
      return 'Status set to $newStatus';
    }
    return 'Status changed from $previousStatus to $newStatus';
  }

  // Check if there are any notes
  bool hasNotes() {
    return notes != null && notes!.isNotEmpty;
  }

  // Check if there's a change reason
  bool hasChangeReason() {
    return changeReason != null && changeReason!.isNotEmpty;
  }

  // Get display name for changed by (with fallback)
  String getChangedByDisplay({String fallback = 'System'}) {
    if (changedByName != null && changedByName!.isNotEmpty) {
      return changedByName!;
    }
    if (changedById != null && changedById!.isNotEmpty) {
      return 'User: $changedById';
    }
    return fallback;
  }

  // ========== COMPARISON METHODS ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplaintStatusHistory &&
        other.historyId == historyId;
  }

  @override
  int get hashCode => historyId.hashCode;

  // Sort by date (newest first)
  static List<ComplaintStatusHistory> sortByDate(List<ComplaintStatusHistory> list, {bool newestFirst = true}) {
    final sorted = List<ComplaintStatusHistory>.from(list);
    sorted.sort((a, b) => newestFirst
        ? b.changedAt.compareTo(a.changedAt)
        : a.changedAt.compareTo(b.changedAt));
    return sorted;
  }

  // Filter by status
  static List<ComplaintStatusHistory> filterByStatus(
      List<ComplaintStatusHistory> list, String status) {
    return list.where((item) => item.isStatus(status)).toList();
  }

  // Get unique statuses in history
  static List<String> getUniqueStatuses(List<ComplaintStatusHistory> list) {
    return list.map((item) => item.newStatus).toSet().toList();
  }
}