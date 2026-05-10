// lib/models/category_model.dart

class Category {
  final String categoryId;
  final String categoryName;
  final String? categoryCode;
  final String? description;
  final String? iconName;
  final String? colorCode;
  final int priorityWeight;
  final int expectedResolutionTimeHours;
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
    required this.expectedResolutionTimeHours,
    required this.isActive,
    required this.createdAt,
    this.departmentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Debug print to see what's coming from API
    print('🔍 Parsing category: ${json['CategoryName'] ?? json['categoryName']}');

    return Category(
      // FIXED: Try PascalCase first (from your backend), then camelCase, then snake_case
      categoryId: json['CategoryId']?.toString() ??
          json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
      categoryName: json['CategoryName'] ??
          json['categoryName'] ??
          json['category_name'] ??
          '',
      categoryCode: json['CategoryCode']?.toString() ??
          json['categoryCode']?.toString() ??
          json['category_code']?.toString(),
      description: json['Description']?.toString() ??
          json['description']?.toString(),
      iconName: json['IconName']?.toString() ??
          json['iconName']?.toString() ??
          json['icon_name']?.toString(),
      colorCode: json['ColorCode']?.toString() ??
          json['colorCode']?.toString() ??
          json['color_code']?.toString(),
      priorityWeight: json['PriorityWeight'] ??
          json['priorityWeight'] ??
          json['priority_weight'] ??
          0,
      expectedResolutionTimeHours: json['ExpectedResolutionTimeHours'] ??
          json['expectedResolutionTimeHours'] ??
          json['expected_resolution_time_hours'] ??
          24,
      isActive: json['IsActive'] ??
          json['isActive'] ??
          json['is_active'] ??
          true,
      createdAt: _parseDateTime(json['CreatedAt'] ?? json['createdAt'] ?? json['created_at']),
      departmentId: json['DepartmentId']?.toString() ??
          json['departmentId']?.toString() ??
          json['department_id']?.toString(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'CategoryId': categoryId,
      'CategoryName': categoryName,
      'CategoryCode': categoryCode,
      'Description': description,
      'IconName': iconName,
      'ColorCode': colorCode,
      'PriorityWeight': priorityWeight,
      'ExpectedResolutionTimeHours': expectedResolutionTimeHours,
      'IsActive': isActive,
      'CreatedAt': createdAt.toIso8601String(),
      'DepartmentId': departmentId,
    };
  }
}