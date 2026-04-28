// lib/models/duplicate_cluster_model.dart
import 'complaint_model.dart';
import 'complaint_photo_model.dart';

class DuplicateCluster {
  final String clusterId;
  final Complaint? primaryComplaint;
  final int totalComplaintsMerged;
  final int totalCombinedUpvotes;
  final DateTime createdAt;
  final int clusterRadiusMeters;
  final double locationLatitude;
  final double locationLongitude;
  final int duplicateCount;
  final List<DuplicateEntry> duplicateEntries;

  DuplicateCluster({
    required this.clusterId,
    this.primaryComplaint,
    required this.totalComplaintsMerged,
    required this.totalCombinedUpvotes,
    required this.createdAt,
    required this.clusterRadiusMeters,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.duplicateCount,
    required this.duplicateEntries,
  });

  factory DuplicateCluster.fromJson(Map<String, dynamic> json) {
    List<DuplicateEntry> entries = [];
    final rawEntries = json['DuplicateEntries'] ?? json['duplicateEntries'];
    if (rawEntries != null && rawEntries is List) {
      entries = rawEntries
          .map((e) => DuplicateEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    Complaint? primary;
    final rawPrimary = json['PrimaryComplaint'] ?? json['primaryComplaint'];
    if (rawPrimary != null && rawPrimary is Map<String, dynamic>) {
      primary = Complaint.fromJson(rawPrimary);
    }

    return DuplicateCluster(
      clusterId: json['ClusterId']?.toString() ??
          json['clusterId']?.toString() ??
          json['cluster_id']?.toString() ?? '',
      primaryComplaint: primary,
      totalComplaintsMerged: json['TotalComplaintsMerged'] ??
          json['totalComplaintsMerged'] ??
          json['total_complaints_merged'] ?? 0,
      totalCombinedUpvotes: json['TotalCombinedUpvotes'] ??
          json['totalCombinedUpvotes'] ??
          json['total_combined_upvotes'] ?? 0,
      createdAt: _parseDateTime(
          json['CreatedAt'] ?? json['createdAt'] ?? json['created_at']),
      clusterRadiusMeters: json['ClusterRadiusMeters'] ??
          json['clusterRadiusMeters'] ??
          json['cluster_radius_meters'] ?? 0,
      locationLatitude:
      (json['LocationLatitude'] ?? json['locationLatitude'] ?? 0.0)
          .toDouble(),
      locationLongitude:
      (json['LocationLongitude'] ?? json['locationLongitude'] ?? 0.0)
          .toDouble(),
      duplicateCount:
      json['DuplicateCount'] ?? json['duplicateCount'] ?? entries.length,
      duplicateEntries: entries,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'ClusterId': clusterId,
      'PrimaryComplaint': primaryComplaint?.toJson(),
      'TotalComplaintsMerged': totalComplaintsMerged,
      'TotalCombinedUpvotes': totalCombinedUpvotes,
      'CreatedAt': createdAt.toIso8601String(),
      'ClusterRadiusMeters': clusterRadiusMeters,
      'LocationLatitude': locationLatitude,
      'LocationLongitude': locationLongitude,
      'DuplicateCount': duplicateCount,
      'DuplicateEntries': duplicateEntries.map((e) => e.toJson()).toList(),
    };
  }

  int getSelectedCount() =>
      duplicateEntries.where((e) => e.isSelected).length;

  void toggleSelection(String complaintId) {
    final index =
    duplicateEntries.indexWhere((e) => e.complaintId == complaintId);
    if (index != -1) {
      duplicateEntries[index].isSelected = !duplicateEntries[index].isSelected;
    }
  }

  List<DuplicateEntry> getSelectedComplaints() =>
      duplicateEntries.where((e) => e.isSelected).toList();
}

class DuplicateEntry {
  final String entryId;
  final String complaintId;
  final double similarityScore;
  final DateTime mergedAt;
  final Complaint? complaint;
  bool isSelected;

  DuplicateEntry({
    required this.entryId,
    required this.complaintId,
    required this.similarityScore,
    required this.mergedAt,
    this.complaint,
    this.isSelected = false,
  });

  factory DuplicateEntry.fromJson(Map<String, dynamic> json) {
    Complaint? complaint;
    final rawComplaint = json['Complaint'] ?? json['complaint'];
    if (rawComplaint != null && rawComplaint is Map<String, dynamic>) {
      complaint = Complaint.fromJson(rawComplaint);
    }

    return DuplicateEntry(
      entryId: json['EntryId']?.toString() ??
          json['entryId']?.toString() ??
          json['entry_id']?.toString() ?? '',
      complaintId: json['ComplaintId']?.toString() ??
          json['complaintId']?.toString() ??
          json['complaint_id']?.toString() ?? '',
      similarityScore:
      (json['SimilarityScore'] ?? json['similarityScore'] ?? 0.0)
          .toDouble(),
      mergedAt: _parseDateTime(
          json['MergedAt'] ?? json['mergedAt'] ?? json['merged_at']),
      complaint: complaint,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'EntryId': entryId,
      'ComplaintId': complaintId,
      'SimilarityScore': similarityScore,
      'MergedAt': mergedAt.toIso8601String(),
      'Complaint': complaint?.toJson(),
    };
  }

  String? get complaintNumber => complaint?.complaintNumber;
  String? get complaintTitle => complaint?.title;
  DateTime? get complaintCreatedAt => complaint?.createdAt;

  String? get thumbnailPhotoUrl {
    if (complaint?.complaintPhotos.isNotEmpty == true) {
      return complaint!.complaintPhotos.first.photoUrl;
    }
    return null;
  }

  List<ComplaintPhoto> get photos => complaint?.complaintPhotos ?? [];
}