import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:truck_mate/features/profile/presentation/screens/search_user_screen.dart';

/// Result of a follow or unfollow action.
class FollowResult {
  final bool success;
  final String message;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  const FollowResult({
    required this.success,
    required this.message,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory FollowResult.fromJson(Map<String, dynamic> json) {
    return FollowResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? json['following'] as bool? ?? false,
    );
  }
}

/// HTTP client for the /api/follows endpoints.
class FollowRepository {
  static final FollowRepository _instance = FollowRepository._internal();
  factory FollowRepository() => _instance;
  FollowRepository._internal();

  /// Fires whenever a follow or unfollow succeeds.
  /// Screens can listen to this to refresh follow counts in real time.
  static final followEventNotifier = ValueNotifier<int>(0);

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Follow a user by their ID. Returns updated counts + new follow state.
  Future<FollowResult> followUser(int targetId) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.follows}/$targetId');
      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final result = FollowResult.fromJson(json.decode(response.body));
        if (result.success) followEventNotifier.value++;
        return result;
      }
    } catch (_) {}
    return const FollowResult(
        success: false,
        message: 'Error',
        followersCount: 0,
        followingCount: 0,
        isFollowing: false);
  }

  /// Unfollow a user by their ID.
  Future<FollowResult> unfollowUser(int targetId) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.follows}/$targetId');
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final result = FollowResult.fromJson(json.decode(response.body));
        if (result.success) followEventNotifier.value++;
        return result;
      }
    } catch (_) {}
    return const FollowResult(
        success: false,
        message: 'Error',
        followersCount: 0,
        followingCount: 0,
        isFollowing: false);
  }

  /// Get the followers list for a given user.
  Future<List<SearchUser>> getFollowers(int userId) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.follows}/$userId/followers');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => SearchUser.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get the following list for a given user.
  Future<List<SearchUser>> getFollowing(int userId) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.follows}/$userId/following');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => SearchUser.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get follow stats for a user relative to the caller.
  Future<FollowResult> getFollowStats(int userId) async {
    try {
      final headers = await _authHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.follows}/$userId/stats');
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return FollowResult.fromJson(json.decode(response.body));
      }
    } catch (_) {}
    return const FollowResult(
        success: false,
        message: 'Error',
        followersCount: 0,
        followingCount: 0,
        isFollowing: false);
  }
}
