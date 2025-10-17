import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final setPasswordController = TextEditingController();

  bool _isLoading = false;

  void _signUp() async {
    if (_isLoading) return;

    // Validate inputs
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dobController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        setPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (passwordController.text != setPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = {
        'first_name': firstNameController.text,
        'last_name': lastNameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'dob': dobController.text,
        'password': passwordController.text,
      };

      final response = await ApiService.register(userData);

      // Navigate to verification screen with user_id and verification code
      Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'user_id': response['user_id'],
          'email': emailController.text,
          'verification_code': response['verification_code'],
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                SizedBox(height: 20),
                Text(
                  'Get Started Now',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Create an account or log in to explore about our app',
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    _TabButton(title: 'Sign Up', selected: true, onTap: () {}),
                    SizedBox(width: 12),
                    _TabButton(
                      title: 'Log In',
                      selected: false,
                      onTap: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _CustomTextField(
                        controller: firstNameController,
                        hintText: 'First Name',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _CustomTextField(
                        controller: lastNameController,
                        hintText: 'Last Name',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: dobController,
                  hintText: 'Birth of date',
                ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: phoneController,
                  hintText: 'Phone',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: setPasswordController,
                  hintText: 'Set Password',
                  obscureText: true,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                          ),
                        )
                      : Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: Color(0xFFD4FF00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Color(0xFFD4FF00) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.black87 : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;

  const _CustomTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          suffixIcon: obscureText ? Icon(Icons.visibility_off, color: Colors.white.withOpacity(0.5)) : null,
        ),
      ),
    );
  }
}