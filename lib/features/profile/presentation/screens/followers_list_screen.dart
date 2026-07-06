import 'package:flutter/material.dart';
import 'package:truck_mate/features/profile/data/repositories/follow_repository.dart';
import 'package:truck_mate/features/profile/presentation/screens/search_user_screen.dart';
import 'package:truck_mate/features/profile/presentation/screens/user_profile_detail_screen.dart';
import 'package:truck_mate/features/profile/presentation/widgets/follow_button_widget.dart';

/// Screen that lists all followers for a given user.
class FollowersListScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final _followRepo = FollowRepository();
  List<SearchUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    final users = await _followRepo.getFollowers(widget.userId);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Followers',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              widget.userName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0095F6)))
          : _users.isEmpty
              ? _buildEmpty(isDark)
              : RefreshIndicator(
                  onRefresh: _loadFollowers,
                  color: const Color(0xFF0095F6),
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) =>
                        _UserRow(user: _users[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 56, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No followers yet',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row card for a single user in a followers/following list.
class _UserRow extends StatelessWidget {
  final SearchUser user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color roleColor;
    switch (user.role) {
      case 'Driver':
        roleColor = Colors.blue;
        break;
      case 'Owner':
        roleColor = Colors.green;
        break;
      case 'Mechanic':
        roleColor = Colors.orange;
        break;
      default:
        roleColor = Colors.grey;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileDetailScreen(user: user),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF0D47A1),
              backgroundImage:
                  user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 26)
                  : null,
            ),
            const SizedBox(width: 12),
            // Name + role + location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.city}, ${user.state}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Follow button
            SizedBox(
              width: 110,
              child: FollowButton(
                targetUserId: user.id,
                initialIsFollowing: user.isFollowing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
