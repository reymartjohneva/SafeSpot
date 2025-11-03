import 'package:flutter/material.dart';
import 'registration_page.dart';
import 'package:safe_spot/services/auth_service.dart';
import 'package:safe_spot/pages/widgets/login_form.dart';
import 'package:safe_spot/pages/widgets/login_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late AnimationController _gridController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _gridController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    _backgroundController.repeat(reverse: true);
    _gridController.repeat();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    print('Login button pressed!');

    String email = _emailController.text.trim();
    String password = _passwordController.text;

    print('Email: $email');
    print('Password length: ${password.length}');

    if (email.isEmpty || password.isEmpty) {
      print('Empty fields validation failed');
      _showEnhancedSnackBar('Please fill in all fields', const Color(0xFFf44336));
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      print('Email validation failed');
      _showEnhancedSnackBar('Please enter a valid email address', const Color(0xFFf44336));
      return;
    }

    if (!AuthService.isValidPassword(password)) {
      print('Password length validation failed');
      _showEnhancedSnackBar('Password must be at least 6 characters', const Color(0xFFf44336));
      return;
    }

    print('All validations passed, starting login process');

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResult result = await AuthService.signIn(
        email: email,
        password: password,
      );

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        print('Login successful, navigating to MainScreen');
        _showEnhancedSnackBar(result.message, const Color(0xFF4CAF50));

        // Add success animation before navigation
        await _scaleController.reverse();
        await _fadeController.reverse();
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        print('Login failed: ${result.message}');
        _showEnhancedSnackBar(result.message, const Color(0xFFf44336));
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      setState(() {
        _isLoading = false;
      });
      _showEnhancedSnackBar(
        'An unexpected error occurred. Please try again.',
        const Color(0xFFf44336),
      );
    }
  }

  void _showEnhancedSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == const Color(0xFF4CAF50)
                  ? Icons.check_circle 
                  : backgroundColor == const Color(0xFFFF9800)
                      ? Icons.warning
                      : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegistrationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundAnimation, _gridController]),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0a0a0a), // Pure black background
            ),
            child: Stack(
              children: [
                // Radial gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -0.5),
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.6, 0.8),
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFF9800).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                
                // Animated grid overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(
                      animation: _gridController,
                      color: const Color(0xFFFF6B35).withOpacity(0.03),
                    ),
                  ),
                ),
                
                // Floating shapes
                Positioned(
                  top: 50,
                  left: 30,
                  child: AnimatedBuilder(
                    animation: _backgroundAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          30 * _backgroundAnimation.value,
                          -30 * _backgroundAnimation.value,
                        ),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF6B35).withOpacity(0.05),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 100,
                  right: 50,
                  child: AnimatedBuilder(
                    animation: _backgroundAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          -20 * _backgroundAnimation.value,
                          20 * _backgroundAnimation.value,
                        ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF9800).withOpacity(0.05),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Header
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: const LoginHeader(),
                              ),
                            ),
                          ),
                          
                          // Animated Form
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: LoginForm(
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isLoading: _isLoading,
                                  onLogin: _handleLogin,
                                  onForgotPassword: () {}, // Not used anymore, dialog handles it
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Animated Sign Up Row
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isLoading ? null : _navigateToRegistration,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: const Color(0xFFFF6B35),
                                        ),
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for animated grid
class GridPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  GridPainter({required this.animation, required this.color})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 50.0;
    final offset = animation.value * spacing;

    // Draw vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => true;
}