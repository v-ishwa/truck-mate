import '../entities/user_profile.dart';
import '../entities/profile_post.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();
  Future<List<ProfilePost>> getUploadedPosts();
  Future<UserProfile> toggleJoinMembership();
  Future<void> uploadPost(ProfilePost post);
  Future<bool> deletePost(String postId);
}
