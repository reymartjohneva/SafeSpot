import 'package:flutter/material.dart';
import 'pages/login_page.dart'; // Import the login page
import 'screens/home_screen.dart'; // Import the home screen
import 'pages/registration_page.dart'; // Import registration page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Set up named routes
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainScreen(),
        '/register': (context) => const RegistrationPage(),
      },
      // Fallback to login page
      home: const LoginPage(),
    );
  }
}