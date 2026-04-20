class User {
  final String userId;
  final String userType;
  final String fullName;
  final String email;
  final String? passwordHash;  // CHANGE: Make it optional (nullable)
  final String? phoneNumber;
  final String? zoneId;
  final bool isActive;
  final DateTime createdAt;
  final String? cnic;
  final String? address;
  final String? profilePhotoUrl;
  final bool isVerified;
  final DateTime updatedAt;
  final DateTime? lastLogin;

  User({
    required this.userId,
    required this.userType,
    required this.fullName,
    required this.email,
    this.passwordHash,  // CHANGE: Make optional
    this.phoneNumber,
    this.zoneId,
    required this.isActive,
    required this.createdAt,
    this.cnic,
    this.address,
    this.profilePhotoUrl,
    required this.isVerified,
    required this.updatedAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? json['UserId']?.toString() ?? '',
      userType: json['user_type'] ?? json['UserType'] ?? '',
      fullName: json['full_name'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      passwordHash: json['password_hash'] ?? json['PasswordHash'],  // Will be null in login responses
      phoneNumber: json['PhoneNumber'] ?? json['phone_number'],
      zoneId: json['zone_id']?.toString() ?? json['ZoneId']?.toString(),
      isActive: json['is_active'] ?? json['IsActive'] ?? false,
      createdAt: _parseDateTime(json['created_at'] ?? json['CreatedAt']),
      cnic: json['CNIC'] ?? json['cnic'],
      address: json['Address'] ?? json['address'],
      profilePhotoUrl: json['ProfilePhotoUrl'] ?? json['profile_photo_url'],
      isVerified: json['IsVerified'] ?? json['is_verified'] ?? false,
      updatedAt: _parseDateTime(json['UpdatedAt'] ?? json['updated_at']),
      lastLogin: json['LastLogin'] != null ? _parseDateTime(json['LastLogin']) : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_type': userType,
      'full_name': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'isVerified': isVerified,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}