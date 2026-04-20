// lib/models/staff_profile_model.dart - Make properties mutable
class StaffProfile {
  // Database fields - CHANGE FROM final TO non-final
  String staffId;  // Removed 'final'
  String userId;   // Removed 'final'
  String? departmentId;
  String? zoneId;
  String? role;
  String? employeeId;
  DateTime? hireDate;
  int totalAssignments;
  int completedAssignments;
  int pendingAssignments;
  double averageResolutionTime;
  double performanceScore;
  bool isAvailable;

  // Joined fields
  String? fullName;
  String? email;
  String? phoneNumber;
  String? departmentName;

  StaffProfile({
    required this.staffId,
    required this.userId,
    this.departmentId,
    this.zoneId,
    this.role,
    this.employeeId,
    this.hireDate,
    required this.totalAssignments,
    required this.completedAssignments,
    required this.pendingAssignments,
    required this.averageResolutionTime,
    required this.performanceScore,
    required this.isAvailable,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.departmentName,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      staffId: json['staffId']?.toString() ??
          json['StaffId']?.toString() ??
          json['staff_id']?.toString() ?? '',
      userId: json['userId']?.toString() ??
          json['UserId']?.toString() ??
          json['user_id']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ??
          json['DepartmentId']?.toString() ??
          json['department_id']?.toString(),
      zoneId: json['zoneId']?.toString() ??
          json['ZoneId']?.toString() ??
          json['zone_id']?.toString(),
      role: json['role'] ?? json['Role'],
      employeeId: json['employeeId']?.toString() ??
          json['EmployeeId']?.toString() ??
          json['employee_id']?.toString(),
      hireDate: json['hireDate'] != null
          ? _parseDateTime(json['hireDate'])
          : (json['hire_date'] != null ? _parseDateTime(json['hire_date']) : null),
      totalAssignments: json['totalAssignments'] ??
          json['TotalAssignments'] ??
          json['total_assignments'] ?? 0,
      completedAssignments: json['completedAssignments'] ??
          json['CompletedAssignments'] ??
          json['completed_assignments'] ?? 0,
      pendingAssignments: json['pendingAssignments'] ??
          json['PendingAssignments'] ??
          json['pending_assignments'] ?? 0,
      averageResolutionTime: (json['averageResolutionTime'] ??
          json['AverageResolutionTime'] ??
          json['average_resolution_time'] ?? 0).toDouble(),
      performanceScore: (json['performanceScore'] ??
          json['PerformanceScore'] ??
          json['performance_score'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ??
          json['IsAvailable'] ??
          json['is_available'] ?? true,
      fullName: json['fullName'] ??
          json['FullName'] ??
          json['full_name'],
      email: json['email'] ?? json['Email'],
      phoneNumber: json['phoneNumber'] ??
          json['PhoneNumber'] ??
          json['phone_number'],
      departmentName: json['departmentName'] ??
          json['DepartmentName'] ??
          json['department_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staffId': staffId,
      'userId': userId,
      'departmentId': departmentId,
      'zoneId': zoneId,
      'role': role,
      'employeeId': employeeId,
      'hireDate': hireDate?.toIso8601String(),
      'totalAssignments': totalAssignments,
      'completedAssignments': completedAssignments,
      'pendingAssignments': pendingAssignments,
      'averageResolutionTime': averageResolutionTime,
      'performanceScore': performanceScore,
      'isAvailable': isAvailable,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  double get completionRate {
    if (totalAssignments == 0) return 0;
    return (completedAssignments / totalAssignments * 100);
  }
}