// register_request.dart
class RegisterRequest {
  final String email;
  final String passwordHash;
  final String fullName;
  final String phoneNumber;
  final String cnic;
  final String address;
  final String? zoneId;
  final String userType;

  RegisterRequest({
    required this.email,
    required this.passwordHash,
    required this.fullName,
    required this.phoneNumber,
    required this.cnic,
    required this.address,
    this.zoneId,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'CNIC': cnic,
      'address': address,
      'zoneId': zoneId,
      'userType': userType,
    };
  }
}