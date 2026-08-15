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
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFB0B8D0) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor =
        isDark ? const Color(0xFFB0B8D0) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final pageBg = isDark ? Colors.black : const Color(0xFFEBF3FF);

    return Container(
      color: pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : const Color(0xFF1A3A6B).withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Stats row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: widget.onAvatarTapped,
                      child: Stack(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1565C0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1565C0)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: widget.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : widget.profile.avatarUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.profile.avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                            Icons.local_shipping_rounded,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.local_shipping_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border: Border.all(color: cardBg, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                              context, widget.postsCount.toString(), 'Vehicles'),
                          Container(
                              width: 1,
                              height: 32,
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE5E7EB)),
                          _buildStatColumn(
                            context,
                            widget.profile.followersCount.toString(),
                            'Followers',
                            onTap: widget.onFollowersTap,
                          ),
                          Container(
                              width: 1,
                              height: 32,
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE5E7EB)),
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

                const SizedBox(height: 14),

                // Name
                Text(
                  widget.profile.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Bio lines
                ...widget.profile.bioLines.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          height: 1.4,
                        ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Edit Profile + Share buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'Edit profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Add vehicle button (full-width)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Add vehicle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
