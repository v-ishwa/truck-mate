import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

class MockPostsRepository implements PostsRepository {
  static final MockPostsRepository _instance = MockPostsRepository._internal();
  factory MockPostsRepository() => _instance;
  MockPostsRepository._internal();

  final List<Post> _posts = [
    Post(
      id: 'post_1',
      userName: 'Ramesh Transport',
      role: 'Owner',
      avatarUrl: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=200&auto=format&fit=crop',
      timeAgo: '2h ago',
      statusText: 'Mumbai → Nagpur 📍\nTomorrow, 7:00 PM ⏰\n32 Feet Open Body Truck Available ✅',
      imageUrl: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=600&auto=format&fit=crop',
      likeCount: 128,
      commentCount: 12,
      isLiked: false,
      isBookmarked: false,
      caption: 'Safe & On-time Delivery 🚚',
      tags: ['#Mumbai', '#Nagpur', '#LoadAvailable', '#TruckMate'],
      hasRouteCard: true,
      fromLocation: 'Mumbai, MH',
      toLocation: 'Nagpur, MH',
      departureTime: '7:00 PM',
      contactNumber: '+91 98765 43210',
    ),
    Post(
      id: 'post_2',
      userName: 'Sharma Motors',
      role: 'Mechanic',
      avatarUrl: 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=200&auto=format&fit=crop',
      timeAgo: '4h ago',
      statusText: 'Engine repair, clutch replacement, general service.\nAll types of trucks & trailers.',
      imageUrl: 'https://images.unsplash.com/photo-1532601224476-15c79f2f7a51?q=80&w=600&auto=format&fit=crop',
      likeCount: 64,
      commentCount: 8,
      isLiked: false,
      isBookmarked: false,
      caption: 'We keep your truck running. 💪',
      tags: ['#TruckRepair', '#Mechanic', '#TruckMate'],
      hasRouteCard: false,
    ),
    Post(
      id: 'post_3',
      userName: 'PMR Logistics',
      role: 'Owner',
      avatarUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=200&auto=format&fit=crop',
      timeAgo: '6h ago',
      statusText: 'Urgent Load Available: 18-ton capacity cargo for immediate shipment from Chennai to Bangalore.\nBest freight rates guaranteed.',
      imageUrl: 'https://images.unsplash.com/photo-1591768793355-74d75b50f58f?q=80&w=600&auto=format&fit=crop',
      likeCount: 42,
      commentCount: 4,
      isLiked: false,
      isBookmarked: false,
      caption: 'Urgent shipment route booked! 🚛',
      tags: ['#Chennai', '#Bangalore', '#CargoAvailable', '#PMRLogistics'],
      hasRouteCard: true,
      fromLocation: 'Chennai, TN',
      toLocation: 'Bangalore, KA',
      departureTime: 'Flexible',
      contactNumber: '+91 87654 32109',
    ),
  ];

  @override
  Future<List<Post>> getPosts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_posts);
  }

  @override
  Future<Post> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final newIsLiked = !post.isLiked;
      final newLikeCount = newIsLiked ? post.likeCount + 1 : post.likeCount - 1;
      final updatedPost = post.copyWith(
        isLiked: newIsLiked,
        likeCount: newLikeCount,
      );
      _posts[index] = updatedPost;
      return updatedPost;
    }
    throw Exception('Post not found');
  }

  @override
  Future<Post> toggleBookmark(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final updatedPost = post.copyWith(
        isBookmarked: !post.isBookmarked,
      );
      _posts[index] = updatedPost;
      return updatedPost;
    }
    throw Exception('Post not found');
  }

  @override
  Future<void> addPost(Post post) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _posts.insert(0, post);
  }

  @override
  Future<bool> deletePost(String postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts.removeAt(index);
      return true;
    }
    return false;
  }
}
