import 'package:flutter/material.dart';
import 'package:truck_mate/features/main_navigation_screen.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDob;

  String? _selectedRole;
  bool _isLoading = false;
  String? _nameErrorText;
  String? _errorText;
  String? _dobErrorText;
  bool _isButtonEnabled = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'owner',
      'label': 'Owner',
      'icon': Icons.business_center_rounded,
      'description': 'Register fleet/trucks',
    },
    {
      'id': 'driver',
      'label': 'Driver',
      'icon': Icons.local_shipping_rounded,
      'description': 'Find loads & drive',
    },
    {
      'id': 'mechanic',
      'label': 'Mechanic',
      'icon': Icons.handyman_rounded,
      'description': 'Repair & service requests',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _nameController.dispose();
    _phoneController.removeListener(_validateForm);
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _selectRole(String roleId) {
    setState(() {
      if (_selectedRole == roleId) {
        _selectedRole = null; // Toggle off if clicked again
      } else {
        _selectedRole = roleId;
      }
      _validateForm();
    });
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime initialDate = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );
    final DateTime firstDate = DateTime(today.year - 100);
    final DateTime lastDate = today;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0095F6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1C1C),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0095F6),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        final age = _calculateAge(picked);
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year} (Age: $age)";
      });
      _validateForm();
    }
  }

  void _validateForm() {
    final nameText = _nameController.text.trim();
    final phoneText = _phoneController.text.trim();

    setState(() {
      // Name validation
      if (nameText.isEmpty) {
        _nameErrorText = null;
      } else if (nameText.length < 2) {
        _nameErrorText = 'Name must be at least 2 characters';
      } else {
        _nameErrorText = null;
      }

      // Phone validation
      if (phoneText.isEmpty) {
        _errorText = null;
      } else if (phoneText.length == 10 &&
          RegExp(r'^[0-9]+$').hasMatch(phoneText)) {
        _errorText = null;
      } else {
        if (phoneText.length > 10) {
          _errorText = 'Mobile number cannot exceed 10 digits';
        } else if (!RegExp(r'^[0-9]*$').hasMatch(phoneText)) {
          _errorText = 'Please enter numbers only';
        } else {
          _errorText = null;
        }
      }

      // Age validation
      if (_selectedDob != null) {
        final age = _calculateAge(_selectedDob!);
        if (age < 18) {
          _dobErrorText = 'You must be at least 18 years old';
        } else {
          _dobErrorText = null;
        }
      } else {
        _dobErrorText = null;
      }

      final isNameValid = nameText.length >= 2;
      final isPhoneValid =
          phoneText.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phoneText);
      final isDobValid =
          _selectedDob != null && _calculateAge(_selectedDob!) >= 18;

      _isButtonEnabled =
          _selectedRole != null && isNameValid && isPhoneValid && isDobValid;
    });
  }

  Future<void> _handleSignUp() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role to proceed.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() {
        _nameErrorText = 'Enter a valid name';
      });
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() {
        _errorText = 'Enter a valid 10-digit mobile number';
      });
      return;
    }

    if (_selectedDob == null) {
      setState(() {
        _dobErrorText = 'Please select your date of birth';
      });
      return;
    }

    final age = _calculateAge(_selectedDob!);
    if (age < 18) {
      setState(() {
        _dobErrorText = 'You must be at least 18 years old';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _nameErrorText = null;
      _errorText = null;
      _dobErrorText = null;
    });

    final response = await _authRepository.register(
      name: name,
      mobileNumber: phone,
      dob: _selectedDob!,
      role: _selectedRole!,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  response.message.isNotEmpty
                      ? response.message
                      : 'Successfully registered $name as ${_selectedRole!.toUpperCase()}! Welcome to TruckMate.',
                ),
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

      // Navigate to Main Navigation Screen and clear the history
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      // Show failure feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(response.message),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1C1C1C),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding / Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1C1C1C),
                        ),
                        children: const [
                          TextSpan(text: 'Create '),
                          TextSpan(
                            text: 'Account',
                            style: TextStyle(color: Color(0xFF0095F6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join TruckMate and select your service category.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Main Form Inputs & Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role Cards Row
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _roles.map((role) {
                          final isSelected = _selectedRole == role['id'];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: _RoleCard(
                                label: role['label'],
                                icon: role['icon'],
                                description: role['description'],
                                isSelected: isSelected,
                                onTap: () => _selectRole(role['id']),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Enter Full Name',
                      prefixIcon: Icons.person_outline_rounded,
                      errorText: _nameErrorText,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomPhoneField(
                      controller: _phoneController,
                      errorText: _errorText,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _dobController,
                      hintText: 'Select Date of Birth',
                      prefixIcon: Icons.calendar_month_outlined,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      errorText: _dobErrorText,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => _selectDate(context),
                      ),
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Sign Up',
                      onPressed: _isButtonEnabled ? _handleSignUp : null,
                      isLoading: _isLoading,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Footer section (Navigate back to login)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0095F6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Inner Widget for Role Card with selection micro-interactions
class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.03 : 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? const Color(0xFF0095F6).withValues(alpha: 0.2)
                      : const Color(0xFFE3F2FD))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0095F6)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0095F6).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Icon color
              AnimatedTheme(
                data: ThemeData(
                  iconTheme: IconThemeData(
                    color: isSelected
                        ? const Color(0xFF0095F6)
                        : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                ),
                child: Icon(icon, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0095F6)
                      : (isDark ? Colors.white : Colors.grey.shade800),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? const Color(0xFF0095F6).withValues(alpha: 0.8)
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
