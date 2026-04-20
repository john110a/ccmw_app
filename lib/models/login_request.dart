// login_request.dart
class LoginRequest {
  final String email;
  final String passwordHash;

  LoginRequest({
    required this.email,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
    };
  }
}
