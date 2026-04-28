// lib/models/complaint_model.dart
import 'package:flutter/animation.dart' show Color;
import 'package:flutter/material.dart' show Colors;
import 'user_model.dart';
import 'complaint_photo_model.dart';

enum ComplaintStatus {
  submitted,
  underReview,
  approved,
  assigned,
  inProgress,
  resolved,
  verified,
  rejected,
  closed
}

enum SubmissionStatus {
  pendingApproval,
  approved,
  rejected
}

class Complaint {
  final String complaintId;
  final String citizenId;
  final String categoryId;
  final String departmentId;
  final String zoneId;
  final String title;
  final String description;
  final String? status;
  final String priority;
  final int escalationLevel;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String locationAddress;
  final double locationLatitude;
  final double locationLongitude;
  final String? locationLandmark;
  final String? complaintNumber;
  final String? approvedById;
  final String? rejectionReason;
  final DateTime? statusUpdatedAt;
  final int upvoteCount;
  final int viewCount;
  final bool isDuplicate;
  final String? mergedIntoComplaintId;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final DateTime? expectedResolutionDate;
  final bool isOverdue;
  final String? assignedToId;
  final DateTime? assignedAt;
  final int submissionStatus;
  final int currentStatus;

  // Display fields from nested objects
  final String? categoryName;
  final String? zoneName;
  final String? departmentName;
  final String? citizenName;
  final String? assignedToName;
  final User? citizen;

  // Complaint photos
  final List<ComplaintPhoto> complaintPhotos;

