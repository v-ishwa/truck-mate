import 'package:flutter/material.dart';
import 'package:truck_mate/features/main_navigation_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhoneNumber);
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    final text = _phoneController.text.trim();
    setState(() {
      // Basic validation: 10-digit Indian phone number
      if (text.isEmpty) {
        _errorText = null;
        _isButtonEnabled = false;
      } else if (text.length == 10 && RegExp(r'^[0-9]+$').hasMatch(text)) {
        _errorText = null;
        _isButtonEnabled = true;
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

  void _handleLogin() {
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

    // Simulate API request and navigate/show feedback
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('OTP verified successfully! Welcome back.'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight:
                  size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header / Branding
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Elegant Logo Badge (Matching Profile avatar / Truck Theme)
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0095F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Title
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Truck',
                            style: TextStyle(color: Color(0xFF1C1C1C)),
                          ),
                          TextSpan(
                            text: 'Mate',
                            style: TextStyle(color: Color(0xFF0095F6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Safe & On-time Delivery 🚚',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Pan India Services',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                // Main Form Inputs
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your mobile number to receive a one-time verification code.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomPhoneField(
                        controller: _phoneController,
                        errorText: _errorText,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Get OTP',
                        onPressed: _isButtonEnabled ? _handleLogin : null,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                // Footer Section
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0095F6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'By continuing, you agree to our',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E8E)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0095F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          '  &  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E8E),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0095F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
