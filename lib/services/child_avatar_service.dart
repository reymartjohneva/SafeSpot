import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ChildAvatarService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload avatar to Supabase Storage
  static Future<String> uploadAvatar(File imageFile, String deviceId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final String fileName =
          '${deviceId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String filePath = '$currentUserId/$fileName';

      // Delete old avatar if exists
      await deleteOldAvatar(deviceId);

      // Upload new avatar
      await _supabase.storage
          .from('child_avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('child_avatars')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Delete old avatar
  static Future<void> deleteOldAvatar(String deviceId) async {
    if (!isAuthenticated) return;

    try {
      // Get existing avatar URL from database
      final response =
          await _supabase
              .from('child_info')
              .select('avatar_url')
              .eq('device_id', deviceId)
              .maybeSingle();

      if (response != null && response['avatar_url'] != null) {
        final String oldUrl = response['avatar_url'];

        // Extract file path from URL
        final Uri uri = Uri.parse(oldUrl);
        final String pathSegment = uri.pathSegments.last;
        final String filePath = '$currentUserId/$pathSegment';

        // Delete from storage
        await _supabase.storage.from('child_avatars').remove([filePath]);
      }
    } catch (e) {
      // Ignore errors when deleting old avatar
      print('Error deleting old avatar: $e');
    }
  }

  // Delete avatar
  static Future<void> deleteAvatar(String avatarUrl) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Extract file path from URL
      final Uri uri = Uri.parse(avatarUrl);
      final List<String> pathSegments = uri.pathSegments;

      // Get the path after 'child_avatars'
      final int bucketIndex = pathSegments.indexOf('child_avatars');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final String filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('child_avatars').remove([filePath]);
      }
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
    }
  }

  // Update avatar URL in database
  static Future<void> updateAvatarUrl(
    String deviceId,
    String? avatarUrl,
  ) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('child_info')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('device_id', deviceId);
    } catch (e) {
      throw Exception('Failed to update avatar URL: $e');
    }
  }
}