  Complaint({
    required this.complaintId,
    required this.citizenId,
    required this.categoryId,
    required this.departmentId,
    required this.zoneId,
    required this.title,
    required this.description,
    this.status,
    required this.priority,
    required this.escalationLevel,
    required this.createdAt,
    this.resolvedAt,
    required this.locationAddress,
    required this.locationLatitude,
    required this.locationLongitude,
    this.locationLandmark,
    this.complaintNumber,
    this.approvedById,
    this.rejectionReason,
    this.statusUpdatedAt,
    required this.upvoteCount,
    required this.viewCount,
    required this.isDuplicate,
    this.mergedIntoComplaintId,
    this.updatedAt,
    this.closedAt,
    this.expectedResolutionDate,
    required this.isOverdue,
    this.assignedToId,
    this.assignedAt,
    required this.submissionStatus,
    required this.currentStatus,
    this.categoryName,
    this.zoneName,
    this.departmentName,
    this.citizenName,
    this.assignedToName,
    this.citizen,
    this.complaintPhotos = const [],
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    // =====================================================
    // Extract nested object data
    // =====================================================

    String? extractedCategoryName;
    if (json['Category'] != null && json['Category'] is Map) {
      extractedCategoryName = json['Category']['CategoryName']?.toString() ??
          json['Category']['categoryName']?.toString();
    } else if (json['categoryName'] != null) {
      extractedCategoryName = json['categoryName'].toString();
    } else if (json['CategoryName'] != null) {
      extractedCategoryName = json['CategoryName'].toString();
    }

    String? extractedZoneName;
    if (json['Zone'] != null && json['Zone'] is Map) {
      extractedZoneName = json['Zone']['ZoneName']?.toString() ??
          json['Zone']['zoneName']?.toString();
    } else if (json['zoneName'] != null) {
      extractedZoneName = json['zoneName'].toString();
    } else if (json['ZoneName'] != null) {
      extractedZoneName = json['ZoneName'].toString();
    }

    String? extractedDepartmentName;
    if (json['Department'] != null && json['Department'] is Map) {
      extractedDepartmentName =
          json['Department']['DepartmentName']?.toString() ??
              json['Department']['departmentName']?.toString();
    } else if (json['departmentName'] != null) {
      extractedDepartmentName = json['departmentName'].toString();
    } else if (json['DepartmentName'] != null) {
      extractedDepartmentName = json['DepartmentName'].toString();
    }

    String? extractedCitizenName;
    if (json['Citizen'] != null && json['Citizen'] is Map) {
      extractedCitizenName = json['Citizen']['FullName']?.toString() ??
          json['Citizen']['fullName']?.toString();
    } else if (json['citizenName'] != null) {
      extractedCitizenName = json['citizenName'].toString();
    } else if (json['CitizenName'] != null) {
      extractedCitizenName = json['CitizenName'].toString();
    } else if (json['FullName'] != null) {
      extractedCitizenName = json['FullName'].toString();
    }

    String? extractedAssignedToName;
    if (json['AssignedTo'] != null && json['AssignedTo'] is Map) {
      extractedAssignedToName = json['AssignedTo']['FullName']?.toString() ??
          json['AssignedTo']['fullName']?.toString();
    } else if (json['assignedToName'] != null) {
      extractedAssignedToName = json['assignedToName'].toString();
    }

    // =====================================================
    // ✅ FIXED: Parse photos — handles objects, plain strings,
    // and all key variants the backend may send
    // =====================================================
    List<ComplaintPhoto> photos = _parsePhotos(json);

    return Complaint(
      complaintId: json['ComplaintId']?.toString() ??
          json['complaint_id']?.toString() ??
          json['complaintId']?.toString() ?? '',
      citizenId: json['citizen_id']?.toString() ??
          json['citizenId']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ??
          json['categoryId']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ??
          json['departmentId']?.toString() ?? '',
      zoneId: json['zone_id']?.toString() ?? json['zoneId']?.toString() ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      status: json['status'] ?? json['Status'],
      priority: json['priority'] ?? json['Priority'] ?? 'Medium',
      escalationLevel: json['escalation_level'] ?? json['escalationLevel'] ?? 0,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? json['CreatedAt']),
      resolvedAt: json['resolved_at'] != null
          ? _parseDateTime(json['resolved_at'])
          : null,
      locationAddress:
      json['location_address'] ?? json['locationAddress'] ?? json['LocationAddress'] ?? '',
      locationLatitude: _parseDouble(
          json['location_latitude'] ?? json['locationLatitude'] ?? json['LocationLatitude']),
      locationLongitude: _parseDouble(
          json['location_longitude'] ?? json['locationLongitude'] ?? json['LocationLongitude']),
      locationLandmark:
      json['location_landmark'] ?? json['locationLandmark'],
      complaintNumber:
      json['ComplaintNumber'] ?? json['complaintNumber'],
      approvedById: json['ApprovedById']?.toString() ??
          json['approvedById']?.toString(),
      rejectionReason:
      json['RejectionReason'] ?? json['rejectionReason'],
      statusUpdatedAt: json['StatusUpdatedAt'] != null
          ? _parseDateTime(json['StatusUpdatedAt'])
          : null,
      upvoteCount: json['UpvoteCount'] ?? json['upvoteCount'] ?? 0,
      viewCount: json['ViewCount'] ?? json['viewCount'] ?? 0,
      isDuplicate: json['IsDuplicate'] ?? json['isDuplicate'] ?? false,
      mergedIntoComplaintId:
      json['MergedIntoComplaintId']?.toString() ??
          json['mergedIntoComplaintId']?.toString(),
      updatedAt: json['UpdatedAt'] != null
          ? _parseDateTime(json['UpdatedAt'])
          : null,
      closedAt: json['ClosedAt'] != null
          ? _parseDateTime(json['ClosedAt'])
          : null,
      expectedResolutionDate: json['ExpectedResolutionDate'] != null
          ? _parseDateTime(json['ExpectedResolutionDate'])
          : null,
      isOverdue: json['IsOverdue'] ?? json['isOverdue'] ?? false,
      assignedToId: json['assigned_to_id']?.toString() ??
          json['assignedToId']?.toString(),
      assignedAt: json['assigned_at'] != null
          ? _parseDateTime(json['assigned_at'])
          : null,
      submissionStatus: _parseSubmissionStatus(
          json['SubmissionStatus'] ?? json['submissionStatus']),
      currentStatus:
      _parseStatus(json['CurrentStatus'] ?? json['currentStatus']),
      categoryName: extractedCategoryName,
      zoneName: extractedZoneName,
      departmentName: extractedDepartmentName,
      citizenName: extractedCitizenName,
      assignedToName: extractedAssignedToName,
      citizen: json['citizen'] != null
          ? User.fromJson(json['citizen'])
          : (json['user'] != null ? User.fromJson(json['user']) : null),
      complaintPhotos: photos,
    );
  }

