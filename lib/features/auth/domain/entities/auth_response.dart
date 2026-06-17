class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final int? userId;
  final bool? profileCompleted;

  // User detail fields
  final String? name;
  final String? mobileNumber;
  final String? role;
  final String? city;
  final String? profilePicture;
  final String? dob;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.userId,
    this.profileCompleted,
    this.name,
    this.mobileNumber,
    this.role,
    this.city,
    this.profilePicture,
    this.dob,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      userId: json['userId'],
      profileCompleted: json['profileCompleted'],
      name: json['name'],
      mobileNumber: json['mobileNumber'],
      role: json['role'],
      city: json['city'],
      profilePicture: json['profilePicture'],
      dob: json['dob'],
    );
  }
}
