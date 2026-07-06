import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class ProfileHeader extends StatefulWidget {
  final UserProfile profile;
  final int postsCount;
  final VoidCallback? onAvatarTapped;
  final VoidCallback? onEditLocation;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.postsCount,
    this.onAvatarTapped,
    this.onEditLocation,
    this.onFollowersTap,
    this.onFollowingTap,
    this.isLoading = false,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  Widget _buildStatColumn(
    BuildContext context,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: onTap != null
                  ? const Color(0xFF0095F6)
                  : (isDark ? const Color(0xFFA8A8A8) : const Color(0xFF4A4A4A)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Row with Avatar and Stats
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
              const SizedBox(width: 24),
              
              // Stats next to Avatar (Instagram layout)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(context, widget.postsCount.toString(), 'Posts'),
                    _buildStatColumn(
                      context,
                      widget.profile.followersCount.toString(),
                      'Followers',
                      onTap: widget.onFollowersTap,
                    ),
                    _buildStatColumn(
                      context,
                      widget.profile.followingCount.toString(),
                      'Following',
                      onTap: widget.onFollowingTap,
                    ),
                  ],
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
          const SizedBox(height: 16),
          
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
