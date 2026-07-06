import 'package:flutter/material.dart';
import 'package:truck_mate/features/profile/data/repositories/follow_repository.dart';

/// A reusable Follow/Following/Unfollow button that syncs with the backend.
///
/// Pass [targetUserId], [initialIsFollowing], and optionally an [onChanged]
/// callback which receives the new [FollowResult] on success.
class FollowButton extends StatefulWidget {
  final int targetUserId;
  final bool initialIsFollowing;
  final double height;
  final ValueChanged<FollowResult>? onChanged;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.initialIsFollowing = false,
    this.height = 44,
    this.onChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late bool _isFollowing;
  bool _isLoading = false;
  final _followRepo = FollowRepository();
  late AnimationController _animationController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _animationController;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsFollowing != widget.initialIsFollowing) {
      _isFollowing = widget.initialIsFollowing;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    // Bounce animation
    await _animationController.reverse();
    _animationController.forward();

    // Optimistic update
    final bool newState = !_isFollowing;
    setState(() {
      _isFollowing = newState;
      _isLoading = true;
    });

    final FollowResult result;
    if (newState) {
      result = await _followRepo.followUser(widget.targetUserId);
    } else {
      result = await _followRepo.unfollowUser(widget.targetUserId);
    }

    if (mounted) {
      if (!result.success) {
        // Roll back on failure
        setState(() {
          _isFollowing = !newState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message.isNotEmpty ? result.message : 'Action failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isFollowing = result.isFollowing;
        });
        widget.onChanged?.call(result);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            color: _isFollowing
                ? (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF))
                : const Color(0xFF0095F6),
            borderRadius: BorderRadius.circular(10),
            border: _isFollowing
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF363636)
                        : const Color(0xFFDBDBDB),
                    width: 1,
                  )
                : null,
          ),
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isFollowing
                          ? (isDark ? Colors.white54 : Colors.black54)
                          : Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isFollowing) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: _isFollowing
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
