class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final int? userId;
  final bool? profileCompleted;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.userId,
    this.profileCompleted,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      userId: json['userId'],
      profileCompleted: json['profileCompleted'],
    );
  }
}
