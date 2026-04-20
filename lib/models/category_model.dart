// lib/models/category_model.dart

class Category {
  final String categoryId;
  final String categoryName;
  final String? categoryCode;
  final String? description;
  final String? iconName;
  final String? colorCode;
  final int priorityWeight;
  final int expectedResolutionTimeHours;  // ADD THIS PROPERTY
  final bool isActive;
  final DateTime createdAt;
  final String? departmentId;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.categoryCode,
    this.description,
    this.iconName,
    this.colorCode,
    required this.priorityWeight,
    required this.expectedResolutionTimeHours,  // ADD THIS
    required this.isActive,
    required this.createdAt,
    this.departmentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id']?.toString() ??
          json['categoryId']?.toString() ??
          '',
      categoryName: json['category_name'] ??
          json['categoryName'] ??
          '',
      categoryCode: json['category_code']?.toString() ??
          json['categoryCode']?.toString(),
      description: json['description']?.toString(),
      iconName: json['icon_name']?.toString() ??
          json['iconName']?.toString(),
      colorCode: json['color_code']?.toString() ??
          json['colorCode']?.toString(),
      priorityWeight: json['priority_weight'] ??
          json['priorityWeight'] ??
          0,
      expectedResolutionTimeHours: json['expected_resolution_time_hours'] ??
          json['expectedResolutionTimeHours'] ??
          24,
      isActive: json['is_active'] ??
          json['isActive'] ??
          true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now()),
      departmentId: json['department_id']?.toString() ??
          json['departmentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_code': categoryCode,
      'description': description,
      'icon_name': iconName,
      'color_code': colorCode,
      'priority_weight': priorityWeight,
      'expected_resolution_time_hours': expectedResolutionTimeHours,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'department_id': departmentId,
    };
  }
}