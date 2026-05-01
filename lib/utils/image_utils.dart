// lib/utils/image_utils.dart
import 'package:flutter/material.dart';
import '../models/complaint_photo_model.dart';
import '../services/api_config.dart';

class ImageUtils {
  // Get the server base URL (without /api)
  static String get serverBaseUrl {
    String baseUrl = ApiConfig.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }

  // Convert stored image path to full URL
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    String cleanPath = path;
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (cleanPath.startsWith('CCMW/')) {
      return '$serverBaseUrl/$cleanPath';
    }

    if (cleanPath.startsWith('uploads/')) {
      return '$serverBaseUrl/CCMW/$cleanPath';
    }

    return '$serverBaseUrl/CCMW/$cleanPath';
  }

  // Build an image widget with loading and error handling
  static Widget buildImageWidget({
    required String? imageUrl,
    double width = 60,
    double height = 60,
    BoxFit fit = BoxFit.cover,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(8)),
    Color? backgroundColor,
  }) {
    final fullUrl = getFullImageUrl(imageUrl);

    if (fullUrl.isEmpty) {
      return _buildPlaceholder(width, height, borderRadius, backgroundColor);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder(width, height, borderRadius, backgroundColor, loadingProgress);
        },
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(width, height, borderRadius, backgroundColor),
      ),
    );
  }

  static Widget _buildPlaceholder(double width, double height, BorderRadiusGeometry borderRadius, Color? backgroundColor) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(Icons.image, size: width * 0.4, color: Colors.grey[400]),
    );
  }

  static Widget _buildLoadingPlaceholder(double width, double height, BorderRadiusGeometry borderRadius, Color? backgroundColor, ImageChunkEvent? progress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: progress?.expectedTotalBytes != null
                ? progress!.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  static Widget _buildErrorPlaceholder(double width, double height, BorderRadiusGeometry borderRadius, Color? backgroundColor) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(Icons.broken_image, size: width * 0.4, color: Colors.grey[400]),
    );
  }
}