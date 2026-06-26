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

  final List<String> _truckImages = [
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1591768793355-74d75b50f58f?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1516576880881-148f8f68740b?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1532601224476-15c79f2f7a51?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1616422285623-13ff0162193c?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1501700490688-6161b2b58f6b?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1592838064808-04a4b518410b?q=80&w=400&auto=format&fit=crop',
  ];

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
      final userMobile = prefs.getString('user_mobile');

      if (token != null && userMobile != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.posts}');
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          
          final List<ProfilePost> fetchedPosts = [];
          for (var jsonItem in jsonList) {
            final postMobile = jsonItem['userMobileNumber'] as String?;
            if (postMobile == userMobile) {
              
              String imageUrl = jsonItem['postImage'] as String? ?? '';
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = '${ApiConstants.baseUrl}$imageUrl';
              }
              if (imageUrl.isEmpty) {
                // Fallback to placeholder if no image
                imageUrl = 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop';
              }
              
              String description = jsonItem['description'] as String? ?? 'No description';
              
              DateTime uploadTime = DateTime.now();
              if (jsonItem['createdAt'] != null) {
                uploadTime = DateTime.parse(jsonItem['createdAt']);
              }
              
              fetchedPosts.add(ProfilePost(
                id: jsonItem['id'].toString(),
                imageUrl: imageUrl,
                description: description,
                uploadTime: uploadTime,
              ));
            }
          }
          
          _posts.clear();
          _posts.addAll(fetchedPosts);
          return _posts;
        }
      }
    } catch (e) {
      // Fallback to mock data if API fails or no token
    }
    
    return List.unmodifiable(_posts);
  }

  @override
  Future<UserProfile> toggleJoinMembership() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _profile = _profile.copyWith(isJoined: !_profile.isJoined);
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
