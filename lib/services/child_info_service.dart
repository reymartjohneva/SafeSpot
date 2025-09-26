import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safe_spot/models/child_info.dart';

class ChildInfoService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get child info for a specific device
  static Future<ChildInfo?> getChildInfo(String deviceId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('child_info')
          .select('*')
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response != null) {
        return ChildInfo.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch child info: $e');
    }
  }

  // Get all child info for user's devices
  static Future<List<ChildInfo>> getAllChildrenInfo() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // First get user's devices
      final devicesResponse = await _supabase
          .from('devices')
          .select('device_id')
          .eq('user_id', currentUserId!);

      final deviceIds = (devicesResponse as List)
          .map((device) => device['device_id'] as String)
          .toList();

      if (deviceIds.isEmpty) return [];

      // Then get child info for those devices
      final response = await _supabase
          .from('child_info')
          .select('*')
          .inFilter('device_id', deviceIds)  // Use inFilter instead of in
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ChildInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch children info: $e');
    }
  }

  // Add or update child info
  static Future<ChildInfo> upsertChildInfo(ChildInfo childInfo) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Check if device belongs to current user
      final deviceCheck = await _supabase
          .from('devices')
          .select('id')
          .eq('device_id', childInfo.deviceId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (deviceCheck == null) {
        throw Exception('Device not found or access denied');
      }

      final data = {
        'device_id': childInfo.deviceId,
        'child_name': childInfo.childName,
        'age': childInfo.age,
        'gender': childInfo.gender,
        'relationship': childInfo.relationship,
        'school': childInfo.school,
        'emergency_contact': childInfo.emergencyContact,
        'medical_info': childInfo.medicalInfo,
        'notes': childInfo.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Check if child info already exists
      final existing = await _supabase
          .from('child_info')
          .select('id')
          .eq('device_id', childInfo.deviceId)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        final response = await _supabase
            .from('child_info')
            .update(data)
            .eq('device_id', childInfo.deviceId)
            .select()
            .single();
        
        return ChildInfo.fromJson(response);
      } else {
        // Insert new
        data['created_at'] = DateTime.now().toIso8601String();
        
        final response = await _supabase
            .from('child_info')
            .insert(data)
            .select()
            .single();
        
        return ChildInfo.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to save child info: $e');
    }
  }

  // Delete child info
  static Future<void> deleteChildInfo(String deviceId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Check if device belongs to current user
      final deviceCheck = await _supabase
          .from('devices')
          .select('id')
          .eq('device_id', deviceId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (deviceCheck == null) {
        throw Exception('Device not found or access denied');
      }

      await _supabase
          .from('child_info')
          .delete()
          .eq('device_id', deviceId);
    } catch (e) {
      throw Exception('Failed to delete child info: $e');
    }
  }

  // Validate child info
  static String? validateChildInfo(ChildInfo childInfo) {
    if (childInfo.childName.trim().isEmpty) {
      return 'Child name is required';
    }
    
    if (childInfo.childName.trim().length < 2) {
      return 'Child name must be at least 2 characters';
    }
    
    if (childInfo.age < 0 || childInfo.age > 18) {
      return 'Age must be between 0 and 18';
    }
    
    if (childInfo.gender.trim().isEmpty) {
      return 'Gender is required';
    }
    
    // Validate emergency contact if provided
    if (childInfo.emergencyContact != null && 
        childInfo.emergencyContact!.isNotEmpty) {
      final phoneRegex = RegExp(r'^[\+]?[0-9\-\(\)\s]+$');
      if (!phoneRegex.hasMatch(childInfo.emergencyContact!)) {
        return 'Please enter a valid emergency contact number';
      }
    }
    
    return null;
  }
}