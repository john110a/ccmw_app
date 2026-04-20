// lib/models/department_model.dart (Enhanced)
class Department {
  final String departmentId;
  final String departmentName;
  final String? departmentCode;
  final String? privatizationStatus;
  final String? contractorId;
  final double? performanceScore;
  final int? performanceRating;
  final int activeComplaintsCount;
  final int resolvedComplaintsCount;
  final int totalComplaintsCount;
  final double? averageResolutionTimeDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? headAdminId;

  Department({
    required this.departmentId,
    required this.departmentName,
    this.departmentCode,
    this.privatizationStatus,
    this.contractorId,
    this.performanceScore,
    this.performanceRating,
    required this.activeComplaintsCount,
    required this.resolvedComplaintsCount,
    required this.totalComplaintsCount,
    this.averageResolutionTimeDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.headAdminId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      // FIXED: Check for both capital D and lowercase d
      departmentId: json['DepartmentId']?.toString() ??
          json['departmentId']?.toString() ??
          json['department_id']?.toString() ?? '',
      departmentName: json['DepartmentName']?.toString() ??
          json['departmentName']?.toString() ??
          json['department_name']?.toString() ?? '',
      departmentCode: json['DepartmentCode']?.toString() ??
          json['departmentCode']?.toString() ??
          json['department_code']?.toString(),
      privatizationStatus: json['PrivatizationStatus']?.toString() ??
          json['privatizationStatus']?.toString() ??
          json['privatization_status']?.toString(),
      contractorId: json['ContractorId']?.toString() ??
          json['contractorId']?.toString() ??
          json['contractor_id']?.toString(),
      performanceScore: (json['PerformanceScore'] ??
          json['performanceScore'] ??
          json['performance_score'])?.toDouble(),
      performanceRating: json['PerformanceRating'] ??
          json['performanceRating'] ??
          json['performance_rating'],
      activeComplaintsCount: json['ActiveComplaintsCount'] ??
          json['activeComplaintsCount'] ??
          json['active_complaints_count'] ?? 0,
      resolvedComplaintsCount: json['ResolvedComplaintsCount'] ??
          json['resolvedComplaintsCount'] ??
          json['resolved_complaints_count'] ?? 0,
      totalComplaintsCount: json['TotalComplaintsCount'] ??
          json['totalComplaintsCount'] ??
          json['total_complaints_count'] ?? 0,
      averageResolutionTimeDays: (json['AverageResolutionTimeDays'] ??
          json['averageResolutionTimeDays'] ??
          json['average_resolution_time_days'])?.toDouble(),
      isActive: json['IsActive'] ??
          json['isActive'] ??
          json['is_active'] ?? true,
      createdAt: _parseDateTime(json['CreatedAt'] ??
          json['createdAt'] ??
          json['created_at']),
      updatedAt: _parseDateTime(json['UpdatedAt'] ??
          json['updatedAt'] ??
          json['updated_at']),
      description: json['Description']?.toString() ??
          json['description']?.toString(),
      headAdminId: json['HeadAdminId']?.toString() ??
          json['headAdminId']?.toString() ??
          json['head_admin_id']?.toString(),
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
      'DepartmentId': departmentId,
      'DepartmentName': departmentName,
      'DepartmentCode': departmentCode,
      'PrivatizationStatus': privatizationStatus,
      'ContractorId': contractorId,
      'PerformanceScore': performanceScore,
      'PerformanceRating': performanceRating,
      'ActiveComplaintsCount': activeComplaintsCount,
      'ResolvedComplaintsCount': resolvedComplaintsCount,
      'TotalComplaintsCount': totalComplaintsCount,
      'AverageResolutionTimeDays': averageResolutionTimeDays,
      'IsActive': isActive,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'Description': description,
      'HeadAdminId': headAdminId,
    };
  }
}