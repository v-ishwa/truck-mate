import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_response.dart';
import '../../../../core/network/api_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client client;

  AuthRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  /// Saves auth token and user info to SharedPreferences
  Future<void> _saveAuthData(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    if (response.token != null) {
      await prefs.setString('auth_token', response.token!);
    }
    if (response.userId != null) {
      await prefs.setInt('user_id', response.userId!);
    }
    if (response.name != null) {
      await prefs.setString('user_name', response.name!);
    }
    if (response.mobileNumber != null) {
      await prefs.setString('user_mobile', response.mobileNumber!);
    }
    if (response.role != null) {
      await prefs.setString('user_role', response.role!);
    }
    if (response.city != null) {
      await prefs.setString('user_city', response.city!);
    }
    if (response.profilePicture != null) {
      await prefs.setString('user_profile_picture', response.profilePicture!);
    }
  }

  @override
  Future<AuthResponse> register({
    required String name,
    required String mobileNumber,
    required DateTime dob,
    required String role,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
      // Date format required: YYYY-MM-DD
      final dobStr = "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'mobileNumber': mobileNumber,
          'dob': dobStr,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse);
        }
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: 'Server returned error: ${response.statusCode}',
        );
      }
    } catch (e) {
      String errorMsg = 'Connection failed: $e';
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMsg = 'Connection timed out. Please check if the server is running and try again.';
      }
      return AuthResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  @override
  Future<AuthResponse> loginWithPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userMobile': phoneNumber,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse);
        }
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: 'Server returned error: ${response.statusCode}',
        );
      }
    } catch (e) {
      String errorMsg = 'Connection failed: $e';
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        errorMsg = 'Connection timed out. Please check if the server is running and try again.';
      }
      return AuthResponse(
        success: false,
        message: errorMsg,
      );
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_mobile');
    await prefs.remove('user_role');
    await prefs.remove('user_city');
    await prefs.remove('user_profile_picture');
  }
}
