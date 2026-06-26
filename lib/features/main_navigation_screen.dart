import 'package:flutter/material.dart';
import 'profile/presentation/screens/profile_screen.dart';
import 'profile/presentation/screens/search_user_screen.dart';
import 'posts/presentation/screens/posts_feed_screen.dart';
import 'posts/presentation/screens/add_post_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0; // Start on the Home feed tab (index 0)
  final GlobalKey<PostsFeedScreenState> _feedKey = GlobalKey<PostsFeedScreenState>();
  final GlobalKey<SearchUserScreenState> _searchKey = GlobalKey<SearchUserScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PostsFeedScreen(key: _feedKey),
      AddPostScreen(
        onPostPublished: () {
          setState(() {
            _selectedIndex = 0; // Redirect to Home Feed tab
          });
          // Refresh the feed to show the newly added post
          _feedKey.currentState?.refreshFeed();
        },
      ),
      SearchUserScreen(
        key: _searchKey,
        onSetLocationRequested: () {
          setState(() {
            _selectedIndex = 3; // Redirect to Profile tab
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _profileKey.currentState?.showEditLocationSheet();
          });
        },
      ),
      ProfileScreen(
        key: _profileKey,
        onPostDeleted: () {
          _feedKey.currentState?.refreshFeed();
        },
        onNavigateToAddPost: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      _searchKey.currentState?.refreshLocationAndUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          border: Theme.of(context).brightness == Brightness.dark
              ? const Border(top: BorderSide(color: Color(0xFF262626), width: 0.5))
              : null,
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.add_box, Icons.add_box_outlined, 'Add'),
                _buildNavItem(2, Icons.search, Icons.search_outlined, 'Search'),
                _buildNavItem(3, Icons.person, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF0095F6) : Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6).withValues(alpha: isDark ? 0.15 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: const Color(0xFF0095F6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFA8A8A8) : Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
