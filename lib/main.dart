import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart'; // Import the login page
import 'screens/home_screen.dart'; // Import the home screen
import 'pages/registration_page.dart'; // Import registration page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zbnnusmjpwvtsigvvlha.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpibm51c21qcHd2dHNpZ3Z2bGhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NTgwODQsImV4cCI6MjA2OTMzNDA4NH0.GWG-9PLnpYU2-foc8wI7fzPza746TGVgmMgab2geZvk',
  );
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
