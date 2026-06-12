import 'package:flutter/material.dart';
import 'package:truck_mate/main.dart';
import '../../domain/entities/profile_post.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/mock_profile_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/posts_grid.dart';
import '../widgets/fallback_posts_view.dart';
import 'package:truck_mate/core/local_storage/datasources/theme_local_datasource.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = MockProfileRepository();
  UserProfile _profile = const UserProfile(
    name: 'Loading...',
    role: '',
    avatarUrl: '',
    bioLines: [],
    isJoined: false,
  );
  List<ProfilePost> _allPosts = [];
  bool _showEmptyState = false;
  bool _isLoading = true;

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
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final profile = await _repository.getUserProfile();
      final posts = await _repository.getUploadedPosts();
      if (mounted) {
        setState(() {
          _profile = profile;
          _allPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleJoin() async {
    try {
      final updatedProfile = await _repository.toggleJoinMembership();
      if (mounted) {
        setState(() {
          _profile = updatedProfile;
        });
      }

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
    } catch (e) {
      // Handle error
    }
  }

  void _addMockPost() async {
    try {
      final newIndex = _allPosts.length;
      final imageIndex = newIndex % _truckImages.length;
      final newPost = ProfilePost(
        id: 'post_custom_${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: _truckImages[imageIndex],
        description: 'New shipment dispatched successfully! 🚚 #TruckMate #RameshTransport',
        uploadTime: DateTime.now(),
      );

      await _repository.uploadPost(newPost);
      final posts = await _repository.getUploadedPosts();
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _showEmptyState = false;
        });
      }

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
    } catch (e) {
      // Handle error
    }
  }

  void _showThemeSelectionDialog() {
    final currentMode = MyApp.themeNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Select Theme',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text('System Theme', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
                value: ThemeMode.system,
                groupValue: currentMode,
                activeColor: const Color(0xFF0095F6),
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    _updateTheme(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Light Theme', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
                value: ThemeMode.light,
                groupValue: currentMode,
                activeColor: const Color(0xFF0095F6),
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    _updateTheme(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark Theme', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
                value: ThemeMode.dark,
                groupValue: currentMode,
                activeColor: const Color(0xFF0095F6),
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    _updateTheme(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateTheme(ThemeMode mode) {
    MyApp.themeNotifier.value = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
      default:
        modeStr = 'system';
        break;
    }
    ThemeLocalDatasource().saveThemeMode(modeStr);
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
              } else if (value == 'change_theme') {
                _showThemeSelectionDialog();
              } else if (value == 'reset') {
                (_repository as MockProfileRepository).resetMockData();
                _loadProfileData();
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
                value: 'change_theme',
                child: Row(
                  children: const [
                    Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: Color(0xFF0095F6),
                    ),
                    const SizedBox(width: 10),
                    Text('Change Theme'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0095F6)))
            : RefreshIndicator(
                onRefresh: () async {
                  final posts = await _repository.getUploadedPosts();
                  if (mounted) {
                    setState(() {
                      _allPosts = posts;
                      if (_showEmptyState) {
                        _showEmptyState = false;
                      }
                    });
                  }
                },
                color: const Color(0xFF0095F6),
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
}
