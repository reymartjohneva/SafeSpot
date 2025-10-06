import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Firebase configuration
  static const String _firebaseHost =
      'sim800l-gps-data-default-rtdb.firebaseio.com';
  static const String _firebaseAuthKey =
      '9KzEmnOMRLzE0faPlxKyEc6TsHnjSmEq5me0AKs3';
  static const String _firebaseDataPath = '/'; // Root path

  // Sync state
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static DateTime? _lastSyncTime;

  /// Start automatic syncing at specified interval
  static void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    stopAutoSync(); // Stop any existing timer

    // Perform initial sync
    syncData();

    // Schedule periodic syncs
    _syncTimer = Timer.periodic(interval, (timer) {
      syncData();
    });
  }

  /// Stop automatic syncing
  static void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Get last sync time
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  static bool get isSyncing => _isSyncing;

  /// Manually trigger a sync
  static Future<SyncResult> syncData() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        recordsProcessed: 0,
        recordsInserted: 0,
        recordsSkipped: 0,
        errors: [],
      );
    }

    _isSyncing = true;

    try {
      final result = await _performSync();
      _lastSyncTime = DateTime.now();
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  /// Fetch data from Firebase Realtime Database
  static Future<Map<String, dynamic>?> _fetchFirebaseData() async {
    try {
      final url = Uri.https(_firebaseHost, '$_firebaseDataPath.json', {
        'auth': _firebaseAuthKey,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) return null;
        return data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Firebase fetch failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch Firebase data: $e');
    }
  }

  /// Check if device exists in devices table
  static Future<bool> _deviceExists(String deviceId) async {
    try {
      final response =
          await _supabase
              .from('devices')
              .select('device_id')
              .eq('device_id', deviceId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking device existence for device_id $deviceId: $e');
      return false;
    }
  }

  /// Check if location already exists in Supabase
  static Future<bool> _locationExists({
    required String deviceId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      final response =
          await _supabase
              .from('location_history')
              .select('id')
              .eq('device_id', deviceId)
              .eq('latitude', latitude)
              .eq('longitude', longitude)
              .eq('timestamp', timestamp.toIso8601String())
              .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking location existence: $e');
      return false; // If error, assume doesn't exist and try to insert
    }
  }

  /// Insert location data into Supabase
  static Future<bool> _insertLocationData({
    required String deviceId,
    required double latitude,
    required double longitude,
    required double? speed,
    required DateTime timestamp,
    required String firebaseKey,
  }) async {
    try {
      // Check if already exists
      final exists = await _locationExists(
        deviceId: deviceId,
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
      );

      if (exists) {
        return false; // Skip, already exists
      }

      await _supabase.from('location_history').insert({
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
        'source': 'firebase',
      });

      return true;
    } catch (e) {
      throw Exception('Failed to insert location data: $e');
    }
  }

  /// Parse timestamp from Firebase format
  static DateTime? _parseTimestamp(String timestamp) {
    try {
      // Format: "2025-10-06 01:18:13"
      // Parse as local time then convert to UTC
      final parts = timestamp.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      ).toUtc();
    } catch (e) {
      debugPrint('Error parsing timestamp "$timestamp": $e');
      return null;
    }
  }

  /// Perform the actual sync operation
  static Future<SyncResult> _performSync() async {
    int recordsProcessed = 0;
    int recordsInserted = 0;
    int recordsSkipped = 0;
    List<String> errors = [];

    try {
      // Fetch data from Firebase
      final firebaseData = await _fetchFirebaseData();

      if (firebaseData == null || firebaseData.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No data to sync from Firebase',
          recordsProcessed: 0,
          recordsInserted: 0,
          recordsSkipped: 0,
          errors: [],
        );
      }

      // Process each record
      for (final entry in firebaseData.entries) {
        final firebaseKey = entry.key;
        final record = entry.value as Map<String, dynamic>;

        recordsProcessed++;

        try {
          // Extract data
          final deviceId = record['childID'] as String?;
          final lat = record['lat'] as num?;
          final long = record['long'] as num?;
          final speed = record['speed'] as num?;
          final timestampStr = record['timestamp'] as String?;

          // Validate required fields
          if (deviceId == null ||
              lat == null ||
              long == null ||
              timestampStr == null) {
            errors.add('Record $firebaseKey: Missing required fields');
            recordsSkipped++;
            continue;
          }

          // Parse timestamp
          final timestamp = _parseTimestamp(timestampStr);
          if (timestamp == null) {
            errors.add(
              'Record $firebaseKey: Invalid timestamp format: $timestampStr',
            );
            recordsSkipped++;
            continue;
          }

          // Check if device exists in devices table
          final deviceExists = await _deviceExists(deviceId);
          if (!deviceExists) {
            errors.add(
              'Record $firebaseKey: No device found for device_id: $deviceId',
            );
            recordsSkipped++;
            continue;
          }

          // Insert into Supabase
          final inserted = await _insertLocationData(
            deviceId: deviceId,
            latitude: lat.toDouble(),
            longitude: long.toDouble(),
            speed: speed?.toDouble(),
            timestamp: timestamp,
            firebaseKey: firebaseKey,
          );

          if (inserted) {
            recordsInserted++;
          } else {
            recordsSkipped++;
          }
        } catch (e) {
          errors.add('Record $firebaseKey: $e');
          recordsSkipped++;
        }
      }

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        recordsProcessed: recordsProcessed,
        recordsInserted: recordsInserted,
        recordsSkipped: recordsSkipped,
        errors: errors,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        recordsProcessed: recordsProcessed,
        recordsInserted: recordsInserted,
        recordsSkipped: recordsSkipped,
        errors: [...errors, e.toString()],
      );
    }
  }

  /// Delete Firebase record after successful sync (optional)
  static Future<bool> deleteFirebaseRecord(String key) async {
    try {
      final url = Uri.https(_firebaseHost, '/$key.json', {
        'auth': _firebaseAuthKey,
      });

      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting Firebase record $key: $e');
      return false;
    }
  }

  /// Sync and optionally delete Firebase records
  static Future<SyncResult> syncAndCleanup() async {
    final syncResult = await syncData();

    if (syncResult.success && syncResult.recordsInserted > 0) {
      // Optionally delete synced records from Firebase
      // Uncomment if you want to clean up Firebase after sync
      /*
      final firebaseData = await _fetchFirebaseData();
      if (firebaseData != null) {
        for (final key in firebaseData.keys) {
          await deleteFirebaseRecord(key);
        }
      }
      */
    }

    return syncResult;
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int recordsProcessed;
  final int recordsInserted;
  final int recordsSkipped;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.recordsProcessed,
    required this.recordsInserted,
    required this.recordsSkipped,
    required this.errors,
  });

  @override
  String toString() {
    return '''
SyncResult(
  success: $success,
  message: $message,
  recordsProcessed: $recordsProcessed,
  recordsInserted: $recordsInserted,
  recordsSkipped: $recordsSkipped,
  errors: ${errors.isNotEmpty ? errors.join(', ') : 'None'}
)''';
  }
}
