import 'package:flutter/material.dart';
import '../../domain/entities/profile_post.dart';

class PostsGrid extends StatelessWidget {
  final List<ProfilePost> posts;
  final Function(ProfilePost)? onPostTap;

  const PostsGrid({
    super.key,
    required this.posts,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => onPostTap?.call(post),
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Hero(
              tag: 'post_${post.id}',
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFFEEEEEE),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF0095F6),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE0E0E0),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
