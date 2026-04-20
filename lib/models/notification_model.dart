// lib/models/notification_model.dart
import 'package:flutter/material.dart';

class Notification {
  final String notificationId;
  final String userId;
  final String? notificationType;
  final String? title;
  final String? message;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.notificationId,
    required this.userId,
    this.notificationType,
    this.title,
    this.message,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['notificationId']?.toString() ??
          json['notification_id']?.toString() ??
          json['NotificationId']?.toString() ?? '',
      userId: json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['UserId']?.toString() ?? '',
      notificationType: json['notificationType']?.toString() ??
          json['notification_type']?.toString() ??
          json['NotificationType']?.toString(),
      title: json['title']?.toString() ?? json['Title']?.toString(),
      message: json['message']?.toString() ?? json['Message']?.toString(),
      referenceType: json['referenceType']?.toString() ??
          json['reference_type']?.toString(),
      referenceId: json['referenceId']?.toString() ??
          json['reference_id']?.toString(),
      isRead: json['isRead'] ?? json['is_read'] ?? json['IsRead'] ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at'] ?? json['CreatedAt']),
      readAt: json['readAt'] != null
          ? _parseDateTime(json['readAt'])
          : (json['read_at'] != null
          ? _parseDateTime(json['read_at'])
          : (json['ReadAt'] != null ? _parseDateTime(json['ReadAt']) : null)),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// Get status color based on read state
  Color getStatusColor() {
    return isRead ? Colors.grey : Colors.orange;
  }
}