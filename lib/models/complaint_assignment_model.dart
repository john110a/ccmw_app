class ComplaintAssignment {
  final String assignmentId;
  final String complaintId;
  final String? staffId;
  final DateTime assignedAt;
  final String? assignedById;
  final String? assignmentType;
  final String? assignmentNotes;
  final DateTime? expectedCompletionDate;
  final bool? isActive;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  ComplaintAssignment({
    required this.assignmentId,
    required this.complaintId,
    this.staffId,
    required this.assignedAt,
    this.assignedById,
    this.assignmentType,
    this.assignmentNotes,
    this.expectedCompletionDate,
    this.isActive,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
  });

  factory ComplaintAssignment.fromJson(Map<String, dynamic> json) {
    return ComplaintAssignment(
      assignmentId: json['assignment_id']?.toString() ?? json['assignmentId']?.toString() ?? '',
      complaintId: json['complaint_id']?.toString() ?? json['complaintId']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? json['staffId']?.toString(),
      assignedAt: _parseDateTime(json['assigned_at'] ?? json['assignedAt']),
      assignedById: json['AssignedById']?.toString() ?? json['assignedById']?.toString(),
      assignmentType: json['AssignmentType'] ?? json['assignmentType'],
      assignmentNotes: json['AssignmentNotes'] ?? json['assignmentNotes'],
      expectedCompletionDate: json['ExpectedCompletionDate'] != null
          ? _parseDateTime(json['ExpectedCompletionDate'])
          : null,
      isActive: json['IsActive'] ?? json['isActive'],
      acceptedAt: json['AcceptedAt'] != null ? _parseDateTime(json['AcceptedAt']) : null,
      startedAt: json['StartedAt'] != null ? _parseDateTime(json['StartedAt']) : null,
      completedAt: json['CompletedAt'] != null ? _parseDateTime(json['CompletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'complaint_id': complaintId,
      'staff_id': staffId,
      'assigned_at': assignedAt.toIso8601String(),
      'AssignedById': assignedById,
      'AssignmentType': assignmentType,
      'AssignmentNotes': assignmentNotes,
      'ExpectedCompletionDate': expectedCompletionDate?.toIso8601String(),
      'IsActive': isActive,
      'AcceptedAt': acceptedAt?.toIso8601String(),
      'StartedAt': startedAt?.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}