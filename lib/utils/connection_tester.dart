// lib/utils/connection_tester.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class ConnectionTester {
  static Future<void> testConnection() async {
    print('🔍 Testing API Connection...');
    print('📡 Base URL: ${ApiConfig.baseUrl}');

    try {
      // Test 1: Check if server is reachable
      final testUrl = Uri.parse('${ApiConfig.baseUrl.replaceAll('/api', '')}/');
      print('Test 1: Checking server at $testUrl');

      try {
        final response = await http.get(testUrl).timeout(const Duration(seconds: 5));
        print('✅ Server reachable! Status: ${response.statusCode}');
      } catch (e) {
        print('❌ Server not reachable: $e');
        print('   Make sure your backend is running');
        return;
      }

      // Test 2: Try a simple API endpoint
      print('\nTest 2: Testing /api/user/all endpoint');
      final apiUrl = Uri.parse('${ApiConfig.baseUrl}/user/all');
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 5));

      print('✅ API responded! Status: ${response.statusCode}');
      print('Response: ${response.body}');

    } on SocketException {
      print('❌ Network Error: Cannot reach server');
      print('   Check:');
      print('   1. Is backend running?');
      print('   2. Is IP address correct?');
      print('   3. Are you on same network?');
      print('   4. Firewall blocking?');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}