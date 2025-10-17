import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Notifications', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: 8,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF00D9A5).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Job Alert', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('A new job matching your profile is available', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        SizedBox(height: 4),
                        Text('2 hours ago', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 2),
      ),
    );
  }
}