// lib/models/escalation_model.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class Escalation {
  final String escalationId;
  final String complaintId;
  final int escalationLevel;
  final String escalatedFromId;
  final String escalatedToId;
  final String escalatedById;
  final String? escalationReason;
  final double? hoursElapsed;
  final String? escalationNotes;
  final bool resolved;
  final DateTime escalatedAt;
  final DateTime? resolvedAt;

  // Additional fields for UI
  String? complaintNumber;
  String? complaintTitle;
  String? escalatedFromName;
  String? escalatedToName;
  String? escalatedByName;

  Escalation({
    required this.escalationId,
    required this.complaintId,
    required this.escalationLevel,
    required this.escalatedFromId,
    required this.escalatedToId,
    required this.escalatedById,
    this.escalationReason,
    this.hoursElapsed,
    this.escalationNotes,
    required this.resolved,
    required this.escalatedAt,
    this.resolvedAt,
    this.complaintNumber,
    this.complaintTitle,
    this.escalatedFromName,
    this.escalatedToName,
    this.escalatedByName,
  });

  factory Escalation.fromJson(Map<String, dynamic> json) {
    return Escalation(
      // Primary IDs - Handle both PascalCase and camelCase
      escalationId: json['EscalationId']?.toString() ??
          json['escalationId']?.toString() ??
          json['escalation_id']?.toString() ?? '',
      complaintId: json['ComplaintId']?.toString() ??
          json['complaintId']?.toString() ??
          json['complaint_id']?.toString() ?? '',

      // Escalation details
      escalationLevel: json['EscalationLevel'] ??
          json['escalationLevel'] ??
          json['escalation_level'] ?? 0,
      escalatedFromId: json['EscalatedFromId']?.toString() ??
          json['escalatedFromId']?.toString() ??
          json['escalated_from_id']?.toString() ?? '',
      escalatedToId: json['EscalatedToId']?.toString() ??
          json['escalatedToId']?.toString() ??
          json['escalated_to_id']?.toString() ?? '',
      escalatedById: json['EscalatedById']?.toString() ??
          json['escalatedById']?.toString() ??
          json['escalated_by_id']?.toString() ?? '',

      // Optional fields
      escalationReason: json['EscalationReason']?.toString() ??
          json['escalationReason']?.toString() ??
          json['reason']?.toString(),
      hoursElapsed: (json['HoursElapsed'] ??
          json['hoursElapsed'] ??
          json['hours_elapsed'] ??
          0)?.toDouble(),
      escalationNotes: json['EscalationNotes']?.toString() ??
          json['escalationNotes']?.toString() ??
          json['escalation_notes']?.toString(),
      resolved: json['Resolved'] ?? json['resolved'] ?? false,

      // Dates
      escalatedAt: _parseDateTime(json['EscalatedAt'] ?? json['escalatedAt'] ?? json['escalated_at']),
      resolvedAt: json['ResolvedAt'] != null
          ? _parseDateTime(json['ResolvedAt'])
          : (json['resolvedAt'] != null
          ? _parseDateTime(json['resolvedAt'])
          : (json['resolved_at'] != null
          ? _parseDateTime(json['resolved_at'])
          : null)),

      // Nested complaint data (if available)
      complaintNumber: json['Complaint'] != null && json['Complaint'] is Map
          ? json['Complaint']['ComplaintNumber']?.toString()
          : (json['ComplaintNumber']?.toString() ??
          json['complaintNumber']?.toString()),
      complaintTitle: json['Complaint'] != null && json['Complaint'] is Map
          ? json['Complaint']['Title']?.toString()
          : (json['ComplaintTitle']?.toString() ??
          json['complaintTitle']?.toString() ??
          json['title']?.toString()),

      // Nested user names (if available)
      escalatedFromName: json['EscalatedFrom'] != null && json['EscalatedFrom'] is Map
          ? json['EscalatedFrom']['FullName']?.toString()
          : (json['escalatedFromName']?.toString() ??
          json['from_name']?.toString()),
      escalatedToName: json['EscalatedTo'] != null && json['EscalatedTo'] is Map
          ? json['EscalatedTo']['FullName']?.toString()
          : (json['escalatedToName']?.toString() ??
          json['to_name']?.toString()),
      escalatedByName: json['EscalatedBy'] != null && json['EscalatedBy'] is Map
          ? json['EscalatedBy']['FullName']?.toString()
          : (json['escalatedByName']?.toString() ??
          json['by_name']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'escalationId': escalationId,
      'complaintId': complaintId,
      'escalationLevel': escalationLevel,
      'escalatedFromId': escalatedFromId,
      'escalatedToId': escalatedToId,
      'escalatedById': escalatedById,
      'escalationReason': escalationReason,
      'hoursElapsed': hoursElapsed,
      'escalationNotes': escalationNotes,
      'resolved': resolved,
      'escalatedAt': escalatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  String getStatusText() {
    if (resolved) return 'Resolved';
    switch (escalationLevel) {
      case 1: return 'Level 1 - Zone Manager';
      case 2: return 'Level 2 - Department Head';
      case 3: return 'Level 3 - Executive';
      default: return 'Level $escalationLevel';
    }
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(escalatedAt);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String getPriorityText() {
    if (hoursElapsed == null) return 'Normal';
    if (hoursElapsed! >= 72) return 'Critical';
    if (hoursElapsed! >= 48) return 'High';
    if (hoursElapsed! >= 24) return 'Medium';
    return 'Normal';
  }

  Color getPriorityColor() {
    switch (getPriorityText()) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.amber;
      default: return Colors.green;
    }
  }
}