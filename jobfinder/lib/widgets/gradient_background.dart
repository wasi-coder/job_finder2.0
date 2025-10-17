import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7DC8E7), // Light blue
            Color(0xFFB8A4C9), // Purple-ish
            Color(0xFFE8C4C4), // Pink-ish
            Color(0xFFE8B896), // Peach/orange
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: child,
    );
  }
}