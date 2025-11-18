import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'screens/device_screen.dart';
import 'pages/registration_page.dart';
import 'services/auth_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/geofence_monitor_service.dart';
import 'screens/profile_screen.dart';
import 'widgets/nav_bar.dart';
import 'screens/emergency_hotlines_screen.dart';
import 'screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zbnnusmjpwvtsigvvlha.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpibm51c21qcHd2dHNpZ3Z2bGhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NTgwODQsImV4cCI6MjA2OTMzNDA4NH0.GWG-9PLnpYU2-foc8wI7fzPza746TGVgmMgab2geZvk',
  );

  // Start CONTINUOUS realtime sync from Firebase to Supabase (every 2 seconds)
  FirebaseSyncService.startRealtimeSync();

  // Also start periodic sync as fallback (every 5 minutes)
  FirebaseSyncService.startAutoSync(interval: const Duration(minutes: 5));
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
      ),
      home: const SplashScreen(), // Changed to custom splash
      routes: {
        '/login': (context) => const LoginPage(),
        '/home':
            (context) =>
                const AuthenticatedRoute(child: MainNavigationScreen()),
        '/register': (context) => const RegistrationPage(),
      },
    );
  }
}

// Custom Splash Screen with animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate to auth wrapper after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9800), // Orange
              Color(0xFFFF6B00), // Deep Orange
              Color(0xFFFF8A00), // Orange
              Color(0xFF4CAF50), // Green
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated circles in background
            Positioned(
              top: -50,
              left: -50,
              child: _buildFloatingCircle(200, 0),
            ),
            Positioned(
              bottom: 100,
              right: -80,
              child: _buildFloatingCircle(250, 2),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: -30,
              child: _buildFloatingCircle(150, 4),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLogoContainer(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'SafeSpot',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Your Safety Companion',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircle(double size, int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(seconds: 3 + delay),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 0),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: ClipOval(
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset('assets/app1_icon.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ),
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
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SafeSpot',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (AuthService.isAuthenticated) {
          return const MainNavigationScreen();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}

// Main navigation screen with modern design
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  final List<Widget> _screens = [
    const DeviceScreen(),
    const EmergencyHotlinesScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeGeofenceMonitoring();
  }

  Future<void> _initializeGeofenceMonitoring() async {
    try {
      await GeofenceMonitorService.initialize();
      print('✅ Geofence monitoring started');
    } catch (e) {
      print('❌ Failed to start geofence monitoring: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    GeofenceMonitorService.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );

      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: ModernNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
