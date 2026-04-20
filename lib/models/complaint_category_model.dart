// lib/models/complaint_category_model.dart
class ComplaintCategory {
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

  ComplaintCategory({
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
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) {
    return ComplaintCategory(
      categoryId: json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
      categoryName: json['categoryName'] ?? json['category_name'] ?? '',
      categoryCode: json['categoryCode']?.toString() ??
          json['category_code']?.toString(),
      description: json['description'] ?? '',
      iconName: json['iconName']?.toString() ?? json['icon_name']?.toString(),
      colorCode: json['colorCode']?.toString() ?? json['color_code']?.toString(),
      priorityWeight: json['priorityWeight'] ?? json['priority_weight'] ?? 0,
      expectedResolutionTimeHours:
      json['expectedResolutionTimeHours'] ?? json['expected_resolution_hours'] ?? 24,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryCode': categoryCode,
      'description': description,
      'iconName': iconName,
      'colorCode': colorCode,
      'priorityWeight': priorityWeight,
      'expectedResolutionTimeHours': expectedResolutionTimeHours,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}