import 'package:flutter/material.dart';
import 'package:truck_mate/features/main_navigation_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;
  String? _errorText;
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
    _phoneController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validateForm);
    _phoneController.dispose();
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

  void _validateForm() {
    final text = _phoneController.text.trim();
    setState(() {
      // Input verification
      if (text.isEmpty) {
        _errorText = null;
        _isButtonEnabled = false;
      } else if (text.length == 10 && RegExp(r'^[0-9]+$').hasMatch(text)) {
        _errorText = null;
        // Enabled only if a role is also selected
        _isButtonEnabled = _selectedRole != null;
      } else {
        _isButtonEnabled = false;
        if (text.length > 10) {
          _errorText = 'Mobile number cannot exceed 10 digits';
        } else if (!RegExp(r'^[0-9]*$').hasMatch(text)) {
          _errorText = 'Please enter numbers only';
        } else {
          _errorText = null;
        }
      }
    });
  }

  void _handleSignUp() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role to proceed.')),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() {
        _errorText = 'Enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Simulate Register Request
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Successfully registered as ${_selectedRole!.toUpperCase()}! Welcome to TruckMate.',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - kToolbarHeight,
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
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Create ',
                            style: TextStyle(color: Color(0xFF1C1C1C)),
                          ),
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
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Main Form Inputs & Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1C),
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
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
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

                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomPhoneField(
                      controller: _phoneController,
                      errorText: _errorText,
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
                        color: Colors.grey.shade600,
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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.03 : 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0095F6) : Colors.grey.shade300,
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
                    color: isSelected ? const Color(0xFF0095F6) : Colors.grey.shade600,
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
                  color: isSelected ? const Color(0xFF0095F6) : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? const Color(0xFF0095F6).withValues(alpha: 0.8) : Colors.grey.shade500,
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
