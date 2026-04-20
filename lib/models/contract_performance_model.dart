// lib/models/contract_performance_model.dart
class ContractPerformance {
  final String performanceId;
  final String contractorId;
  final String departmentId;
  final DateTime reviewPeriodStart;
  final DateTime reviewPeriodEnd;
  final int complaintsHandled;
  final int complaintsResolved;
  final double averageResolutionTimeDays;
  final double slaComplianceRate;
  final double citizenSatisfactionScore;
  final double performanceScore;
  final double penaltiesIncurred;
  final double bonusesEarned;
  final String? reviewNotes;
  final String reviewedById;
  final DateTime reviewedAt;
  final DateTime createdAt;

  ContractPerformance({
    required this.performanceId,
    required this.contractorId,
    required this.departmentId,
    required this.reviewPeriodStart,
    required this.reviewPeriodEnd,
    required this.complaintsHandled,
    required this.complaintsResolved,
    required this.averageResolutionTimeDays,
    required this.slaComplianceRate,
    required this.citizenSatisfactionScore,
    required this.performanceScore,
    required this.penaltiesIncurred,
    required this.bonusesEarned,
    this.reviewNotes,
    required this.reviewedById,
    required this.reviewedAt,
    required this.createdAt,
  });

  factory ContractPerformance.fromJson(Map<String, dynamic> json) {
    return ContractPerformance(
      performanceId: json['performance_id']?.toString() ??
          json['performanceId']?.toString() ?? '',
      contractorId: json['contractor_id']?.toString() ??
          json['contractorId']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ??
          json['departmentId']?.toString() ?? '',
      reviewPeriodStart: _parseDateTime(json['review_period_start'] ??
          json['reviewPeriodStart']),
      reviewPeriodEnd: _parseDateTime(json['review_period_end'] ??
          json['reviewPeriodEnd']),
      complaintsHandled: json['complaints_handled'] ??
          json['complaintsHandled'] ?? 0,
      complaintsResolved: json['complaints_resolved'] ??
          json['complaintsResolved'] ?? 0,
      averageResolutionTimeDays: _parseDouble(json['average_resolution_time_days'] ??
          json['averageResolutionTimeDays']),
      slaComplianceRate: _parseDouble(json['sla_compliance_rate'] ??
          json['slaComplianceRate']),
      citizenSatisfactionScore: _parseDouble(json['citizen_satisfaction_score'] ??
          json['citizenSatisfactionScore']),
      performanceScore: _parseDouble(json['performance_score'] ??
          json['performanceScore']),
      penaltiesIncurred: _parseDouble(json['penalties_incurred'] ??
          json['penaltiesIncurred']),
      bonusesEarned: _parseDouble(json['bonuses_earned'] ??
          json['bonusesEarned']),
      reviewNotes: json['review_notes'] ?? json['reviewNotes'],
      reviewedById: json['reviewed_by_id']?.toString() ??
          json['reviewedById']?.toString() ?? '',
      reviewedAt: _parseDateTime(json['reviewed_at'] ?? json['reviewedAt']),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'performance_id': performanceId,
      'contractor_id': contractorId,
      'department_id': departmentId,
      'review_period_start': reviewPeriodStart.toIso8601String(),
      'review_period_end': reviewPeriodEnd.toIso8601String(),
      'complaints_handled': complaintsHandled,
      'complaints_resolved': complaintsResolved,
      'average_resolution_time_days': averageResolutionTimeDays,
      'sla_compliance_rate': slaComplianceRate,
      'citizen_satisfaction_score': citizenSatisfactionScore,
      'performance_score': performanceScore,
      'penalties_incurred': penaltiesIncurred,
      'bonuses_earned': bonusesEarned,
      'review_notes': reviewNotes,
      'reviewed_by_id': reviewedById,
      'reviewed_at': reviewedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}