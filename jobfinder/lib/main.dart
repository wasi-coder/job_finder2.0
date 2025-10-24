import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/job_type_screen.dart';
import 'screens/category_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/home_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(JobFinderApp());
}

class JobFinderApp extends StatelessWidget {
  const JobFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Finder',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: OnboardingScreen(),
      routes: {
        '/jobType': (context) => JobTypeScreen(),
        '/category': (context) => CategoryScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/verification': (context) => VerificationScreen(),
        '/home': (context) => HomeScreen(),
        '/jobs': (context) => JobsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
