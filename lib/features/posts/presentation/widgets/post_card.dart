import 'package:flutter/material.dart';
import '../../domain/entities/post.dart';
import 'route_info_card.dart';
import 'package:truck_mate/core/widgets/truck_illustration.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLikePressed;
  final VoidCallback onBookmarkPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onMoreMenuPressed;
  final VoidCallback? onProfilePressed;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikePressed,
    required this.onBookmarkPressed,
    required this.onCallPressed,
    required this.onMoreMenuPressed,
    this.onProfilePressed,
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

    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? const Color(0xFFB0B8D0) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF1A3A6B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Post Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onProfilePressed,
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1565C0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: post.avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    post.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.local_shipping_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Name + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.role,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // More menu button
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: subtitleColor,
                    size: 22,
                  ),
                  onPressed: widget.onMoreMenuPressed,
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // ── 2. Truck Illustration / Image Area ────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 150,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1C3F) : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: post.imageUrl.isNotEmpty
                ? GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 150,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white38 : const Color(0xFF1565C0),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                _buildTruckPlaceholder(isDark),
                          ),
                        ),
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
                  )
                : _buildTruckPlaceholder(isDark),
          ),

          // ── 3. Message + Call Buttons ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Message button (outlined)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                    label: Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF374151),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Call Owner button (filled blue)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onCallPressed,
                    icon: const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Call Owner',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 4. Route Info ─────────────────────────────────────────
          if (post.hasRouteCard &&
              post.fromLocation != null &&
              post.toLocation != null &&
              post.departureTime != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: RouteInfoCard(
                fromLocation: post.fromLocation!,
                toLocation: post.toLocation!,
                departureTime: post.departureTime!,
                onCallPressed: widget.onCallPressed,
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTruckPlaceholder(bool isDark) {
    final tyres = TruckIllustration.parseTyreCount(widget.post.role);
    final truckColor =
        isDark ? const Color(0xFF3D6CBF) : const Color(0xFF1565C0);
    return Center(
      child: TruckIllustration(
        tyreCount: tyres,
        color: truckColor,
        size: const Size(220, 90),
      ),
    );
  }
}
