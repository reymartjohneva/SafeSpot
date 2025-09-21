import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

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

  /// Upload profile picture and update user profile
  /// Upload profile picture and update user profile
  static Future<AuthResult> uploadProfilePicture({
    required File imageFile,
    String? fileName,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'User not authenticated');
      }

      final userId = currentUser!.id;
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadFileName = fileName ?? '$timestamp.$fileExt';

      print('Uploading profile picture: $uploadFileName');
      print('File size: ${await imageFile.length()} bytes');

      // Validate file size (6MB limit for standard uploads)
      final fileSize = await imageFile.length();
      if (fileSize > 6 * 1024 * 1024) {
        return AuthResult(
          success: false,
          message: 'File too large. Please select an image under 6MB.',
        );
      }

      // Validate file extension
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExt)) {
        return AuthResult(
          success: false,
          message: 'Invalid file type. Please select a valid image file.',
        );
      }

      // Delete old profile picture if it exists
      await _deleteOldProfilePicture(userId);

      // Upload new image to Supabase Storage
      final String filePath = '$userId/$uploadFileName';

      // Read file as bytes for better compatibility
      final Uint8List fileBytes = await imageFile.readAsBytes();

      final String uploadPath = await _supabase.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // This will overwrite existing files
            ),
          );

      print('File uploaded to path: $uploadPath');

      // Small delay to ensure file is fully uploaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Get public URL for the uploaded image
      final String imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      print('Generated public URL: $imageUrl');

      // Verify the file was uploaded by trying to access it
      try {
        final response = await _supabase.storage
            .from('avatars')
            .list(path: userId);
        print(
          'Files in user directory: ${response.map((f) => f.name).toList()}',
        );
      } catch (e) {
        print('Error listing files: $e');
      }

      // Try to update profile in database first
      try {
        await _supabase.from('profiles').upsert({
          'id': userId,
          'avatar_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('Profile table updated successfully');
      } catch (e) {
        print('Error updating profiles table (might not exist): $e');
        // Continue anyway - we'll update user metadata
      }

      // Update user metadata (this is crucial!)
      final Map<String, dynamic> updatedMetadata = {
        ...?currentUser?.userMetadata,
        'avatar_url': imageUrl,
      };

      final userUpdateResponse = await _supabase.auth.updateUser(
        UserAttributes(data: updatedMetadata),
      );

      print('User metadata updated: ${userUpdateResponse.user?.userMetadata}');

      if (userUpdateResponse.user != null) {
        return AuthResult(
          success: true,
          message: 'Profile picture updated successfully!',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Failed to update user metadata',
        );
      }
    } catch (e) {
      print('Error in uploadProfilePicture: $e');
      print('Error type: ${e.runtimeType}');

      String errorMessage = 'Failed to upload profile picture';
      if (e.toString().contains('400')) {
        errorMessage =
            'Upload failed. Please check your storage bucket configuration.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Permission denied. Please check storage policies.';
      } else if (e.toString().contains('413')) {
        errorMessage = 'File too large. Please select a smaller image.';
      }

      return AuthResult(
        success: false,
        message: '$errorMessage: ${e.toString()}',
      );
    }
  }

  /// Enhanced delete old profile picture method
  static Future<void> _deleteOldProfilePicture(String userId) async {
    try {
      // List all files in the user's directory
      final List<FileObject> files = await _supabase.storage
          .from('avatars')
          .list(path: userId);

      // Delete each file
      final List<String> filesToDelete =
          files.map((file) => '$userId/${file.name}').toList();

      if (filesToDelete.isNotEmpty) {
        await _supabase.storage.from('avatars').remove(filesToDelete);
        print('Deleted ${filesToDelete.length} old profile pictures');
      }
    } catch (e) {
      print('Error deleting old profile pictures: $e');
      // Don't throw error - this is cleanup, not critical
    }
  }

  /// Upload profile picture from bytes (for web)
  static Future<AuthResult> uploadProfilePictureFromBytes({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'User not authenticated');
      }

      final userId = currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadFileName = '${userId}_${timestamp}_$fileName';

      // Delete old profile picture if it exists
      await _deleteOldProfilePicture(userId);

      // Upload new image to Supabase Storage

      // Get public URL for the uploaded image
      final String imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl('$userId/$uploadFileName');

      // Update profile in database
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Update user metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      return AuthResult(
        success: true,
        message: 'Profile picture updated successfully!',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to upload profile picture: ${e.toString()}',
      );
    }
  }

  /// Delete profile picture
  static Future<AuthResult> deleteProfilePicture() async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'User not authenticated');
      }

      final userId = currentUser!.id;

      // Delete from storage
      await _deleteOldProfilePicture(userId);

      // Try to update profile in database
      try {
        await _supabase
            .from('profiles')
            .update({
              'avatar_url': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
        print('Profile table updated - avatar removed');
      } catch (e) {
        print('Error updating profiles table: $e');
      }

      // Update user metadata (remove avatar_url)
      Map<String, dynamic> updatedMetadata = Map.from(
        currentUser?.userMetadata ?? {},
      );
      updatedMetadata['avatar_url'] = null;

      await _supabase.auth.updateUser(UserAttributes(data: updatedMetadata));

      print('User metadata updated - avatar removed');

      return AuthResult(
        success: true,
        message: 'Profile picture deleted successfully!',
      );
    } catch (e) {
      print('Error in deleteProfilePicture: $e');
      return AuthResult(
        success: false,
        message: 'Failed to delete profile picture: ${e.toString()}',
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
              .update({
                ...updateData,
                'updated_at': DateTime.now().toIso8601String(),
              })
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
              .maybeSingle(); // Use maybeSingle() instead of single()

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Add this method to your AuthService class to verify storage setup
  static Future<AuthResult> verifyStorageSetup() async {
    try {
      if (currentUser == null) {
        return AuthResult(success: false, message: 'User not authenticated');
      }

      print('Verifying storage setup...');

      // Try to list buckets
      final buckets = await _supabase.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');

      // Check if avatars bucket exists
      final avatarBucket = buckets.firstWhere(
        (bucket) => bucket.name == 'avatars',
        orElse: () => throw Exception('avatars bucket not found'),
      );

      print(
        'Avatar bucket found: ${avatarBucket.name} (Public: ${avatarBucket.public})',
      );

      // Try to create a test file
      final testData = Uint8List.fromList([1, 2, 3, 4]);
      final testPath = '${currentUser!.id}/test.txt';

      await _supabase.storage.from('avatars').uploadBinary(testPath, testData);

      print('Test upload successful');

      // Try to get public URL
      final testUrl = _supabase.storage.from('avatars').getPublicUrl(testPath);

      print('Test URL generated: $testUrl');

      // Clean up test file
      await _supabase.storage.from('avatars').remove([testPath]);

      print('Storage setup verification completed successfully');

      return AuthResult(success: true, message: 'Storage setup is correct');
    } catch (e) {
      print('Storage setup verification failed: $e');

      String message = 'Storage setup issue: ';
      if (e.toString().contains('avatars bucket not found')) {
        message +=
            'Please create an "avatars" bucket in your Supabase dashboard.';
      } else if (e.toString().contains('403')) {
        message += 'Permission denied. Please check your storage policies.';
      } else {
        message += e.toString();
      }

      return AuthResult(success: false, message: message);
    }
  }

  // Add this method to test a specific avatar URL
  static Future<bool> testAvatarUrl(String url) async {
    try {
      // Try to download just the headers to test if URL is accessible
      final uri = Uri.parse(url);
      final response = await HttpClient().headUrl(uri);
      final httpResponse = await response.close();

      print('Avatar URL test - Status: ${httpResponse.statusCode}');
      print('Avatar URL test - Headers: ${httpResponse.headers}');

      return httpResponse.statusCode == 200;
    } catch (e) {
      print('Avatar URL test failed: $e');
      return false;
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
        'avatar_url': null, // Add avatar_url field
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