  // =====================================================
  // ✅ FIXED: Robust photo parser — handles every format
  // the backend might return:
  //   - List of objects with PhotoUrl key
  //   - List of plain URL strings
  //   - Keys: ComplaintPhotos, complaintPhotos, Photos, photos
  // =====================================================
  static List<ComplaintPhoto> _parsePhotos(Map<String, dynamic> json) {
    // All possible keys the backend might use
    final List<dynamic>? rawList =
        (json['ComplaintPhotos'] as List?)  ??
            (json['complaintPhotos'] as List?)  ??
            (json['Photos'] as List?)           ??
            (json['photos'] as List?)           ??
            (json['complaint_photos'] as List?);

    if (rawList == null || rawList.isEmpty) return [];

    return rawList.map((item) {
      // If item is already a Map (object), parse normally
      if (item is Map<String, dynamic>) {
        return ComplaintPhoto.fromJson(item);
      }
      // If item is a plain URL string (backend sends Photos as List<string>)
      if (item is String && item.isNotEmpty) {
        return ComplaintPhoto(
          photoId: '',
          complaintId: '',
          photoUrl: item,
          uploadedAt: DateTime.now(),
        );
      }
      return null;
    }).whereType<ComplaintPhoto>().toList();
  }

  static int _parseStatus(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsedInt = int.tryParse(value);
      if (parsedInt != null) return parsedInt;
      switch (value.toLowerCase()) {
        case 'submitted': return 0;
        case 'underreview':
        case 'under review': return 1;
        case 'approved': return 2;
        case 'assigned': return 3;
        case 'inprogress':
        case 'in progress': return 4;
        case 'resolved': return 5;
        case 'verified': return 6;
        case 'rejected': return 7;
        case 'closed': return 8;
        case 'reopened': return 9;
        default: return 0;
      }
    }
    return 0;
  }

  static int _parseSubmissionStatus(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      final parsedInt = int.tryParse(value);
      if (parsedInt != null) return parsedInt;
      switch (value.toLowerCase()) {
        case 'pendingapproval':
        case 'pending approval': return 0;
        case 'approved': return 1;
        case 'rejected': return 2;
        default: return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'citizen_id': citizenId,
      'category_id': categoryId,
      'department_id': departmentId,
      'zone_id': zoneId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'escalation_level': escalationLevel,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'location_address': locationAddress,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'location_landmark': locationLandmark,
      'ComplaintNumber': complaintNumber,
      'ApprovedById': approvedById,
      'RejectionReason': rejectionReason,
      'StatusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'UpvoteCount': upvoteCount,
      'ViewCount': viewCount,
      'IsDuplicate': isDuplicate,
      'MergedIntoComplaintId': mergedIntoComplaintId,
      'UpdatedAt': updatedAt?.toIso8601String(),
      'ClosedAt': closedAt?.toIso8601String(),
      'ExpectedResolutionDate': expectedResolutionDate?.toIso8601String(),
      'IsOverdue': isOverdue,
      'assigned_to_id': assignedToId,
      'assigned_at': assignedAt?.toIso8601String(),
      'SubmissionStatus': submissionStatus,
      'CurrentStatus': currentStatus,
      if (citizen != null) 'citizen': citizen!.toJson(),
      'ComplaintPhotos': complaintPhotos.map((p) => p.toJson()).toList(),
    };
  }

  String getStatusString() {
    switch (currentStatus) {
      case 0: return 'Submitted';
      case 1: return 'Under Review';
      case 2: return 'Approved';
      case 3: return 'Assigned';
      case 4: return 'In Progress';
      case 5: return 'Resolved';
      case 6: return 'Verified';
      case 7: return 'Rejected';
      case 8: return 'Closed';
      case 9: return 'Reopened';
      default: return 'Unknown';
    }
  }

  Color getStatusColor() {
    switch (currentStatus) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.purple;
      case 4: return Colors.amber;
      case 5: return Colors.green;
      case 6: return Colors.teal;
      case 7: return Colors.red;
      case 8: return Colors.grey;
      case 9: return Colors.pinkAccent;
      default: return Colors.grey;
    }
  }

  String? get firstPhotoUrl {
    if (complaintPhotos.isNotEmpty) return complaintPhotos.first.photoUrl;
    return null;
  }

  bool get hasPhotos => complaintPhotos.isNotEmpty;

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
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