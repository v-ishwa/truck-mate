import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import 'package:truck_mate/core/network/api_constants.dart';

class ProfileHeader extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onJoinToggled;
  final VoidCallback? onAvatarTapped;
  final VoidCallback? onEditLocation;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onJoinToggled,
    this.onAvatarTapped,
    this.onEditLocation,
    this.isLoading = false,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isJoined = widget.profile.isJoined;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultAvatar = CircleAvatar(
      radius: 45,
      backgroundColor: const Color(0xFF0D47A1),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Avatar and Join Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Avatar with shadow & border
              GestureDetector(
                onTap: widget.onAvatarTapped,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: widget.isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0095F6)))
                            : widget.profile.avatarUrl.isNotEmpty
                                ? Image.network(
                                    widget.profile.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => defaultAvatar,
                                  )
                                : defaultAvatar,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              
              // Join Button on the right
              Expanded(
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  onTap: widget.onJoinToggled,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isJoined
                            ? (isDark ? const Color(0xFF1B5E20).withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
                            : const Color(0xFF0095F6),
                        borderRadius: BorderRadius.circular(10),
                        border: isJoined
                            ? Border.all(color: isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784), width: 1.5)
                            : null,
                        boxShadow: isJoined
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0095F6).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isJoined) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isJoined ? 'Joined' : 'Join',
                              style: TextStyle(
                                color: isJoined
                                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Profile Details (Name, Role, Bio Lines)
          Text(
            widget.profile.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.profile.role,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2196F3), // Owner role highlighted in blue
            ),
          ),
          const SizedBox(height: 8),
          
          // Bio bullet list
          ...widget.profile.bioLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFFA8A8A8) : const Color(0xFF4A4A4A),
                    height: 1.3,
                  ),
                ),
              )),
          const SizedBox(height: 12),
          
          // Edit Location Button
          InkWell(
            onTap: widget.onEditLocation,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF333333) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_location_alt_rounded, size: 16, color: isDark ? Colors.white70 : Colors.grey.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
