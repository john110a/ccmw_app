// lib/services/citizen_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/citizen_profile_model.dart';
import '../models/appeal_model.dart';
import 'api_config.dart';
import 'AuthService.dart';

class CitizenService {
  final AuthService _authService = AuthService();

  // =====================================================
  // 1. GET CITIZEN PROFILE
  // =====================================================
  Future<Map<String, dynamic>> getCitizenProfile() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/$userId'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // =====================================================
  // 2. UPDATE PROFILE
  // =====================================================
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profilePhotoUrl,
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final Map<String, dynamic> updateData = {};
    if (fullName != null) updateData['fullName'] = fullName;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (address != null) updateData['address'] = address;
    if (profilePhotoUrl != null) updateData['profilePhotoUrl'] = profilePhotoUrl;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/user/$userId'),
      headers: ApiConfig.getHeaders(),
      body: json.encode(updateData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // =====================================================
  // 3. GET LEADERBOARD
  // =====================================================
  Future<List<dynamic>> getLeaderboard({String period = 'all', int top = 20}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/leaderboard/citizens?period=$period&top=$top'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['leaderboard'] ?? data['Leaderboard'] ?? [];
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  // =====================================================
  // 4. FILE APPEAL
  // =====================================================
  Future<Map<String, dynamic>> fileAppeal({
    required String complaintId,
    required String appealReason,
    String? supportingDocuments,
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final appealData = {
      'complaintId': complaintId,
      'citizenId': userId,
      'appealReason': appealReason,
      'appealStatus': 'Pending',
      'supportingDocuments': supportingDocuments,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appeals/file'),
      headers: ApiConfig.getHeaders(),
      body: json.encode(appealData),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to file appeal');
    }
  }

  // =====================================================
  // 5. GET MY APPEALS
  // =====================================================
  Future<List<dynamic>> getMyAppeals() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appeals/my/$userId'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load appeals');
    }
  }

  // =====================================================
  // 6. UPVOTE COMPLAINT
  // =====================================================
  Future<bool> upvoteComplaint(String complaintId) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final upvoteData = {
      'complaintId': complaintId,
      'citizenId': userId,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/complaint-upvotes/upvote'),
      headers: ApiConfig.getHeaders(),
      body: json.encode(upvoteData),
    ).timeout(const Duration(seconds: 10));

    return response.statusCode == 200;
  }

  // =====================================================
  // 7. ACCEPT RESOLUTION
  // =====================================================
  Future<bool> acceptResolution(String complaintId) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/complaint-verification/$complaintId/accept?citizenId=$userId'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    return response.statusCode == 200;
  }

  // =====================================================
  // 8. REJECT RESOLUTION
  // =====================================================
  Future<bool> rejectResolution(String complaintId, String reason) async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/complaint-verification/$complaintId/reject?citizenId=$userId'),
      headers: ApiConfig.getHeaders(),
      body: json.encode(reason),
    ).timeout(const Duration(seconds: 10));

    return response.statusCode == 200;
  }
}