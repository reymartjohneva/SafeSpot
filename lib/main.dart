import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'screens/home_screen.dart';
import 'pages/registration_page.dart';
import 'services/auth_service.dart';
import 'services/friend_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zbnnusmjpwvtsigvvlha.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpibm51c21qcHd2dHNpZ3Z2bGhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NTgwODQsImV4cCI6MjA2OTMzNDA4NH0.GWG-9PLnpYU2-foc8wI7fzPza746TGVgmMgab2geZvk',
  );
  await FriendService.init();

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
      // Use a custom widget that checks authentication state
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const AuthenticatedRoute(child: MainScreen()),
        '/register': (context) => const RegistrationPage(),
      },
    );
  }
}

// Wrapper to check authentication state on app start
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading screen while checking auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is authenticated
        if (AuthService.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// Protected route wrapper
class AuthenticatedRoute extends StatelessWidget {
  final Widget child;

  const AuthenticatedRoute({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (AuthService.isAuthenticated) {
      return child;
    } else {
      // If not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
