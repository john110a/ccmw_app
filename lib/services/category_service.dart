// lib/services/category_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CategoryService {
  // Get all complaint categories
  Future<List<dynamic>> getAllCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/complaint-categories'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Get categories by department
  Future<List<dynamic>> getCategoriesByDepartment(String departmentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/complaint-categories/department/$departmentId'),
      headers: ApiConfig.getHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }
}