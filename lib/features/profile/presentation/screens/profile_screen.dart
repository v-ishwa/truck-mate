import 'package:flutter/material.dart';
import 'package:truck_mate/main.dart';
import '../../domain/entities/profile_post.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/profile_header.dart';
import '../widgets/posts_grid.dart';
import '../widgets/fallback_posts_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock Data definitions
  late UserProfile _profile;
  final List<ProfilePost> _allPosts = [];
  bool _showEmptyState = false;
  int _activeTab = 0; // 0 = Grid, 1 = Videos, 2 = Mentions

  // Curated list of premium truck photo URLs from Unsplash
  final List<String> _truckImages = [
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1591768793355-74d75b50f58f?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1516576880881-148f8f68740b?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1532601224476-15c79f2f7a51?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1616422285623-13ff0162193c?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1501700490688-6161b2b58f6b?q=80&w=400&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1592838064808-04a4b518410b?q=80&w=400&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize user profile
    _profile = const UserProfile(
      name: 'Ramesh Transport',
      role: 'Owner',
      avatarUrl: 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?q=80&w=200&auto=format&fit=crop',
      bioLines: [
        'Safe & On-time Delivery 🚚',
        'Pan India Services',
        'Contact for load bookings.',
      ],
      isJoined: false,
    );

    // Initialize with mock posts
    _loadMockPosts();
  }

  void _loadMockPosts() {
    _allPosts.clear();
    for (int i = 0; i < _truckImages.length; i++) {
      _allPosts.add(
        ProfilePost(
          id: 'post_$i',
          imageUrl: _truckImages[i],
          description: 'Proud to deliver safe & on-time load #$i! 🚚💨 #RameshTransport',
          uploadTime: DateTime.now().subtract(Duration(days: i * 2)),
        ),
      );
    }
  }

  void _toggleJoin() {
    setState(() {
      _profile = _profile.copyWith(isJoined: !_profile.isJoined);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _profile.isJoined ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_profile.isJoined
                  ? 'Welcome! You have joined Ramesh Transport membership.'
                  : 'You have left Ramesh Transport membership.'),
            ),
          ],
        ),
        backgroundColor: _profile.isJoined ? Colors.green.shade600 : const Color(0xFF1C1C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addMockPost() {
    setState(() {
      final newIndex = _allPosts.length;
      final imageIndex = newIndex % _truckImages.length;
      final newPost = ProfilePost(
        id: 'post_$newIndex',
        imageUrl: _truckImages[imageIndex],
        description: 'New shipment dispatched successfully! 🚚 #TruckMate #RameshTransport',
        uploadTime: DateTime.now(),
      );
      
      _allPosts.insert(0, newPost);
      _showEmptyState = false; // automatically swap to grid view
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Successfully simulated uploading a new post!'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0095F6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                    backgroundImage: NetworkImage(_profile.avatarUrl),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Owner',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    final bool isEmpty = _showEmptyState || _allPosts.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          _profile.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Developer simulation menu (the 3-dots in reference UI)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : const Color(0xFF1C1C1C)),
            onSelected: (value) {
              if (value == 'toggle_state') {
                setState(() {
                  _showEmptyState = !_showEmptyState;
                });
              } else if (value == 'toggle_theme') {
                final currentMode = MyApp.themeNotifier.value;
                MyApp.themeNotifier.value =
                    currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              } else if (value == 'reset') {
                setState(() {
                  _showEmptyState = false;
                  _loadMockPosts();
                  _profile = _profile.copyWith(isJoined: false);
                });
              } else if (value == 'add_mock') {
                _addMockPost();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_state',
                child: Row(
                  children: [
                    Icon(
                      _showEmptyState ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                      size: 20,
                      color: const Color(0xFF0095F6),
                    ),
                    const SizedBox(width: 10),
                    Text(_showEmptyState ? 'Show Grid State' : 'Show Empty Fallback'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_mock',
                child: Row(
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Text('Simulate Post Upload'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_theme',
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                      color: const Color(0xFF0095F6),
                    ),
                    const SizedBox(width: 10),
                    Text(isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    const Text('Reset Simulation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh action
            await Future.delayed(const Duration(seconds: 1));
            setState(() {
              if (_showEmptyState) {
                _showEmptyState = false;
              }
              _loadMockPosts();
            });
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header & Bio
              SliverToBoxAdapter(
                child: ProfileHeader(
                  profile: _profile,
                  onJoinToggled: _toggleJoin,
                ),
              ),

              // Tab bars matching the UI design (Grid, Reels, Tagged)
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: isDark ? const Color(0xFF262626) : Colors.grey.shade200, width: 0.5),
                      bottom: BorderSide(color: isDark ? const Color(0xFF262626) : Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, Icons.grid_on_sharp),
                      _buildTabButton(1, Icons.video_library_outlined),
                      _buildTabButton(2, Icons.account_box_outlined),
                    ],
                  ),
                ),
              ),

              // Post content or fallback
              if (isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FallbackPostsView(
                    onUploadPressed: _addMockPost,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 2),
                  sliver: SliverToBoxAdapter(
                    child: PostsGrid(
                      posts: _allPosts,
                      onPostTap: _showPostDetails,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon) {
    final isSelected = _activeTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
            // For mock logic: Video & Mention tabs can simulate empty fallback, grid tab has our data
            if (index != 0) {
              _showEmptyState = true;
            } else {
              _showEmptyState = false;
            }
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected 
                    ? (isDark ? Colors.white : const Color(0xFF1C1C1C)) 
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? (isDark ? Colors.white : const Color(0xFF1C1C1C)) 
                : Colors.grey.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }
}
