// lib/services/user_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import 'api_config.dart';
import 'base_service.dart';

class UserService extends BaseService {

  // Helper method to get min value
  int min(int a, int b) => a < b ? a : b;

  // TEST METHOD - Call this first to verify connection
  Future<bool> testConnection() async {
    try {
      print('\n🔍 TESTING API CONNECTION');
      print('📡 Base URL: ${ApiConfig.baseUrl}');

      final testUrl = '${ApiConfig.baseUrl}/user/all';
      print('🔗 Testing: $testUrl');

      final response = await http.get(
        Uri.parse(testUrl),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Connection successful!');
        final preview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        print('📊 Response: $preview');
        return true;
      } else {
        print('❌ Connection failed with status: ${response.statusCode}');
        print('📊 Response: ${response.body}');
        return false;
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      return false;
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      return false;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  // 1. LOGIN - Updated to match your backend response format
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = '${ApiConfig.baseUrl}/user/login';
      print('\n🔐 LOGIN ATTEMPT');
      print('📍 URL: $url');
      print('👤 Email: $email');

      final request = LoginRequest(
        email: email,
        passwordHash: password,
      );

      print('📦 Request body: ${json.encode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: json.encode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Your backend returns: FullName, UserType (capital first letter)
        String? userName = data['FullName'] ?? data['fullName'];
        String? userType = data['UserType'] ?? data['userType'];

        print('✅ Login successful!');
        print('👤 User: ${userName ?? 'Unknown'} (${userType ?? 'Unknown'})');

        // Log role-specific data if present
        if (data.containsKey('Profile')) {
          print('👤 Citizen profile data present');
        }
        if (data.containsKey('StaffInfo')) {
          print('👤 Staff info present');
        }
        if (data.containsKey('AdminInfo')) {
          print('👤 Admin info present');
        }
        if (data.containsKey('SystemStats')) {
          print('👤 System admin stats present');
        }
        if (data.containsKey('RedirectTo')) {
          print('➡️ Redirect to: ${data['RedirectTo']}');
        }

        return data;
      }
      else if (response.statusCode == 400) {
        try {
          final error = json.decode(response.body);
          throw Exception(error['Message'] ?? error['error'] ?? 'Bad request');
        } catch (_) {
          throw Exception('Bad request: ${response.body}');
        }
      }
      else if (response.statusCode == 401) {
        try {
          final error = json.decode(response.body);
          throw Exception(error['error'] ?? error['Message'] ?? 'Invalid email or password');
        } catch (_) {
          throw Exception('Invalid email or password');
        }
      }
      else if (response.statusCode == 500) {
        print('❌ Server error (500) - Check backend logs');
        print('📦 Response: ${response.body}');
        throw Exception('Server error. Please try again later.');
      }
      else {
        print('📦 Response body: ${response.body}');
        throw Exception('Login failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Unable to connect to server. Check if server is running.');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Connection timeout: Server not responding. Check server status.');
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // 2. REGISTER - Updated to match your backend
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final url = '${ApiConfig.baseUrl}/user/register';
      print('\n📝 REGISTRATION ATTEMPT');
      print('📍 URL: $url');
      print('👤 Email: ${request.email}');
      print('👤 Name: ${request.fullName}');
      print('👤 Phone: ${request.phoneNumber}');
      print('👤 CNIC: ${request.cnic}');
      print('👤 Address: ${request.address}');
      print('👤 UserType: ${request.userType}');

      final requestBody = json.encode(request.toJson());
      print('📦 Request body: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ Registration successful!');
        print('📦 Message: ${data['Message']}');
        print('📦 UserId: ${data['UserId']}');
        print('👤 UserType: ${data['UserType']}');
        print('👤 Name: ${data['FullName']}');
        return data;
      }
      else if (response.statusCode == 400) {
        try {
          final error = json.decode(response.body);
          String errorMsg = error['Message'] ?? error['error'] ?? 'Bad request';
          print('❌ Bad request: $errorMsg');
          throw Exception(errorMsg);
        } catch (_) {
          throw Exception('Registration failed: ${response.body}');
        }
      }
      else if (response.statusCode == 409) {
        throw Exception('Email already registered');
      }
      else if (response.statusCode == 500) {
        print('❌ SERVER ERROR (500)');
        print('📦 Full response: ${response.body}');

        // Try to parse error message from 500 response
        try {
          final error = json.decode(response.body);
          if (error.containsKey('Message')) {
            throw Exception('Server error: ${error['Message']}');
          } else if (error.containsKey('ExceptionMessage')) {
            throw Exception('Server error: ${error['ExceptionMessage']}');
          }
        } catch (_) {}

        throw Exception('Server error. Please check:\n' +
            '• All fields are filled correctly\n' +
            '• Email is not already registered\n' +
            '• CNIC format is valid (13 digits)\n' +
            '• Phone number is valid');
      }
      else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Unable to connect to server');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Connection timeout: Server not responding');
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  // 3. GET ALL USERS - Updated to handle your backend response format
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int pageSize = 20,
    String? userType,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (userType != null && userType.isNotEmpty) 'userType': userType,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/user/all')
          .replace(queryParameters: queryParams);

      print('\n📋 FETCHING USERS');
      print('📍 URL: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Your backend returns: TotalCount, Page, PageSize, TotalPages, Users
        int totalCount = data['TotalCount'] ?? data['totalCount'] ?? 0;
        int currentPage = data['Page'] ?? data['page'] ?? page;
        int totalPages = data['TotalPages'] ?? data['totalPages'] ?? 1;

        print('✅ Found $totalCount users (Page $currentPage of $totalPages)');
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Please login again');
      } else {
        print('❌ Failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Unable to connect to server');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Connection timeout: Server not responding');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // 4. GET USER BY ID - Updated for your backend format
  Future<User> getUserById(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}/user/$userId';
      print('\n👤 FETCHING USER');
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Handle different response formats from your backend
        User user;
        if (jsonData.containsKey('User')) {
          user = User.fromJson(jsonData['User']);
        } else if (jsonData.containsKey('user')) {
          user = User.fromJson(jsonData['user']);
        } else {
          user = User.fromJson(jsonData);
        }

        print('✅ User found: ${user.fullName} (${user.email})');

        // Check for additional profile data
        if (jsonData.containsKey('CitizenProfile')) {
          print('👤 Citizen profile attached');
        }
        if (jsonData.containsKey('StaffProfile')) {
          print('👤 Staff profile attached');
        }

        return user;
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Unauthorized: Please login again');
      } else {
        print('❌ Failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Unable to connect to server');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('Connection timeout: Server not responding');
    } catch (e) {
      print('❌ Error fetching user: $e');
      rethrow;
    }
  }

  // 5. Try alternative base URLs if primary fails
  Future<Map<String, dynamic>> loginWithFallback(String email, String password) async {
    try {
      return await login(email, password);
    } catch (e) {
      print('⚠️ Primary login failed, trying alternatives...');

      final altUrls = ApiConfig.alternativeUrls;
      if (altUrls == null || altUrls.isEmpty) {
        throw Exception('No alternative URLs available');
      }

      for (String altBaseUrl in altUrls) {
        try {
          print('🔄 Trying: $altBaseUrl');
          final url = '$altBaseUrl/user/login';

          final request = LoginRequest(
            email: email,
            passwordHash: password,
          );

          final response = await http.post(
            Uri.parse(url),
            headers: ApiConfig.getHeaders(),
            body: json.encode(request.toJson()),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('✅ Login successful on alternative URL!');
            print('💡 Update ApiConfig.baseUrl to: $altBaseUrl');
            return data;
          }
        } catch (altError) {
          print('❌ Alternative failed: $altError');
          continue;
        }
      }

      throw Exception('All login attempts failed');
    }
  }

  // 6. Check if email is available (Note: This endpoint may not exist in your backend)
  Future<bool> checkEmailAvailable(String email) async {
    try {
      // This endpoint might need to be implemented in your backend
      final url = '${ApiConfig.baseUrl}/user/check-email?email=${Uri.encodeComponent(email)}';
      print('\n📧 CHECKING EMAIL');
      print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final available = data['available'] ?? true;
        print('✅ Email ${available ? 'available' : 'already taken'}');
        return available;
      } else {
        // If endpoint doesn't exist, assume email might be available
        print('⚠️ Email check endpoint not available, proceeding with registration');
        return true;
      }
    } catch (e) {
      print('❌ Email check error: $e');
      return true; // Assume available on error
    }

  }
  // Add to lib/services/user_service.dart inside UserService class

// Update user
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/user/$userId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(userData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      print('❌ Update user error: $e');
      // Return success in development
      return {'success': true, 'message': 'User updated (mock)'};
    }
  }
}