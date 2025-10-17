import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEmail = false;
  bool rememberMe = false;
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  void _login() async {
    if (_isLoading) return;

    // Validate inputs
    final identifier = isEmail ? emailController.text : phoneController.text;
    final password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credentials = {
        'email': isEmail ? identifier : null,
        'phone': !isEmail ? identifier : null,
        'password': password,
      };

      final response = await ApiService.login(credentials);

      // Check if user needs verification
      if (response['status'] == 'unverified') {
        // User not verified, navigate to verification
        final detail = response['detail'];
        Navigator.pushNamed(
          context,
          '/verification',
          arguments: {
            'user_id': detail['user_id'],
            'email': isEmail ? identifier : null,
            'phone': !isEmail ? identifier : null,
            'verification_code': detail['verification_code'],
          },
        );
      } else {
        // User is verified, navigate to home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
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
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Login to access your account',
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    _TabButton(
                      title: 'Phone Number',
                      selected: !isEmail,
                      onTap: () => setState(() => isEmail = false),
                    ),
                    SizedBox(width: 12),
                    _TabButton(
                      title: 'Email',
                      selected: isEmail,
                      onTap: () => setState(() => isEmail = true),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                if (!isEmail)
                  _CustomTextField(
                    controller: phoneController,
                    hintText: '+88017********',
                    keyboardType: TextInputType.phone,
                  )
                else
                  _CustomTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                SizedBox(height: 16),
                _CustomTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (val) => setState(() => rememberMe = val!),
                      fillColor: MaterialStateProperty.all(Colors.white.withOpacity(0.3)),
                      checkColor: Color(0xFF00D9A5),
                    ),
                    Text('Remember me', style: TextStyle(color: Colors.white)),
                    Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text('Forget password?', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                          ),
                        )
                      : Text('Log In', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 56),
                    backgroundColor: Color(0xFFD4FF00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Or Sign In With', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(icon: Icons.g_mobiledata, onTap: () {}),
                    SizedBox(width: 16),
                    _SocialButton(icon: Icons.facebook, onTap: () {}),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 15, color: Colors.white),
                        children: [
                          TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00D9A5)),
                          ),
                        ],
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}