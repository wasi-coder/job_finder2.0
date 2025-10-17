import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        // Try to get user data to verify token is valid
        final userData = await ApiService.getCurrentUser();
        setState(() {
          _isLoggedIn = true;
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Token invalid or expired
      await ApiService.clearToken();
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await ApiService.logout();
    setState(() {
      _isLoggedIn = false;
      _userData = null;
    });
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Profile', style: TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 100, color: Colors.white.withOpacity(0.5)),
                  SizedBox(height: 24),
                  Text(
                    'You need to login first',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Create an account or login to access your profile and start applying for jobs',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text('Login', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD4FF00),
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      side: BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(currentIndex: 4),
        ),
      );
    }

    // Logged in profile view
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Profile', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                '${_userData?['first_name'] ?? 'User'} ${_userData?['last_name'] ?? ''}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                _userData?['email'] ?? _userData?['phone'] ?? 'user@example.com',
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
              ),
              SizedBox(height: 32),
              _ProfileMenuItem(icon: Icons.person, title: 'Edit Profile', onTap: () {}),
              _ProfileMenuItem(icon: Icons.bookmark, title: 'Saved Jobs', onTap: () {}),
              _ProfileMenuItem(icon: Icons.work, title: 'Applied Jobs', onTap: () {}),
              _ProfileMenuItem(icon: Icons.settings, title: 'Settings', onTap: () {}),
              _ProfileMenuItem(icon: Icons.help, title: 'Help & Support', onTap: () {}),
              _ProfileMenuItem(icon: Icons.logout, title: 'Logout', onTap: _logout),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 4),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        onTap: onTap,
      ),
    );
  }
}