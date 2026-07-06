import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:truck_mate/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:truck_mate/main.dart';
import '../../domain/entities/profile_post.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/mock_profile_repository.dart';
import '../../data/repositories/follow_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/posts_grid.dart';
import '../widgets/fallback_posts_view.dart';
import 'package:truck_mate/core/local_storage/datasources/theme_local_datasource.dart';
import 'package:truck_mate/features/auth/domain/repositories/auth_repository.dart';
import 'package:truck_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:truck_mate/features/auth/presentation/screens/login_screen.dart';
import 'followers_list_screen.dart';
import 'following_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onPostDeleted;
  final VoidCallback? onNavigateToAddPost;

  const ProfileScreen({
    super.key,
    this.onPostDeleted,
    this.onNavigateToAddPost,
  });

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  void showEditLocationSheet() {
    _showEditLocationSheet();
  }

  Future<void> refreshProfile() async {
    await _loadProfileData(false);
  }
  final ProfileRepository _repository = MockProfileRepository();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final FollowRepository _followRepository = FollowRepository();
  int? _ownUserId;
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
  bool _isProfilePicLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 50,
    );
    if (image == null) return;

    setState(() {
      _isProfilePicLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      if (token == null || userId == null) {
        throw Exception('User not logged in properly.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProfileImage}');
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['userId'] = userId.toString();
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final newImageUrl = data['imageUrl'] as String?;
          if (newImageUrl != null && newImageUrl.isNotEmpty) {
            await prefs.setString('user_profile_picture', newImageUrl);
          }
          await _loadProfileData(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Profile image updated successfully!'), backgroundColor: Colors.green.shade600),
            );
          }
        }
      } else {
        throw Exception('Failed to upload image.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProfilePicLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    Navigator.pop(context); // close bottom sheet
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _isProfilePicLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('user_id');
      if (token == null || userId == null) {
        throw Exception('User not logged in properly.');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadProfileImage}/$userId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await prefs.remove('user_profile_picture');
          await _loadProfileData(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Profile photo removed'), backgroundColor: Colors.green.shade600),
            );
          }
        }
      } else {
        throw Exception('Failed to remove image.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProfilePicLoading = false;
        });
      }
    }
  }

  void _showImageSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Update Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF0095F6)),
                title: Text('Gallery', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
                onTap: () => _pickAndUploadProfileImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1C1C1C))),
                onTap: () => _pickAndUploadProfileImage(ImageSource.camera),
              ),
              if (_profile.avatarUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: _deleteProfileImage,
                ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    _loadProfileData();
    // Re-fetch own stats whenever any follow/unfollow occurs in the app
    FollowRepository.followEventNotifier.addListener(_onFollowEvent);
  }

  void _onFollowEvent() {
    _loadProfileData(false);
  }

  @override
  void dispose() {
    FollowRepository.followEventNotifier.removeListener(_onFollowEvent);
    super.dispose();
  }

  Future<void> _loadProfileData([bool showLoading = true]) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      // Load own userId from prefs (set during login)
      if (_ownUserId == null) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getInt('user_id');
        if (id != null && mounted) {
          setState(() => _ownUserId = id);
        }
      }

      final profile = await _repository.getUserProfile();
      final posts = await _repository.getUploadedPosts();

      // Fetch real follower/following counts for own profile
      UserProfile enrichedProfile = profile;
      if (_ownUserId != null) {
        final stats = await _followRepository.getFollowStats(_ownUserId!);
        enrichedProfile = profile.copyWith(
          followersCount: stats.followersCount,
          followingCount: stats.followingCount,
        );
      }

      if (mounted) {
        setState(() {
          _profile = enrichedProfile;
          _allPosts = posts;
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (showLoading) {
            _isLoading = false;
          }
        });
      }
    }
  }


  void _showEditLocationSheet() {
    String? tempState = _profile.state;
    String? tempCity = _profile.city;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1C) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Edit Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('State', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempState,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: (AppConstants.stateCityMap.keys.toList()..sort()).map((state) {
                      return DropdownMenuItem(value: state, child: Text(state, style: TextStyle(color: textColor)));
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        tempState = val;
                        tempCity = null; // reset city when state changes
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('City', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCity,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: tempState == null ? 'Select State first' : 'Select City',
                    ),
                    items: ((tempState != null ? AppConstants.stateCityMap[tempState]! : <String>[]).toList()..sort()).map((city) {
                      return DropdownMenuItem(value: city, child: Text(city, style: TextStyle(color: textColor)));
                    }).toList(),
                    onChanged: tempState == null ? null : (val) {
                      setModalState(() {
                        tempCity = val;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (tempState != null && tempCity != null) {
                          Navigator.pop(context);
                          await _saveLocation(tempState!, tempCity!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0095F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveLocation(String state, String city) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}');
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'state': state,
            'city': city,
          }),
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            await prefs.setString('user_state', state);
            await prefs.setString('user_city', city);
            await _loadProfileData(false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location updated successfully'), backgroundColor: Colors.green),
              );
            }
            return;
          }
        }
      }
      
      // Fallback for mock if API fails
      await prefs.setString('user_state', state);
      await prefs.setString('user_city', city);
      await _loadProfileData(false);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        modeStr = 'system';
        break;
    }
    ThemeLocalDatasource().saveThemeMode(modeStr);
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // Show loading indicator while logging out
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0095F6)),
      ),
    );
    try {
      await _authRepository.logout();
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _deletePost(String postId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0095F6)),
      ),
    );
    try {
      final success = await _repository.deletePost(postId);
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
      }
      if (success) {
        if (mounted) {
          setState(() {
            _allPosts.removeWhere((p) => p.id == postId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post deleted successfully'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          widget.onPostDeleted?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete post'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Post',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deletePost(postId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPostDetails(ProfilePost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                           child: _profile.avatarUrl.isNotEmpty
                              ? Image.network(_profile.avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const CircleAvatar(radius: 20, backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, size: 24, color: Colors.white)))
                              : const CircleAvatar(radius: 20, backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, size: 24, color: Colors.white)),
                        ),
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
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmationDialog(post.id);
                    },
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_profile.name),
        actions: [
          // Developer simulation menu (the 3-dots in reference UI)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : const Color(0xFF1C1C1C)),
            onSelected: (value) {
              if (value == 'change_theme') {
                _showThemeSelectionDialog();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_theme',
                child: Row(
                  children: const [
                    Icon(
                      Icons.palette_outlined,
                      size: 20,
                      color: Color(0xFF0095F6),
                    ),
                    SizedBox(width: 10),
                    Text('Change Theme'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
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
                        postsCount: _allPosts.length,
                        onAvatarTapped: _showImageSourceSheet,
                        onEditLocation: _showEditLocationSheet,
                        isLoading: _isProfilePicLoading,
                        onFollowersTap: _ownUserId == null
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersListScreen(
                                      userId: _ownUserId!,
                                      userName: _profile.name,
                                    ),
                                  ),
                                ),
                        onFollowingTap: _ownUserId == null
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowingListScreen(
                                      userId: _ownUserId!,
                                      userName: _profile.name,
                                    ),
                                  ),
                                ),
                      ),
                    ),

                    // Post content or fallback
                    if (isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: FallbackPostsView(
                          onUploadPressed: widget.onNavigateToAddPost ?? () {},
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
