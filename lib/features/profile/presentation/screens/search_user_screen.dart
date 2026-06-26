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
  });

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

    return SearchUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      role: mappedRole,
      age: calculateAge(json['dob']),
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      avatarUrl: avatarUrl,
      bio: 'Ready for loads and jobs.',
      mobileNumber: json['mobileNumber'] as String? ?? '',
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
            user.bio.toLowerCase().contains(query);

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
            final modalBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grabber
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _resetAllFilters();
                        },
                        child: const Text(
                          'Reset All',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          
                          // 1. Role Filter
                          Text(
                            'User Role',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Driver', 'Owner', 'Mechanic'].map((role) {
                              final isSelected = _selectedRole == role;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(role),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0095F6),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  onSelected: (val) {
                                    setModalState(() {
                                      _selectedRole = val ? role : null;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 20),

                          // 2. Age Filter
                          Text(
                            'Age Range',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _ageRanges.map((range) {
                              final isSelected = _selectedAgeRange == range;
                              return ChoiceChip(
                                label: Text(range['label']),
                                selected: isSelected,
                                selectedColor: const Color(0xFF0095F6),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                onSelected: (val) {
                                  setModalState(() {
                                    if (val) {
                                      _selectedAgeRange = range;
                                      _minAge = range['min'];
                                      _maxAge = range['max'];
                                    } else {
                                      _selectedAgeRange = null;
                                      _minAge = null;
                                      _maxAge = null;
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // 3. State Filter
                          Text(
                            'State',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
                                _selectedCity = null; // Clear selected city
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // 4. City Filter
                          Text(
                            'City',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  
                  // Apply Button
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            fontWeight: FontWeight.bold,
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

  Widget _buildModalDropdown({
    required bool isDark,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final inputBgColor = isDark ? const Color(0xFF161616) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        menuMaxHeight: 250,
        underline: const SizedBox.shrink(),
        hint: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        style: TextStyle(color: textColor, fontSize: 14),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0095F6)),
        ),
      );
    }

    if (!_hasLocation) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          title: Text(
            'Search Fleet & Users',
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1C1C1C), fontSize: 18),
          ),
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_rounded, size: 64, color: isDark ? Colors.white54 : Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Location Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1C1C1C)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please set your State and City in your Profile to start searching for drivers, mechanics, and loads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onSetLocationRequested,
                  icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Set Location Now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0095F6),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final isFiltersActive = _selectedRole != null ||
        _selectedAgeRange != null ||
        _selectedState != null ||
        _selectedCity != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Find Users'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161616) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white30 : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search by name or bio...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.grey,
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
                                color: isDark ? Colors.white30 : Colors.grey,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: isFiltersActive
                                ? const Color(0xFF0095F6).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF161616) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(12),
                            border: isFiltersActive
                                ? Border.all(color: const Color(0xFF0095F6), width: 1.5)
                                : null,
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: isFiltersActive
                                ? const Color(0xFF0095F6)
                                : (isDark ? Colors.white70 : Colors.grey.shade700),
                            size: 22,
                          ),
                        ),
                        if (isFiltersActive)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              height: 14,
                              width: 14,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters summary list
            if (isFiltersActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_selectedRole != null)
                        _buildFilterChip(_selectedRole!, () {
                          setState(() => _selectedRole = null);
                          _applyFilters();
                        }),
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

            // Active list count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    '${_filteredUsers.length} Users Found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Users list
            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Users Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try broadening your search or filters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user, isDark);
                      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0095F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0095F6).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0095F6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF0095F6),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(SearchUser user, bool isDark) {
    final cardBgColor = isDark ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262626) : Colors.grey.shade200;
    
    // Role color mappings
    Color roleBadgeColor;
    Color roleTextColor;
    switch (user.role) {
      case 'Driver':
        roleBadgeColor = Colors.blue.withValues(alpha: 0.1);
        roleTextColor = Colors.blue;
        break;
      case 'Owner':
        roleBadgeColor = Colors.green.withValues(alpha: 0.1);
        roleTextColor = Colors.green;
        break;
      case 'Mechanic':
        roleBadgeColor = Colors.orange.withValues(alpha: 0.1);
        roleTextColor = Colors.orange;
        break;
      default:
        roleBadgeColor = Colors.grey.withValues(alpha: 0.1);
        roleTextColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileDetailScreen(user: user),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? NetworkImage(user.avatarUrl)
                      : null,
                  backgroundColor: const Color(0xFF0D47A1),
                  child: user.avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User Details
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                              ),
                            ),
                          ),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleBadgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.role,
                              style: TextStyle(
                                color: roleTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${user.age} • ${user.city}, ${user.state}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bio
            Text(
              user.bio,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Contact Button
            GestureDetector(
              onTap: () async {
                final mobile = user.mobileNumber;
                final messenger = ScaffoldMessenger.of(context);
                if (mobile.isNotEmpty) {
                  final Uri launchUri = Uri(
                    scheme: 'tel',
                    path: mobile,
                  );
                  try {
                    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Could not launch phone dialer for $mobile'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Phone number is unavailable'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? const Color(0xFF262626) : Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
