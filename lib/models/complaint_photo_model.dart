class ComplaintPhoto {
  final String photoId;
  final String complaintId;
  final String photoUrl;
  final DateTime uploadedAt;
  final String? uploadedById;
  final String? photoType;
  final String? photoThumbnailUrl;
  final String? caption;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? metadata;
  final int? uploadOrder;

  ComplaintPhoto({
    required this.photoId,
    required this.complaintId,
    required this.photoUrl,
    required this.uploadedAt,
    this.uploadedById,
    this.photoType,
    this.photoThumbnailUrl,
    this.caption,
    this.gpsLatitude,
    this.gpsLongitude,
    this.metadata,
    this.uploadOrder,
  });

  factory ComplaintPhoto.fromJson(Map<String, dynamic> json) {
    return ComplaintPhoto(
      photoId: json['photo_id']?.toString() ?? json['photoId']?.toString() ?? '',
      complaintId: json['complaint_id']?.toString() ?? json['complaintId']?.toString() ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'] ?? '',
      uploadedAt: _parseDateTime(json['uploaded_at'] ?? json['uploadedAt']),
      uploadedById: json['UploadedById']?.toString() ?? json['uploadedById']?.toString(),
      photoType: json['PhotoType'] ?? json['photoType'],
      photoThumbnailUrl: json['PhotoThumbnailUrl'] ?? json['photoThumbnailUrl'],
      caption: json['Caption'] ?? json['caption'],
      gpsLatitude: _parseDouble(json['GpsLatitude'] ?? json['gpsLatitude']),
      gpsLongitude: _parseDouble(json['GpsLongitude'] ?? json['gpsLongitude']),
      metadata: json['Metadata'] ?? json['metadata'],
      uploadOrder: json['UploadOrder'] ?? json['uploadOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_id': photoId,
      'complaint_id': complaintId,
      'photo_url': photoUrl,
      'uploaded_at': uploadedAt.toIso8601String(),
      'UploadedById': uploadedById,
      'PhotoType': photoType,
      'PhotoThumbnailUrl': photoThumbnailUrl,
      'Caption': caption,
      'GpsLatitude': gpsLatitude,
      'GpsLongitude': gpsLongitude,
      'Metadata': metadata,
      'UploadOrder': uploadOrder,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}