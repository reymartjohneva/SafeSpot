import 'package:flutter/material.dart';
import 'registration_page.dart';
import '../services/auth_service.dart';
import 'package:safe_spot/pages/widgets/login_form.dart';
import 'package:safe_spot/pages/widgets/login_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      _showSnackBar('Please fill in all fields', Colors.red);
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      print('Email validation failed');
      _showSnackBar('Please enter a valid email address', Colors.red);
      return;
    }

    if (!AuthService.isValidPassword(password)) {
      print('Password length validation failed');
      _showSnackBar('Password must be at least 6 characters', Colors.red);
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
        _showSnackBar(result.message, Colors.green);

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        print('Login failed: ${result.message}');
        _showSnackBar(result.message, Colors.red);
      }
    } catch (e) {
      print('Unexpected error during login: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        Colors.red,
      );
    }
  }

  void _handleForgotPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address first', Colors.orange);
      return;
    }

    if (!AuthService.isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResult result = await AuthService.resetPassword(email: email);

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        _showSnackBar(result.message, Colors.green);
      } else {
        _showSnackBar(result.message, Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(
        'Failed to send reset email. Please try again.',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg2_icon.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoginHeader(),
                    LoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: _isLoading,
                      onLogin: _handleLogin,
                      onForgotPassword: _handleForgotPassword,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToRegistration,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade300,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}