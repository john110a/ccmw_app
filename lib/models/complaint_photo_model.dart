// lib/models/complaint_photo_model.dart
import '../services/api_config.dart';

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
    String rawUrl = json['PhotoUrl']?.toString() ??
        json['photo_url']?.toString() ??
        json['photoUrl']?.toString() ?? '';

    return ComplaintPhoto(
      photoId: json['PhotoId']?.toString() ??
          json['photo_id']?.toString() ??
          json['photoId']?.toString() ?? '',
      complaintId: json['ComplaintId']?.toString() ??
          json['complaint_id']?.toString() ??
          json['complaintId']?.toString() ?? '',
      photoUrl: rawUrl,
      uploadedAt: _parseDateTime(
          json['UploadedAt'] ?? json['uploaded_at'] ?? json['uploadedAt']),
      uploadedById: json['UploadedById']?.toString() ??
          json['uploadedById']?.toString(),
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
      'PhotoId': photoId,
      'ComplaintId': complaintId,
      'PhotoUrl': photoUrl,
      'UploadedAt': uploadedAt.toIso8601String(),
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

  // =====================================================
  // IMAGE URL HELPERS
  // =====================================================

  /// Get the server base URL (without /api)
  static String get _serverBaseUrl {
    String baseUrl = ApiConfig.baseUrl;
    // Remove /api if present at the end
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  /// Convert stored image path to full URL
  static String _getFullImageUrl(String path) {
    if (path.isEmpty) return '';

    // If already a full URL (starts with http:// or https://)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Remove leading slashes
    String cleanPath = path;
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // If it starts with CCMW or api, adjust accordingly
    if (cleanPath.startsWith('CCMW/')) {
      return '${_serverBaseUrl}/$cleanPath';
    }

    // If it starts with uploads (common pattern)
    if (cleanPath.startsWith('uploads/')) {
      return '${_serverBaseUrl}/CCMW/$cleanPath';
    }

    // Default: just append to server URL
    return '${_serverBaseUrl}/CCMW/$cleanPath';
  }

  /// Get the full URL for the photo (with base URL prepended if needed)
  String get fullPhotoUrl {
    if (photoUrl.isEmpty) return '';
    return _getFullImageUrl(photoUrl);
  }

  /// Get the full URL for the thumbnail
  String? get fullThumbnailUrl {
    if (photoThumbnailUrl == null || photoThumbnailUrl!.isEmpty) return null;
    return _getFullImageUrl(photoThumbnailUrl!);
  }

  /// Check if this is a dummy/test image
  bool get isDummyImage {
    final dummyPatterns = [
      'dummy',
      'placeholder',
      'test',
      'sample',
      'no-image',
      'default',
      'null',
    ];
    final lowerUrl = photoUrl.toLowerCase();
    return dummyPatterns.any((pattern) => lowerUrl.contains(pattern)) ||
        photoUrl.isEmpty;
  }

  /// Check if the image URL is valid
  bool get isValidImage {
    if (photoUrl.isEmpty) return false;
    if (isDummyImage) return false;
    return true;
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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}