import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../../../../core/network/api_constants.dart';

class ApiPostsRepository implements PostsRepository {
  final http.Client client;

  // Local cache for client-side like/bookmark state
  final Map<String, Post> _postCache = {};

  ApiPostsRepository({http.Client? client})
      : client = client ?? http.Client();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Future<List<Post>> getPosts() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.posts}');
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      final posts = jsonList.map((jsonItem) {
        final post = Post.fromJson(jsonItem as Map<String, dynamic>);
        // Preserve local like/bookmark state if we have it cached
        final cached = _postCache[post.id];
        if (cached != null) {
          return post.copyWith(
            isLiked: cached.isLiked,
            likeCount: cached.likeCount,
            isBookmarked: cached.isBookmarked,
          );
        }
        return post;
      }).toList();
      return posts;
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      throw Exception('Failed to load posts (${response.statusCode})');
    }
  }

  @override
  Future<Post> toggleLike(String postId) async {
    // Client-side toggle (no backend endpoint for likes yet)
    final cached = _postCache[postId];
    if (cached != null) {
      final newIsLiked = !cached.isLiked;
      final newLikeCount = newIsLiked ? cached.likeCount + 1 : cached.likeCount - 1;
      final updatedPost = cached.copyWith(
        isLiked: newIsLiked,
        likeCount: newLikeCount,
      );
      _postCache[postId] = updatedPost;
      return updatedPost;
    }
    throw Exception('Post not found in cache');
  }

  @override
  Future<Post> toggleBookmark(String postId) async {
    // Client-side toggle (no backend endpoint for bookmarks yet)
    final cached = _postCache[postId];
    if (cached != null) {
      final updatedPost = cached.copyWith(
        isBookmarked: !cached.isBookmarked,
      );
      _postCache[postId] = updatedPost;
      return updatedPost;
    }
    throw Exception('Post not found in cache');
  }

  @override
  Future<void> addPost(Post post) async {
    // This is handled by AddPostScreen's own API call
    // Just add to cache for consistency
    _postCache[post.id] = post;
  }

  /// Update the local cache after fetching posts
  void updateCache(List<Post> posts) {
    for (final post in posts) {
      if (!_postCache.containsKey(post.id)) {
        _postCache[post.id] = post;
      }
    }
  }
}
