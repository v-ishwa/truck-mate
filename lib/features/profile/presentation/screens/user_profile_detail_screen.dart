import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/posts_grid.dart';
import '../widgets/follow_button_widget.dart';
import '../../domain/entities/profile_post.dart';
import '../../data/repositories/follow_repository.dart';
import 'search_user_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';

class UserProfileDetailScreen extends StatefulWidget {
  final SearchUser user;

  const UserProfileDetailScreen({super.key, required this.user});

  @override
  State<UserProfileDetailScreen> createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  late SearchUser _user;
  List<ProfilePost> _userPosts = [];
  bool _isLoadingPosts = true;
  bool _isLoadingStats = true;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;

  final _followRepo = FollowRepository();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _followersCount = widget.user.followersCount;
    _followingCount = widget.user.followingCount;
    _isFollowing = widget.user.isFollowing;
    _fetchUserPosts();
    _fetchFollowStats();
    // Re-fetch target user stats whenever any follow/unfollow fires
    FollowRepository.followEventNotifier.addListener(_fetchFollowStats);
  }

  @override
  void dispose() {
    FollowRepository.followEventNotifier.removeListener(_fetchFollowStats);
    super.dispose();
  }

  Future<void> _fetchFollowStats() async {
    setState(() => _isLoadingStats = true);
    final result = await _followRepo.getFollowStats(_user.id);
    if (mounted) {
      setState(() {
        _followersCount = result.followersCount;
        _followingCount = result.followingCount;
        _isFollowing = result.isFollowing;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userPosts}/${_user.id}');
        final response = await http
            .get(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          final List<ProfilePost> fetchedPosts = jsonList.map((jsonItem) {
            String imageUrl = jsonItem['postImage'] as String? ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = '${ApiConstants.baseUrl}$imageUrl';
            }
            if (imageUrl.isEmpty) {
              imageUrl =
                  'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop';
            }
            return ProfilePost(
              id: jsonItem['id'].toString(),
              imageUrl: imageUrl,
              description: jsonItem['description'] as String? ?? '',
              uploadTime: jsonItem['createdAt'] != null
                  ? DateTime.parse(jsonItem['createdAt'])
                  : DateTime.now(),
            );
          }).toList();

          if (mounted) {
            setState(() {
              _userPosts = fetchedPosts;
              _isLoadingPosts = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      // Handle error gracefully
    }
    if (mounted) {
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  void _showPostDetails(ProfilePost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _user.avatarUrl.isNotEmpty
                        ? NetworkImage(_user.avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: _user.avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _user.role,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(post.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                post.description,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploaded on ${post.uploadTime.day}/${post.uploadTime.month}/${post.uploadTime.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.green.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact ${_user.name}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _user.mobileNumber.isNotEmpty
                    ? _user.mobileNumber
                    : 'Contact number unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF64B5F6)
                      : const Color(0xFF0095F6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF333333)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF1C1C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final contactNumber = _user.mobileNumber;
                        if (contactNumber.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: contactNumber,
                          );
                          try {
                            await launchUrl(launchUri,
                                mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Could not launch phone dialer for $contactNumber'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number is unavailable'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Call Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    // Role color mappings
    Color roleBadgeColor;
    Color roleTextColor;
    switch (widget.user.role) {
      case 'Driver':
        roleBadgeColor = Colors.blue.withOpacity(0.1);
        roleTextColor = Colors.blue;
        break;
      case 'Owner':
        roleBadgeColor = Colors.green.withOpacity(0.1);
        roleTextColor = Colors.green;
        break;
      case 'Mechanic':
        roleBadgeColor = Colors.orange.withOpacity(0.1);
        roleTextColor = Colors.orange;
        break;
      default:
        roleBadgeColor = Colors.grey.withOpacity(0.1);
        roleTextColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.user.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Info
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _user.avatarUrl.isNotEmpty
                        ? NetworkImage(_user.avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: _user.avatarUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          _isLoadingPosts
                              ? '-'
                              : _userPosts.length.toString(),
                          'Posts',
                          onTap: null,
                        ),
                        _buildStatColumn(
                          _isLoadingStats ? '-' : _followersCount.toString(),
                          'Followers',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersListScreen(
                                userId: _user.id,
                                userName: _user.name,
                              ),
                            ),
                          ).then((_) => _fetchFollowStats()),
                        ),
                        _buildStatColumn(
                          _isLoadingStats ? '-' : _followingCount.toString(),
                          'Following',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowingListScreen(
                                userId: _user.id,
                                userName: _user.name,
                              ),
                            ),
                          ).then((_) => _fetchFollowStats()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User Info details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _user.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleBadgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _user.role,
                          style: TextStyle(
                            color: roleTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: roleTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_user.city}, ${_user.state}',
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user.bio,
                    style: TextStyle(
                      fontSize: 14,
                      color: subTextColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Follow and Contact Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Follow Button (real API)
                  Expanded(
                    child: FollowButton(
                      targetUserId: _user.id,
                      initialIsFollowing: _isFollowing,
                      onChanged: (result) {
                        // Update follow state immediately (optimistic)
                        setState(() {
                          _isFollowing = result.isFollowing;
                          _followersCount = result.followersCount;
                          _followingCount = result.followingCount;
                        });
                        // Re-fetch from DB for guaranteed real-time accuracy
                        _fetchFollowStats();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contact Button
                  Expanded(
                    child: GestureDetector(
                      onTap: _showContactBottomSheet,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF363636)
                                  : const Color(0xFFDBDBDB),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color:
                                  isDark ? Colors.white70 : Colors.black87,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Contact',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),

            // Posts Grid Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Uploaded Loads & Posts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _isLoadingPosts
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0095F6),
                      ),
                    ),
                  )
                : _userPosts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : PostsGrid(
                        posts: _userPosts, onPostTap: _showPostDetails),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: onTap != null
                  ? const Color(0xFF0095F6)
                  : Colors.grey.shade500,
              decoration:
                  onTap != null ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
