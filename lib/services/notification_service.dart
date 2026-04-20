// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart' as Model;
import 'api_config.dart';
import 'AuthService.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  /// Get notifications for current user
  Future<List<Model.Notification>> getUserNotifications() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        print('⚠️ No user ID found');
        return [];
      }

      print('📡 Fetching notifications for user: $userId');
      final url = '${ApiConfig.baseUrl}/notifications/$userId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle response format - your controller returns a direct List
        List<dynamic> notificationsList = [];

        if (responseData is List) {
          notificationsList = responseData;
        } else if (responseData is Map && responseData.containsKey('notifications')) {
          notificationsList = responseData['notifications'] as List? ?? [];
        } else if (responseData is Map && responseData.containsKey('data')) {
          notificationsList = responseData['data'] as List? ?? [];
        }

        print('✅ Found ${notificationsList.length} notifications');
        return notificationsList.map((json) => Model.Notification.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('ℹ️ No notifications found (404)');
        return [];
      } else {
        print('❌ Failed to load notifications: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      return [];
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      return [];
    } catch (e) {
      print('❌ Unexpected error: $e');
      return [];
    }
  }

  /// Get notifications for a specific user
  Future<List<Model.Notification>> getUserNotificationsById(String userId) async {
    try {
      print('📡 Fetching notifications for user: $userId');
      final url = '${ApiConfig.baseUrl}/notifications/$userId';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> notificationsList = [];

        if (responseData is List) {
          notificationsList = responseData;
        } else if (responseData is Map && responseData.containsKey('notifications')) {
          notificationsList = responseData['notifications'] as List? ?? [];
        } else if (responseData is Map && responseData.containsKey('data')) {
          notificationsList = responseData['data'] as List? ?? [];
        }

        return notificationsList.map((json) => Model.Notification.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('ℹ️ No notifications found for user $userId');
        return [];
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      print('📡 Marking notification $notificationId as read');
      final url = '${ApiConfig.baseUrl}/notifications/mark-read/$notificationId';
      print('📍 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data['message'] ?? 'Notification marked as read'}');
        return true;
      } else {
        print('❌ Failed to mark as read: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      return false;
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return false;
    }
  }

  /// Mark all notifications as read for current user
  Future<bool> markAllAsRead() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        print('⚠️ No user ID found');
        return false;
      }

      print('📡 Marking all notifications as read for user: $userId');
      final url = '${ApiConfig.baseUrl}/notifications/mark-all-read/$userId';
      print('📍 URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data['message'] ?? 'All notifications marked as read'}');
        return true;
      } else {
        print('❌ Failed to mark all as read: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      print('📡 Deleting notification $notificationId');
      final url = '${ApiConfig.baseUrl}/notifications/$notificationId';
      print('📍 URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data['message'] ?? 'Notification deleted'}');
        return true;
      } else if (response.statusCode == 404) {
        print('⚠️ Notification not found');
        return false;
      } else {
        print('❌ Failed to delete notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Get unread count for current user
  Future<int> getUnreadCount() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        print('⚠️ No user ID found');
        return 0;
      }

      print('📡 Fetching unread count for user: $userId');
      final url = '${ApiConfig.baseUrl}/notifications/$userId/unread-count';
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 5));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int count = data['unreadCount'] ?? 0;
        print('✅ Unread count: $count');
        return count;
      } else {
        print('⚠️ Unread count endpoint failed, calculating manually...');
        // Fallback: calculate from notifications list
        final notifications = await getUserNotifications();
        final unreadCount = notifications.where((n) => !n.isRead).length;
        print('✅ Manual unread count: $unreadCount');
        return unreadCount;
      }
    } catch (e) {
      print('❌ Error getting unread count: $e');
      // Fallback: calculate from notifications list
      try {
        final notifications = await getUserNotifications();
        return notifications.where((n) => !n.isRead).length;
      } catch (innerError) {
        print('❌ Fallback also failed: $innerError');
        return 0;
      }
    }
  }

  /// Send a notification (admin/staff only)
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String message,
    String notificationType = 'System',
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      print('📡 Sending notification to user: $userId');
      final url = '${ApiConfig.baseUrl}/notifications/send';
      print('📍 URL: $url');

      final body = {
        'userId': userId,
        'title': title,
        'message': message,
        'notificationType': notificationType,
        'referenceType': referenceType,
        'referenceId': referenceId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data['message'] ?? 'Notification sent'}');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return false;
    }
  }
}