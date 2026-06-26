import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import 'route_info_card.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLikePressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onMoreMenuPressed;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikePressed,
    required this.onBookmarkPressed,
    required this.onCallPressed,
    required this.onMoreMenuPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _showDoubleTapLikeOverlay = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 0.9).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      widget.onLikePressed();
    }
    setState(() {
      _showDoubleTapLikeOverlay = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      setState(() {
        _showDoubleTapLikeOverlay = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final secondaryTextColor = isDark ? const Color(0xFFA8A8A8) : Colors.grey.shade600;
    final dividerColor = isDark ? const Color(0xFF262626) : Colors.grey.shade100;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // User Avatar
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF363636) : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: post.avatarUrl.isNotEmpty ? NetworkImage(post.avatarUrl) : null,
                    radius: 20,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: post.avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 24, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // User Name and Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            post.role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF0095F6),
                            ),
                          ),
                          Text(
                            '  •  ${post.timeAgo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  icon: Icon(Icons.more_vert, color: textColor),
                  onPressed: widget.onMoreMenuPressed,
                ),
              ],
            ),
          ),
          
          // 2. Multiline Status Description
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Text(
              post.statusText,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
          
          // 3. Main Post Image (Interactive with Double-Tap to Like animation)
          if (post.imageUrl.isNotEmpty)
          GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isDark ? const Color(0xFF161616) : Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0095F6),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? const Color(0xFF161616) : Colors.grey.shade100,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 48,
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Double tap animated heart overlay
                if (_showDoubleTapLikeOverlay)
                  AnimatedBuilder(
                    animation: _heartScaleAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _heartScaleAnim.value,
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 90,
                          shadows: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          // 4. Action Row (Likes, Comments, Shares, Bookmark)
// Action row (likes, comments, share, bookmark) removed
SizedBox.shrink(),
          
// Caption and tags removed
SizedBox.shrink(),
          
          // 6. Route Info Card
          if (post.hasRouteCard &&
              post.fromLocation != null &&
              post.toLocation != null &&
              post.departureTime != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 12.0),
              child: RouteInfoCard(
                fromLocation: post.fromLocation!,
                toLocation: post.toLocation!,
                departureTime: post.departureTime!,
                onCallPressed: widget.onCallPressed,
              ),
            ),
            
          const SizedBox(height: 12),
        ],
      ),
    );
  }


}
