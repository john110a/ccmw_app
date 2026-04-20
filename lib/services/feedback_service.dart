// lib/services/feedback_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback_model.dart';
import 'api_config.dart';
import 'AuthService.dart';

class FeedbackService {
  final AuthService _authService = AuthService();

  // =====================================================
  // SUBMIT FEEDBACK FOR A COMPLAINT
  // =====================================================
  Future<Map<String, dynamic>> submitFeedback(FeedbackRequest request) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/feedback/submit'),
        headers: ApiConfig.getHeaders(),
        body: json.encode({
          ...request.toJson(),
          'citizenId': userId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit feedback');
      }
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // =====================================================
  // GET FEEDBACK FOR A SPECIFIC COMPLAINT
  // =====================================================
  Future<List<Feedback>> getComplaintFeedback(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/feedback/complaint/$complaintId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Feedback.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading feedback: $e');
      return [];
    }
  }

  // =====================================================
  // GET FEEDBACK STATISTICS FOR A COMPLAINT
  // =====================================================
  Future<Map<String, dynamic>> getFeedbackStats(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/feedback/stats/$complaintId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'totalCount': 0,
          'averageRating': 0,
          'ratingDistribution': {
            'oneStar': 0,
            'twoStar': 0,
            'threeStar': 0,
            'fourStar': 0,
            'fiveStar': 0,
          }
        };
      }
    } catch (e) {
      print('❌ Error loading feedback stats: $e');
      return {
        'totalCount': 0,
        'averageRating': 0,
        'ratingDistribution': {
          'oneStar': 0,
          'twoStar': 0,
          'threeStar': 0,
          'fourStar': 0,
          'fiveStar': 0,
        }
      };
    }
  }

  // =====================================================
  // GET MY FEEDBACK (for current user)
  // =====================================================
  Future<List<Feedback>> getMyFeedback() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      // This endpoint might need to be implemented in your backend
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/feedback/user/$userId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Feedback.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error loading my feedback: $e');
      return [];
    }
  }
}