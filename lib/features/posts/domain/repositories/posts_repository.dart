import '../entities/post.dart';

abstract class PostsRepository {
  Future<List<Post>> getPosts();
  Future<Post> toggleLike(String postId);
  Future<Post> toggleBookmark(String postId);
  Future<void> addPost(Post post);
}
