class Appeal {
  final String appealId;
  final String complaintId;
  final String citizenId;
  final String appealReason;
  final String appealStatus;
  final DateTime createdAt;
  final String? reviewedById;
  final String? reviewNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? supportingDocuments;

  Appeal({
    required this.appealId,
    required this.complaintId,
    required this.citizenId,
    required this.appealReason,
    required this.appealStatus,
    required this.createdAt,
    this.reviewedById,
    this.reviewNotes,
    required this.submittedAt,
    this.reviewedAt,
    this.supportingDocuments,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      appealId: json['appeal_id']?.toString() ?? json['appealId']?.toString() ?? '',
      complaintId: json['complaint_id']?.toString() ?? json['complaintId']?.toString() ?? '',
      citizenId: json['citizen_id']?.toString() ?? json['citizenId']?.toString() ?? '',
      appealReason: json['appeal_reason'] ?? json['appealReason'] ?? '',
      appealStatus: json['appeal_status'] ?? json['appealStatus'] ?? 'Pending',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      reviewedById: json['reviewed_by_id']?.toString() ?? json['reviewedById']?.toString(),
      reviewNotes: json['review_notes'] ?? json['reviewNotes'],
      submittedAt: _parseDateTime(json['submitted_at'] ?? json['submittedAt']),
      reviewedAt: json['reviewed_at'] != null ? _parseDateTime(json['reviewed_at']) : null,
      supportingDocuments: json['supporting_documents'] ?? json['supportingDocuments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appeal_id': appealId,
      'complaint_id': complaintId,
      'citizen_id': citizenId,
      'appeal_reason': appealReason,
      'appeal_status': appealStatus,
      'created_at': createdAt.toIso8601String(),
      'reviewed_by_id': reviewedById,
      'review_notes': reviewNotes,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'supporting_documents': supportingDocuments,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}