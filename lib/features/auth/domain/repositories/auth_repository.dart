import '../entities/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> loginWithPhoneNumber(String phoneNumber);
  Future<AuthResponse> register({
    required String name,
    required String mobileNumber,
    required DateTime dob,
    required String role,
  });
  Future<void> logout();
}
