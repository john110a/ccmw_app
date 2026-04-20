// lib/models/feedback_model.dart
class Feedback {
  final String feedbackId;
  final String complaintId;
  final String complaintNumber;
  final String complaintTitle;
  final int rating;
  final String? comments;
  final DateTime createdAt;
  final String? citizenId;
  final String? citizenName;

  Feedback({
    required this.feedbackId,
    required this.complaintId,
    required this.complaintNumber,
    required this.complaintTitle,
    required this.rating,
    this.comments,
    required this.createdAt,
    this.citizenId,
    this.citizenName,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedback_id']?.toString() ??
          json['feedbackId']?.toString() ??
          '',
      complaintId: json['complaint_id']?.toString() ??
          json['complaintId']?.toString() ??
          '',
      complaintNumber: json['complaint_number']?.toString() ??
          json['complaintNumber']?.toString() ??
          'N/A',
      complaintTitle: json['complaint_title']?.toString() ??
          json['complaintTitle']?.toString() ??
          'Unknown Complaint',
      rating: json['rating'] ?? 0,
      comments: json['comments']?.toString() ??
          json['Comments']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now()),
      citizenId: json['citizen_id']?.toString() ??
          json['citizenId']?.toString(),
      citizenName: json['citizen_name']?.toString() ??
          json['citizenName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_id': feedbackId,
      'complaint_id': complaintId,
      'complaint_number': complaintNumber,
      'complaint_title': complaintTitle,
      'rating': rating,
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
      'citizen_id': citizenId,
      'citizen_name': citizenName,
    };
  }
}

// For submitting new feedback
class FeedbackRequest {
  final String complaintId;
  final int rating;
  final String? comments;

  FeedbackRequest({
    required this.complaintId,
    required this.rating,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'rating': rating,
      'comments': comments,
    };
  }
}