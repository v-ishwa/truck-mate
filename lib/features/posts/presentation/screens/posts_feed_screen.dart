import 'package:flutter/material.dart';


import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/post.dart';
import '../../data/repositories/api_posts_repository.dart';
import '../widgets/post_card.dart';
import '../../../profile/presentation/screens/user_profile_detail_screen.dart';
import '../../../profile/presentation/screens/search_user_screen.dart';

class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => PostsFeedScreenState();
}

class PostsFeedScreenState extends State<PostsFeedScreen> {
  final ApiPostsRepository _repository = ApiPostsRepository();
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = await _repository.getPosts();
      _repository.updateCache(posts);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // Public method to allow parent widget to trigger a reload or scroll to top
  Future<void> refreshFeed() async {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    await _loadFeed();
  }

  void _handleLike(String postId) async {
    try {
      final updatedPost = await _repository.toggleLike(postId);
      setState(() {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void _handleBookmark(String postId) async {
    try {
      final updatedPost = await _repository.toggleBookmark(postId);
      setState(() {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void _handleProfilePressed(Post post) {
    String city = 'Chennai';
    String state = 'Tamil Nadu';
    if (post.fromLocation != null && post.fromLocation!.contains(',')) {
      final parts = post.fromLocation!.split(',');
      if (parts.length >= 2) {
        city = parts[0].trim();
        state = parts[1].trim();
      } else if (parts.isNotEmpty) {
        city = parts[0].trim();
      }
    }

    final user = SearchUser(
      id: post.userId,   // ✅ real user ID from backend
      name: post.userName,
      role: post.role,
      age: 0,
      state: state,
      city: city,
      avatarUrl: post.avatarUrl,
      bio: 'Services: ${post.role}. Contact for bookings.',
      mobileNumber: post.contactNumber ?? '',
      followersCount: 0,   // profile screen will fetch real counts
      followingCount: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileDetailScreen(user: user),
      ),
    );
  }

  void _handleCallOwner(Post post) {
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
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
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
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.green.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Contact ${post.userName}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.contactNumber ?? 'Contact number unavailable',
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
                        final contactNumber = post.contactNumber;
                        if (contactNumber != null && contactNumber.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: contactNumber,
                          );
                          try {
                            await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not launch phone dialer for $contactNumber'),
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

  void _handleMoreOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tileColor = isDark ? Colors.white70 : const Color(0xFF1C1C1C);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.share_rounded, color: tileColor),
                title: Text('Share Post', style: TextStyle(color: tileColor)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing capability coming soon!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.link_rounded, color: tileColor),
                title: Text('Copy Link', style: TextStyle(color: tileColor)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Report Post',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you, this post has been reported.'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFilterTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Posts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildFilterChip('All Posts', true),
                  _buildFilterChip('Truck Available', false),
                  _buildFilterChip('Mechanic', false),
                  _buildFilterChip('Load Booking', false),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0095F6),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {},
      selectedColor: const Color(0xFF0095F6).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? const Color(0xFF0095F6)
            : (isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF0095F6)
              : (isDark ? const Color(0xFF262626) : Colors.grey.shade300),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPosts = _posts.where((post) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final statusMatch = post.statusText.toLowerCase().contains(query);
      final fromMatch =
          post.fromLocation?.toLowerCase().contains(query) ?? false;
      final toMatch = post.toLocation?.toLowerCase().contains(query) ?? false;
      final nameMatch = post.userName.toLowerCase().contains(query);
      return statusMatch || fromMatch || toMatch || nameMatch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFEBF3FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A1A) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEBF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1565C0),
              size: 22,
            ),
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'Truck',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const TextSpan(
                text: 'Mate',
                style: TextStyle(color: Color(0xFF1565C0)),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEBF3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1565C0),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : const Color(0xFF1A3A6B).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by location or name...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFF9CA3AF),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleFilterTap,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : const Color(0xFF1A3A6B).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: isDark
                                ? const Color(0xFF4A90D9)
                                : const Color(0xFF1565C0),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF4A90D9)
                                  : const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feed List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0095F6),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 64,
                                  color: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _loadFeed,
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: Colors.white),
                                  label: const Text('Retry',
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0095F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: refreshFeed,
                          color: const Color(0xFF0095F6),
                          child: filteredPosts.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height * 0.2,
                                    ),
                                    Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 64,
                                            color: isDark
                                                ? Colors.white30
                                                : Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No matching posts found'
                                                : 'No posts yet. Be the first to post!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                                  itemCount: filteredPosts.length,
                                  itemBuilder: (context, index) {
                                    final post = filteredPosts[index];
                                    return PostCard(
                                      post: post,
                                      onLikePressed: () => _handleLike(post.id),
                                      onBookmarkPressed: () =>
                                          _handleBookmark(post.id),
                                      onCallPressed: () => _handleCallOwner(post),
                                      onMoreMenuPressed: () =>
                                          _handleMoreOptions(post),
                                      onProfilePressed: () => _handleProfilePressed(post),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
