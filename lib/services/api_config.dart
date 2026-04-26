// lib/services/api_config.dart
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ===== YOUR COMPUTER'S IP ADDRESS =====
  static const String _computerIp = '192.168.10.4'; // Your PC LAN IP

  // ===== BACKEND PORT - CHANGED TO 80 (IIS DEFAULT) =====
  static const int _backendPort = 80; // CHANGED: IIS uses port 80, not 8080

  /// Returns the base URL depending on platform
  static String get baseUrl {
    debugPrint('📱 Platform: ${Platform.operatingSystem}');

    String url;

    if (Platform.isAndroid || Platform.isIOS) {
      // Physical devices on same LAN - port 80 doesn't need to be specified
      url = 'http://$_computerIp/CCMW/api'; // REMOVED: port 80 is default
    } else {
      // Emulator / Simulator - port 80 doesn't need to be specified
      url = 'http://localhost/CCMW/api';// REMOVED: port 80 is default
    }

    debugPrint('🌐 API Base URL: $url');
    return url;
  }

  /// Alternative method if you want to try multiple ports (for debugging)
  static List<String> get alternativeUrls {
    return [
      'http://$_computerIp/CCMW/api',      // port 80 (default)
      'http://$_computerIp:8080/CCMW/api', // port 8080
      'http://$_computerIp:5000/CCMW/api', // port 5000
      'http://$_computerIp:44376/CCMW/api', // old HTTPS port
    ];
  }

  /// Default headers for API calls
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Helper method to print configuration for debugging
  static void printConfig() {
    debugPrint('''
    ===== API CONFIGURATION =====
    Platform: ${Platform.operatingSystem}
    Base URL: $baseUrl
    Alternative URLs:
      ${alternativeUrls.join('\n      ')}
    ============================    ''');
  }

  /// Test connection to backend API
  static Future<bool> testConnection() async {
    // Try primary URL first
    try {
      final testUrl = '$baseUrl/user/all';
      debugPrint('🔍 Testing primary connection to: $testUrl');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(testUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('✅ Connection successful!');
        client.close();
        return true;
      } else {
        debugPrint('❌ Primary connection failed with status: ${response.statusCode}');
        client.close();
      }
    } catch (e) {
      debugPrint('❌ Primary connection failed: $e');
    }

    // Try alternative URLs
    debugPrint('🔄 Trying alternative URLs...');
    for (String altUrl in alternativeUrls) {
      try {
        final testUrl = '$altUrl/user/all';
        debugPrint('🔍 Testing: $testUrl');

        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(testUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          debugPrint('✅ Connection successful on: $altUrl');
          client.close();
          return true;
        }
        client.close();
      } catch (e) {
        debugPrint('❌ Failed: $altUrl - $e');
      }
    }

    debugPrint('❌ All connection attempts failed');
    return false;
  }

  /// Test specific endpoint
  static Future<void> testEndpoint(String endpoint) async {
    final url = '$baseUrl$endpoint';
    try {
      debugPrint('🔍 Testing endpoint: $url');

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('✅ Endpoint working: $url');

        // Read response body
        final stringData = await response.transform(utf8.decoder).join();
        debugPrint('📦 Response: $stringData');
      } else {
        debugPrint('❌ Endpoint failed with status: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      debugPrint('❌ Endpoint error: $e');
    }
  }
}