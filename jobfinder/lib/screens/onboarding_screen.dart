import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Find Jobs Easily",
      "subtitle": "Search through thousands of jobs in IT, Design, Marketing, and more.",
      "icon": "search",
    },
    {
      "title": "Apply with One CV",
      "subtitle": "Create your profile once and apply to multiple companies instantly.",
      "icon": "file",
    },
    {
      "title": "Chat with Employers",
      "subtitle": "Direct messaging with hirers to fast-track your interview process.",
      "icon": "chat",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIcon(index),
                            size: 100,
                            color: Color(0xFFD4FF00),
                          ),
                          SizedBox(height: 40),
                          Text(
                            _pages[index]['title']!,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _pages[index]['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Color(0xFFD4FF00) : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFD4FF00),
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Login", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                      child: Text("Create an Account", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0: return Icons.search;
      case 1: return Icons.description_outlined;
      case 2: return Icons.chat_bubble_outline;
      default: return Icons.circle;
    }
  }
}