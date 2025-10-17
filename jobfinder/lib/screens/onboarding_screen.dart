import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Login/Register buttons at top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text('Sign Up', style: TextStyle(color: Colors.black87)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  // Main content
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.work_outline, size: 80, color: Colors.white),
                  ),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatCard(label: '70K+', subtitle: 'Recruiters'),
                        SizedBox(width: 30),
                        _StatCard(label: '1K+', subtitle: 'Job Offer'),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Everything you need\nin one app',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Create your profile now and be visible to\nthe top recruiters in the world',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/jobType');
                    },
                    child: Text('Get Started', style: TextStyle(fontSize: 16, color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(200, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String subtitle;
  const _StatCard({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }
}