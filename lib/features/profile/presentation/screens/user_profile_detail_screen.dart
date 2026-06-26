import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/posts_grid.dart';
import '../../domain/entities/profile_post.dart';
import 'search_user_screen.dart'; 

class UserProfileDetailScreen extends StatefulWidget {
  final SearchUser user;

  const UserProfileDetailScreen({super.key, required this.user});

  @override
  State<UserProfileDetailScreen> createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  List<ProfilePost> _userPosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  Future<void> _fetchUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.posts}');
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
          final List<ProfilePost> fetchedPosts = [];

          for (var jsonItem in jsonList) {
            final postMobile = jsonItem['userMobileNumber'] as String?;
            if (postMobile == widget.user.mobileNumber) {
              String imageUrl = jsonItem['postImage'] as String? ?? '';
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = '${ApiConstants.baseUrl}$imageUrl';
              }
              if (imageUrl.isEmpty) {
                imageUrl =
                    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop';
              }

              String description =
                  jsonItem['description'] as String? ?? 'No description';
              DateTime uploadTime = DateTime.now();
              if (jsonItem['createdAt'] != null) {
                uploadTime = DateTime.parse(jsonItem['createdAt']);
              }

              fetchedPosts.add(
                ProfilePost(
                  id: jsonItem['id'].toString(),
                  imageUrl: imageUrl,
                  description: description,
                  uploadTime: uploadTime,
                ),
              );
            }
          }

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
                    backgroundImage: widget.user.avatarUrl.isNotEmpty
                        ? NetworkImage(widget.user.avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: widget.user.avatarUrl.isEmpty
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
                        widget.user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.user.role,
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
                    backgroundImage: widget.user.avatarUrl.isNotEmpty
                        ? NetworkImage(widget.user.avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: widget.user.avatarUrl.isEmpty
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
                          _isLoadingPosts ? '-' : _userPosts.length.toString(),
                          'Posts',
                        ),
                        _buildStatColumn(widget.user.age.toString(), 'Age'),
                        _buildStatColumn(widget.user.role, 'Role'),
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
                        widget.user.name,
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
                          widget.user.role,
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
                        '${widget.user.city}, ${widget.user.state}',
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
                    widget.user.bio,
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

            // Contact button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final mobile = widget.user.mobileNumber;
                        if (mobile.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: mobile,
                          );
                          try {
                            await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not launch phone dialer for $mobile'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number is unavailable'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Contact User',
                              style: TextStyle(
                                color: Colors.white,
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
                : PostsGrid(posts: _userPosts, onPostTap: _showPostDetails),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
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
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
