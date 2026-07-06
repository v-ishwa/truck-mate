import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_constants.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/profile_post.dart';
import '../../domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  static final MockProfileRepository _instance = MockProfileRepository._internal();
  factory MockProfileRepository() => _instance;
  MockProfileRepository._internal() {
    _initMockData();
  }

  late UserProfile _profile;
  final List<ProfilePost> _posts = [];

  void _initMockData() {
    _profile = const UserProfile(
      name: 'Ramesh Transport',
      role: 'Owner',
      avatarUrl: '',
      bioLines: [
        'Safe & On-time Delivery 🚚',
        'Pan India Services',
        'Contact for load bookings.',
      ],
      isJoined: false,
      followersCount: 1250,
      followingCount: 482,
    );

    _posts.clear();
  }

  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await SharedPreferences.getInstance();
    
    final name = prefs.getString('user_name') ?? _profile.name;
    final role = prefs.getString('user_role') ?? _profile.role;
    final state = prefs.getString('user_state');
    final city = prefs.getString('user_city');
    final mobile = prefs.getString('user_mobile');
    
    String avatarUrl = '';
    final savedProfilePic = prefs.getString('user_profile_picture');
    if (savedProfilePic != null && savedProfilePic.isNotEmpty) {
      if (savedProfilePic.startsWith('http')) {
        avatarUrl = savedProfilePic;
      } else {
        avatarUrl = '${ApiConstants.baseUrl}$savedProfilePic';
      }
    }
    
    final bioLines = [
      if (state != null && state.isNotEmpty && city != null && city.isNotEmpty)
        'Location: $city, $state'
      else if (city != null && city.isNotEmpty)
        'Location: $city',
      if (mobile != null && mobile.isNotEmpty) 'Contact: $mobile',
      'Safe & On-time Delivery 🚚',
      'Pan India Services',
    ];
    
    _profile = _profile.copyWith(
      name: name,
      role: role,
      avatarUrl: avatarUrl,
      bioLines: bioLines,
      state: state,
      city: city,
    );
    
    return _profile;
  }

  @override
  Future<List<ProfilePost>> getUploadedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');

      if (token != null && userId != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userPosts}/$userId');
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          final List<ProfilePost> fetchedPosts = jsonList.map((jsonItem) {
            String imageUrl = jsonItem['postImage'] as String? ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = '${ApiConstants.baseUrl}$imageUrl';
            }
            if (imageUrl.isEmpty) {
              imageUrl = 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop';
            }
            return ProfilePost(
              id: jsonItem['id'].toString(),
              imageUrl: imageUrl,
              description: jsonItem['description'] as String? ?? '',
              uploadTime: jsonItem['createdAt'] != null
                  ? DateTime.parse(jsonItem['createdAt'])
                  : DateTime.now(),
            );
          }).toList();

          _posts.clear();
          _posts.addAll(fetchedPosts);
          return _posts;
        }
      }
    } catch (e) {
      // Fallback to cached posts if API fails
    }

    return List.unmodifiable(_posts);
  }

  @override
  Future<UserProfile> toggleJoinMembership() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final bool newJoin = !_profile.isJoined;
    _profile = _profile.copyWith(
      isJoined: newJoin,
      followersCount: newJoin ? _profile.followersCount + 1 : _profile.followersCount - 1,
    );
    return _profile;
  }

  @override
  Future<void> uploadPost(ProfilePost post) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _posts.insert(0, post);
  }

  void resetMockData() {
    _initMockData();
  }

  @override
  Future<bool> deletePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.posts}/$postId');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _posts.removeWhere((p) => p.id == postId);
          return true;
        }
      }
    } catch (e) {
      // Rethrow for the caller to handle
      rethrow;
    }
    return false;
  }
}
