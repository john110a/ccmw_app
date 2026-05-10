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

  // Add these to category_service.dart:

// =====================================================
// CREATE CATEGORY (Admin only)
// =====================================================
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/complaint-categories'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(categoryData),
      ).timeout(const Duration(seconds: 10));

      print('📡 Create category response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating category: $e');
      throw Exception('Network error: $e');
    }
  }

// =====================================================
// UPDATE CATEGORY (Admin only)
// =====================================================
  Future<Map<String, dynamic>> updateCategory(String categoryId, Map<String, dynamic> categoryData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/complaint-categories/$categoryId'),
        headers: ApiConfig.getHeaders(),
        body: json.encode(categoryData),
      ).timeout(const Duration(seconds: 10));

      print('📡 Update category response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update category: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating category: $e');
      throw Exception('Network error: $e');
    }
  }

// =====================================================
// DELETE CATEGORY (Soft delete - Admin only)
// =====================================================
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/complaint-categories/$categoryId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('📡 Delete category response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting category: $e');
      return false;
    }
  }

// =====================================================
// GET CATEGORY BY ID
// =====================================================
  Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaint-categories/$categoryId'),
        headers: ApiConfig.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load category');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}