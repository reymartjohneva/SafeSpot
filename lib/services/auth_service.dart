import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Get auth state stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Register a new user with email and password
  static Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobile,
  }) async {
    try {
      // Register user with Supabase Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'mobile': mobile,
          'full_name': '$firstName $lastName',
        },
      );

      if (response.user != null) {
        // Optionally create a profile record in your database
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
        );

        return AuthResult(
          success: true,
          message: 'Account created successfully!',
          user: response.user,
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Registration failed. Please try again.',
        );
      }
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult(
          success: true,
          message: 'Login successful!',
          user: response.user,
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Login failed. Please check your credentials.',
        );
      }
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Sign out the current user
  static Future<AuthResult> signOut() async {
    try {
      await _supabase.auth.signOut();
      return AuthResult(success: true, message: 'Signed out successfully');
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to sign out. Please try again.',
      );
    }
  }

  /// Reset password via email
  static Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult(success: true, message: 'Password reset email sent!');
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to send reset email. Please try again.',
      );
    }
  }

  /// Update user password
  static Future<AuthResult> updatePassword({
    required String newPassword,
  }) async {
    try {
      final UserResponse response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        return AuthResult(
          success: true,
          message: 'Password updated successfully!',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Failed to update password.',
        );
      }
    } on AuthException catch (e) {
      return AuthResult(success: false, message: _getErrorMessage(e.message));
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred.',
      );
    }
  }

  /// Update user profile
  static Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? mobile,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (mobile != null) updateData['mobile'] = mobile;

      if (firstName != null && lastName != null) {
        updateData['full_name'] = '$firstName $lastName';
      }

      final UserResponse response = await _supabase.auth.updateUser(
        UserAttributes(data: updateData),
      );

      if (response.user != null) {
        // Also update the profiles table if it exists
        if (currentUser != null) {
          await _supabase
              .from('profiles')
              .update(updateData)
              .eq('id', currentUser!.id);
        }

        return AuthResult(
          success: true,
          message: 'Profile updated successfully!',
        );
      } else {
        return AuthResult(success: false, message: 'Failed to update profile.');
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update profile. Please try again.',
      );
    }
  }

  /// Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', currentUser!.id)
              .single();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Create user profile in database
  static Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String mobile,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'full_name': '$firstName $lastName',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      // Don't throw error here as the main auth was successful
    }
  }

  /// Convert Supabase error messages to user-friendly messages
  static String _getErrorMessage(String? error) {
    if (error == null) return 'An unknown error occurred';

    // Common Supabase error message mappings
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account';
    } else if (error.contains('User already registered')) {
      return 'An account with this email already exists';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address';
    } else if (error.contains('Signup is disabled')) {
      return 'Account registration is currently disabled';
    } else if (error.contains('Too many requests')) {
      return 'Too many attempts. Please try again later';
    }

    return error; // Return original error if no mapping found
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate mobile number (basic validation)
  static bool isValidMobile(String mobile) {
    // Remove any non-digit characters for validation
    String cleanedMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    return cleanedMobile.length >=
        10; // Adjust based on your country's requirements
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({required this.success, required this.message, this.user});
}

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  final String fullName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      mobile: json['mobile'],
      fullName: json['full_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'mobile': mobile,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
