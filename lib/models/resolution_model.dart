// lib/models/resolution_model.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class Resolution {
  final String id;
  final String complaintId;
  final String complaintNumber;
  final String title;
  final String location;
  final String category;
  final String resolvedBy;
  final String submittedAt;
  final String status;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String resolutionNotes;
  final String? flagReason;

  Resolution({
    required this.id,
    required this.complaintId,
    required this.complaintNumber,
    required this.title,
    required this.location,
    required this.category,
    required this.resolvedBy,
    required this.submittedAt,
    required this.status,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    required this.resolutionNotes,
    this.flagReason,
  });

  factory Resolution.fromJson(Map<String, dynamic> json) {
    return Resolution(
      id: json['id']?.toString() ??
          json['resolutionId']?.toString() ??
          json['complaintId']?.toString() ?? '',
      complaintId: json['complaintId']?.toString() ??
          json['complaint_id']?.toString() ?? '',
      complaintNumber: json['complaintNumber']?.toString() ??
          json['complaint_number']?.toString() ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      category: json['category'] ?? json['Category'] ?? '',
      resolvedBy: json['resolvedBy']?.toString() ??
          json['resolved_by']?.toString() ?? '',
      submittedAt: json['submittedAt']?.toString() ??
          json['submitted_at']?.toString() ?? '',
      status: json['verificationStatus'] ??
          json['status'] ?? 'Pending',
      beforePhotoUrl: json['beforePhoto'] ??
          json['before_photo'] ??
          json['beforePhotoUrl'],
      afterPhotoUrl: json['afterPhoto'] ??
          json['after_photo'] ??
          json['afterPhotoUrl'],
      resolutionNotes: json['resolutionNotes'] ??
          json['notes'] ?? '',
      flagReason: json['flagReason'] ??
          json['flag_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'complaintNumber': complaintNumber,
      'title': title,
      'location': location,
      'category': category,
      'resolvedBy': resolvedBy,
      'submittedAt': submittedAt,
      'status': status,
      'beforePhotoUrl': beforePhotoUrl,
      'afterPhotoUrl': afterPhotoUrl,
      'resolutionNotes': resolutionNotes,
      'flagReason': flagReason,
    };
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'flagged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}