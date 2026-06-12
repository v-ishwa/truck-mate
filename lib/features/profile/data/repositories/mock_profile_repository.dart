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
      avatarUrl: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=200&auto=format&fit=crop',
      bioLines: [
        'Safe & On-time Delivery 🚚',
        'Pan India Services',
        'Contact for load bookings.',
      ],
      isJoined: false,
    );

    _posts.clear();
    for (int i = 0; i < _truckImages.length; i++) {
      _posts.add(
        ProfilePost(
          id: 'post_$i',
          imageUrl: _truckImages[i],
          description: 'Proud to deliver safe & on-time load #$i! 🚚💨 #RameshTransport',
          uploadTime: DateTime.now().subtract(Duration(days: i * 2)),
        ),
      );
    }
  }

  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _profile;
  }

  @override
  Future<List<ProfilePost>> getUploadedPosts() async {
    await Future.delayed(const Duration(milliseconds: 200));
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
}
