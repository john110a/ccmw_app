// lib/models/fake_complaint_log_model.dart
import 'package:flutter/material.dart';

class FakeComplaintLog {
  final String logId;
  final String complaintId;
  final String citizenId;
  final int strikeNumber;
  final String actionTaken; // Warning, TempBan, PermanentBan
  final DateTime? bannedUntil;
  final DateTime createdAt;

  // Optional: For displaying related data
  final String? complaintNumber;
  final String? citizenName;
  final String? citizenEmail;

  FakeComplaintLog({
    required this.logId,
    required this.complaintId,
    required this.citizenId,
    required this.strikeNumber,
    required this.actionTaken,
    this.bannedUntil,
    required this.createdAt,
    this.complaintNumber,
    this.citizenName,
    this.citizenEmail,
  });

  factory FakeComplaintLog.fromJson(Map<String, dynamic> json) {
    return FakeComplaintLog(
      logId: json['LogId']?.toString() ??
          json['logId']?.toString() ??
          json['log_id']?.toString() ?? '',
      complaintId: json['ComplaintId']?.toString() ??
          json['complaintId']?.toString() ??
          json['complaint_id']?.toString() ?? '',
      citizenId: json['CitizenId']?.toString() ??
          json['citizenId']?.toString() ??
          json['citizen_id']?.toString() ?? '',
      strikeNumber: json['StrikeNumber'] ?? json['strikeNumber'] ?? 0,
      actionTaken: json['ActionTaken'] ?? json['actionTaken'] ?? 'Warning',
      bannedUntil: json['BannedUntil'] != null
          ? DateTime.parse(json['BannedUntil'].toString())
          : (json['bannedUntil'] != null ? DateTime.parse(json['bannedUntil'].toString()) : null),
      createdAt: _parseDateTime(json['CreatedAt'] ?? json['createdAt']),
      complaintNumber: json['ComplaintNumber']?.toString() ?? json['complaintNumber']?.toString(),
      citizenName: json['CitizenName']?.toString() ?? json['citizenName']?.toString(),
      citizenEmail: json['CitizenEmail']?.toString() ?? json['citizenEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LogId': logId,
      'ComplaintId': complaintId,
      'CitizenId': citizenId,
      'StrikeNumber': strikeNumber,
      'ActionTaken': actionTaken,
      'BannedUntil': bannedUntil?.toIso8601String(),
      'CreatedAt': createdAt.toIso8601String(),
    };
  }

  // Helper getters for UI
  String get actionIcon {
    switch (actionTaken) {
      case 'Warning':
        return '⚠️';
      case 'TempBan':
        return '⛔';
      case 'PermanentBan':
        return '🚫';
      default:
        return '📋';
    }
  }

  Color getActionColor() {
    switch (actionTaken) {
      case 'Warning':
        return Colors.orange;
      case 'TempBan':
        return Colors.red;
      case 'PermanentBan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String getActionDisplayName() {
    switch (actionTaken) {
      case 'Warning':
        return 'Warning';
      case 'TempBan':
        return 'Temporary Ban';
      case 'PermanentBan':
        return 'Permanent Ban';
      default:
        return actionTaken;
    }
  }

  String getStrikeDisplay() {
    return 'Strike $strikeNumber of 3';
  }

  String getBannedUntilDisplay() {
    if (bannedUntil == null) return 'N/A';
    return _formatDate(bannedUntil!);
  }

  String getCreatedAtDisplay() {
    return _formatDate(createdAt);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}