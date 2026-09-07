import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truck_mate/core/network/api_constants.dart';
import 'package:truck_mate/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_profile_detail_screen.dart';

class SearchUser {
  final int id;
  final String name;
  final String role; // Driver, Owner, Mechanic
  final int age;
  final String state;
  final String city;
  final String avatarUrl;
  final String bio;
  final String mobileNumber;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  const SearchUser({
    required this.id,
    required this.name,
    required this.role,
    required this.age,
    required this.state,
    required this.city,
    required this.avatarUrl,
    required this.bio,
    required this.mobileNumber,
    required this.followersCount,
    required this.followingCount,
    this.isFollowing = false,
  });

  SearchUser copyWith({
    int? id,
    String? name,
    String? role,
    int? age,
    String? state,
    String? city,
    String? avatarUrl,
    String? bio,
    String? mobileNumber,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return SearchUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      age: age ?? this.age,
      state: state ?? this.state,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    int calculateAge(dynamic dobVal) {
      if (dobVal == null) return 30; // default age
      final dobString = dobVal.toString();
      if (dobString.isEmpty) return 30;
      try {
        DateTime dob = DateTime.parse(dobString);
        DateTime today = DateTime.now();
        int age = today.year - dob.year;
        if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
          age--;
        }
        return age;
      } catch (e) {
        return 30;
      }
    }

    String avatarUrl = json['profilePicture'] as String? ?? '';
    if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = '${ApiConstants.baseUrl}$avatarUrl';
    }

    final rawRole = json['role'] as String? ?? 'driver';
    String mappedRole = 'Driver';
    if (rawRole.toLowerCase() == 'owner') {
      mappedRole = 'Owner';
    } else if (rawRole.toLowerCase() == 'mechanic') {
      mappedRole = 'Mechanic';
    }

    final userId = json['id'] as int? ?? 0;

    return SearchUser(
      id: userId,
      name: json['name'] as String? ?? 'Unknown',
      role: mappedRole,
      age: calculateAge(json['dob']),
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      avatarUrl: avatarUrl,
      bio: json['bio'] as String? ?? 'Ready for loads and jobs.',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? json['following'] as bool? ?? false,
    );
  }
}

class SearchUserScreen extends StatefulWidget {
  final VoidCallback? onSetLocationRequested;
  const SearchUserScreen({super.key, this.onSetLocationRequested});

  @override
  State<SearchUserScreen> createState() => SearchUserScreenState();
}

class SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Selected filters
  String? _selectedRole; // Driver, Owner, Mechanic
  int? _minAge;
  int? _maxAge;
  String? _selectedState;
  String? _selectedCity;

  // Age ranges for filters
  final List<Map<String, dynamic>> _ageRanges = [
    {'label': 'Under 25', 'min': 18, 'max': 24},
    {'label': '25 - 35', 'min': 25, 'max': 35},
    {'label': '36 - 45', 'min': 36, 'max': 45},
    {'label': 'Over 45', 'min': 46, 'max': 100},
  ];
  Map<String, dynamic>? _selectedAgeRange;

  List<SearchUser> _allUsers = [];
  List<SearchUser> _filteredUsers = [];

  bool _isLoading = true;
  bool _hasLocation = false;

  void refreshLocationAndUsers() {
    _checkLocationAndFetchUsers();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _checkLocationAndFetchUsers();
  }

  Future<void> _checkLocationAndFetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = prefs.getString('user_state');
      final city = prefs.getString('user_city');

      if (state == null || state.isEmpty || city == null || city.isEmpty) {
        setState(() {
          _hasLocation = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _hasLocation = true;
        _selectedState = state;
        _selectedCity = city;
      });

      await _fetchUsers();
    } catch (e) {
      // Handle error gently
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final queryParams = <String, String>{};
      if (_selectedState != null && _selectedState!.isNotEmpty) {
        queryParams['state'] = _selectedState!;
      }
      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        queryParams['city'] = _selectedCity!;
      }
      if (_selectedRole != null && _selectedRole!.isNotEmpty) {
        queryParams['role'] = _selectedRole!.toLowerCase();
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.searchUsers}').replace(
        queryParameters: queryParams,
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allUsers = data.map((json) => SearchUser.fromJson(json)).toList();
          _filteredUsers = List.from(_allUsers);
        });
        _applyFilters();
      }
    } catch (e) {
      // Handle error gently
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Search query check
        final matchesQuery = user.name.toLowerCase().contains(query) ||
            user.bio.toLowerCase().contains(query) ||
            user.city.toLowerCase().contains(query) ||
            user.state.toLowerCase().contains(query) ||
            user.role.toLowerCase().contains(query);

        // Role check
        final matchesRole = _selectedRole == null || user.role == _selectedRole;

        // Age check
        final matchesAge = (_minAge == null || user.age >= _minAge!) &&
            (_maxAge == null || user.age <= _maxAge!);

        // State check
        final matchesState = _selectedState == null ||
            user.state.trim().toLowerCase() == _selectedState!.trim().toLowerCase();

        // City check
        final matchesCity = _selectedCity == null ||
            user.city.trim().toLowerCase() == _selectedCity!.trim().toLowerCase();

        return matchesQuery && matchesRole && matchesAge && matchesState && matchesCity;
      }).toList();
    });
  }

  Future<void> _resetAllFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final state = prefs.getString('user_state');
    final city = prefs.getString('user_city');
    setState(() {
      _selectedRole = null;
      _selectedAgeRange = null;
      _minAge = null;
      _maxAge = null;
      _selectedState = state;
      _selectedCity = city;
    });
    setState(() => _isLoading = true);
    await _fetchUsers();
    setState(() => _isLoading = false);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final modalBgColor = isDark ? const Color(0xFF161616) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
            final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0);

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grabber
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEBF3FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF1565C0),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Filter Users',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _resetAllFilters();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.redAccent),
                        label: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Role Filter
                          Text(
                            'Select Role',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildRoleCard(
                                role: 'Driver',
                                icon: Icons.local_shipping_rounded,
                                isSelected: _selectedRole == 'Driver',
                                isDark: isDark,
                                onTap: () {
                                  setModalState(() {
                                    _selectedRole = _selectedRole == 'Driver' ? null : 'Driver';
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildRoleCard(
                                role: 'Owner',
                                icon: Icons.business_rounded,
                                isSelected: _selectedRole == 'Owner',
                                isDark: isDark,
                                onTap: () {
                                  setModalState(() {
                                    _selectedRole = _selectedRole == 'Owner' ? null : 'Owner';
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              _buildRoleCard(
                                role: 'Mechanic',
                                icon: Icons.build_rounded,
                                isSelected: _selectedRole == 'Mechanic',
                                isDark: isDark,
                                onTap: () {
                                  setModalState(() {
                                    _selectedRole = _selectedRole == 'Mechanic' ? null : 'Mechanic';
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 2. Age Range Filter
                          Text(
                            'Age Range',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _ageRanges.map((range) {
                              final isSelected = _selectedAgeRange == range;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      _selectedAgeRange = null;
                                      _minAge = null;
                                      _maxAge = null;
                                    } else {
                                      _selectedAgeRange = range;
                                      _minAge = range['min'];
                                      _maxAge = range['max'];
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1565C0)
                                        : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1565C0)
                                          : (isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB)),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    range['label'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF1A1A2E)),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // 3. State Filter
                          Text(
                            'State',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildModalDropdown(
                            isDark: isDark,
                            label: 'Select State',
                            value: _selectedState,
                            items: AppConstants.stateCityMap.keys.toList()..sort(),
                            onChanged: (val) {
                              setModalState(() {
                                _selectedState = val;
                                _selectedCity = null;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // 4. City Filter
                          Text(
                            'City',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildModalDropdown(
                            isDark: isDark,
                            label: _selectedState == null ? 'Select State First' : 'Select City',
                            value: _selectedCity,
                            items: _selectedState != null
                                ? (List<String>.from(AppConstants.stateCityMap[_selectedState]!)..sort())
                                : [],
                            onChanged: _selectedState == null
                                ? null
                                : (val) {
                                    setModalState(() {
                                      _selectedCity = val;
                                    });
                                  },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Apply Button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() => _isLoading = true);
                            await _fetchUsers();
                            setState(() => _isLoading = false);
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1565C0)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1565C0)
                  : (isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB)),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0)),
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF1A1A2E)),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDropdown({
    required bool isDark,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final inputBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        menuMaxHeight: 250,
        underline: const SizedBox.shrink(),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
        ),
        hint: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final cardBg = isDark ? const Color(0xFF0A0A1A) : Colors.white;
    final iconBoxBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEBF3FF);
    final isFiltersActive = _selectedRole != null ||
        _selectedAgeRange != null ||
        _selectedState != null ||
        _selectedCity != null;

    return AppBar(
      backgroundColor: cardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: iconBoxBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.person_search_rounded,
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
          child: GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isFiltersActive
                        ? const Color(0xFF1565C0).withValues(alpha: 0.15)
                        : iconBoxBg,
                    borderRadius: BorderRadius.circular(10),
                    border: isFiltersActive
                        ? Border.all(color: const Color(0xFF1565C0), width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                if (isFiltersActive)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFEBF3FF);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(isDark),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)),
        ),
      );
    }

    if (!_hasLocation) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(isDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Container(
              padding: const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEBF3FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 40,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Set Your Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F2C59),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please set your State and City in your Profile to start searching for drivers, mechanics, and owners.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: widget.onSetLocationRequested,
                      icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Set Location Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isFiltersActive = _selectedRole != null ||
        _selectedAgeRange != null ||
        _selectedState != null ||
        _selectedCity != null;

    final searchCardBg = isDark ? const Color(0xFF161616) : Colors.white;
    final searchBorder = isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Search Bar & Quick Role Selector
            Container(
              color: isDark ? const Color(0xFF0A0A1A) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search Input Container
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: searchCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: searchBorder, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF1565C0),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search drivers, owners, mechanics...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Role Filter Pills (All, Driver, Owner, Mechanic)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildQuickRolePill(
                          label: 'All Users',
                          icon: Icons.people_alt_rounded,
                          isSelected: _selectedRole == null,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedRole = null);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRolePill(
                          label: 'Drivers',
                          icon: Icons.local_shipping_rounded,
                          isSelected: _selectedRole == 'Driver',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedRole = _selectedRole == 'Driver' ? null : 'Driver');
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRolePill(
                          label: 'Owners',
                          icon: Icons.business_rounded,
                          isSelected: _selectedRole == 'Owner',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedRole = _selectedRole == 'Owner' ? null : 'Owner');
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickRolePill(
                          label: 'Mechanics',
                          icon: Icons.build_rounded,
                          isSelected: _selectedRole == 'Mechanic',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedRole = _selectedRole == 'Mechanic' ? null : 'Mechanic');
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Row & Results Count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_2_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_filteredUsers.length} Users Found',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF0F2C59),
                    ),
                  ),
                  const Spacer(),
                  if (isFiltersActive)
                    GestureDetector(
                      onTap: _resetAllFilters,
                      child: Text(
                        'Reset Filters',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Filter Chips Summary (Age, State, City)
            if (isFiltersActive && (_selectedAgeRange != null || _selectedState != null || _selectedCity != null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_selectedAgeRange != null)
                        _buildFilterChip('Age: ${_selectedAgeRange!['label']}', () {
                          setState(() {
                            _selectedAgeRange = null;
                            _minAge = null;
                            _maxAge = null;
                          });
                          _applyFilters();
                        }),
                      if (_selectedState != null)
                        _buildFilterChip(_selectedState!, () {
                          setState(() {
                            _selectedState = null;
                            _selectedCity = null;
                          });
                          _applyFilters();
                        }),
                      if (_selectedCity != null)
                        _buildFilterChip(_selectedCity!, () {
                          setState(() => _selectedCity = null);
                          _applyFilters();
                        }),
                    ],
                  ),
                ),
              ),

            // Users List
            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEBF3FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                size: 40,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Users Found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F2C59),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try broadening your search query or adjusting your role and location filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            if (isFiltersActive) ...[
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                onPressed: _resetAllFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Clear All Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1565C0),
                                  side: const BorderSide(color: Color(0xFF1565C0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF1565C0),
                      onRefresh: () async {
                        await _checkLocationAndFetchUsers();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 6, bottom: 24),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user, isDark);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRolePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1565C0)
              : (isDark ? const Color(0xFF161616) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1565C0)
                : (isDark ? const Color(0xFF262626) : const Color(0xFFDCE5F0)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF1A1A2E)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF1565C0),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactBottomSheet(SearchUser user) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
              const SizedBox(height: 22),
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
              const SizedBox(height: 18),
              Text(
                'Contact ${user.name}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F2C59),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.mobileNumber.isNotEmpty ? user.mobileNumber : 'Contact number unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
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
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF1C1C1C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final contactNumber = user.mobileNumber;
                        if (contactNumber.isNotEmpty) {
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
                        backgroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Call Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
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

  Widget _buildUserCard(SearchUser user, bool isDark) {
    final cardBgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0);

    // Role badge color configuration
    Color roleBadgeBg;
    Color roleTextColor;
    IconData roleIcon;
    switch (user.role) {
      case 'Driver':
        roleBadgeBg = const Color(0xFFE0F2FE);
        roleTextColor = const Color(0xFF0284C7);
        roleIcon = Icons.local_shipping_rounded;
        break;
      case 'Owner':
        roleBadgeBg = const Color(0xFFDCFCE7);
        roleTextColor = const Color(0xFF16A34A);
        roleIcon = Icons.business_rounded;
        break;
      case 'Mechanic':
        roleBadgeBg = const Color(0xFFFEF3C7);
        roleTextColor = const Color(0xFFD97706);
        roleIcon = Icons.build_rounded;
        break;
      default:
        roleBadgeBg = const Color(0xFFF1F5F9);
        roleTextColor = const Color(0xFF64748B);
        roleIcon = Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Avatar + User Info + Role Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Circular Deep Blue container
                CircleAvatar(
                  radius: 26,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  backgroundColor: const Color(0xFF0D47A1),
                  child: user.avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Name & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F2C59),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? roleBadgeBg.withValues(alpha: 0.2) : roleBadgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, size: 13, color: roleTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  user.role,
                                  style: TextStyle(
                                    color: roleTextColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Location with map pin
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF4A90D9) : const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.city.isNotEmpty && user.state.isNotEmpty
                                  ? '${user.city}, ${user.state}'
                                  : (user.city.isNotEmpty ? user.city : user.state),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details & Stats Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTagPill(
                  icon: Icons.cake_rounded,
                  text: '${user.age} yrs',
                  isDark: isDark,
                ),
                if (user.followersCount > 0)
                  _buildTagPill(
                    icon: Icons.group_rounded,
                    text: '${user.followersCount} followers',
                    isDark: isDark,
                  ),
              ],
            ),
          ),

          // Bio text
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                user.bio,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),

          // Action Buttons: "View Profile" + "Call Now" (matches home.jpg & profile.jpg)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Secondary Button: View Profile
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileDetailScreen(user: user),
                        ),
                      );
                    },
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 18,
                            color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Primary Button: Call Now
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showContactBottomSheet(user),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Call Now',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildTagPill({
    required IconData icon,
    required String text,
    required bool isDark,
    Color? iconColor,
    Color? textColor,
    Color? bgColor,
  }) {
    final defaultBg = isDark ? const Color(0xFF161616) : const Color(0xFFF1F5F9);
    final defaultText = isDark ? Colors.white60 : const Color(0xFF475569);
    final defaultIcon = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? defaultBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? defaultIcon),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? defaultText,
            ),
          ),
        ],
      ),
    );
  }
}
