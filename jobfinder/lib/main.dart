import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Import this
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/cv_builder_screen.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.black, // Dark theme base
      ),
      // START WITH SPLASH SCREEN
      home: SplashScreen(), 
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/jobs': (context) => JobsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/cv_builder': (context) => CVBuilderScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}