// lib/models/resolution_model.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_config.dart';

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

  /// Helper method to convert relative path to full URL
  static String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // If already a full URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Remove leading slash
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Get base URL without /api
    String baseUrl = ApiConfig.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    return '$baseUrl/$cleanPath';
  }

  factory Resolution.fromJson(Map<String, dynamic> json) {
    // Extract raw photo URLs first
    String? rawBeforeUrl = json['beforePhoto'] ??
        json['before_photo'] ??
        json['beforePhotoUrl'] ??
        json['BeforePhotoUrl'];

    String? rawAfterUrl = json['afterPhoto'] ??
        json['after_photo'] ??
        json['afterPhotoUrl'] ??
        json['AfterPhotoUrl'];

    return Resolution(
      id: json['id']?.toString() ??
          json['resolutionId']?.toString() ??
          json['complaintId']?.toString() ??
          json['Id']?.toString() ??
          '',
      complaintId: json['complaintId']?.toString() ??
          json['complaint_id']?.toString() ??
          json['ComplaintId']?.toString() ??
          '',
      complaintNumber: json['complaintNumber']?.toString() ??
          json['complaint_number']?.toString() ??
          json['ComplaintNumber']?.toString() ??
          '',
      title: json['title'] ?? json['Title'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      category: json['category'] ?? json['Category'] ?? '',
      resolvedBy: json['resolvedBy']?.toString() ??
          json['resolved_by']?.toString() ??
          json['ResolvedBy']?.toString() ??
          'Unknown',
      submittedAt: json['submittedAt']?.toString() ??
          json['submitted_at']?.toString() ??
          json['SubmittedAt']?.toString() ??
          '',
      status: json['verificationStatus'] ??
          json['status'] ??
          json['Status'] ??
          'Pending',
      // Convert relative paths to full URLs
      beforePhotoUrl: _getFullImageUrl(rawBeforeUrl),
      afterPhotoUrl: _getFullImageUrl(rawAfterUrl),
      resolutionNotes: json['resolutionNotes'] ??
          json['notes'] ??
          json['ResolutionNotes'] ??
          '',
      flagReason: json['flagReason'] ??
          json['flag_reason'] ??
          json['FlagReason']?.toString(),
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