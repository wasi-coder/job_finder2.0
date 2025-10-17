import 'package:flutter/material.dart';
import '../widgets/gradient_background.dart';

class CategoryScreen extends StatelessWidget {
  final categories = [
    {'icon': Icons.design_services, 'title': 'Design', 'jobs': '1200+'},
    {'icon': Icons.bar_chart, 'title': 'Business', 'jobs': '1200+'},
    {'icon': Icons.medical_services, 'title': 'Medical', 'jobs': '1200+'},
    {'icon': Icons.movie, 'title': 'Media', 'jobs': '1200+'},
    {'icon': Icons.school, 'title': 'Education', 'jobs': '1200+'},
    {'icon': Icons.restaurant, 'title': 'Restaurant', 'jobs': '1200+'},
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Category', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.tune, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/home'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat['icon'] as IconData, size: 48, color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        cat['title'] as String,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${cat['jobs']} Jobs',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}