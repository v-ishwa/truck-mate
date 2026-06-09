import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> loginWithPhoneNumber(String phoneNumber);
  Future<User?> registerWithPhoneNumber(String phoneNumber, String role);
  Future<void> logout();
}
