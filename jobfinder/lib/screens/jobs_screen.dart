import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';
import '../widgets/bottom_nav_bar.dart';

class JobsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('All Jobs', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: 10,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.business, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Company ${index + 1}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                            Text('Job Position ${index + 1}', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Icon(Icons.bookmark_border, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Full-time • Remote', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      ),
    );
  }
}