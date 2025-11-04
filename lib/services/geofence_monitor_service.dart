// geofence_monitor_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_spot/services/geofence_service.dart';

/// Service to monitor device locations and trigger geofence notifications
class GeofenceMonitorService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Map to track the last known state of each device for each geofence
  // Key: "deviceId:geofenceId", Value: GeofenceState
  static final Map<String, GeofenceState> _deviceGeofenceStates = {};

  // Set to track which location IDs we've already processed
  static final Set<String> _processedLocationIds = {};

  // Flag to track if we've done initial load
  static bool _hasLoadedInitialState = false;

  // Stream subscriptions
  static StreamSubscription? _locationSubscription;
  static StreamSubscription? _geofenceSubscription;

  // Cache for active geofences
  static List<Geofence> _activeGeofences = [];

  static String? get currentUserId => _client.auth.currentUser?.id;
  static bool get isAuthenticated => currentUserId != null;

  /// Initialize the geofence monitoring service
  static Future<void> initialize() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    print('🔄 Initializing Geofence Monitor Service...');

    // Reset the loaded state flag
    _hasLoadedInitialState = false;

    // Load active geofences
    await _loadActiveGeofences();

    // Subscribe to geofence changes
    _subscribeToGeofenceChanges();

    // Subscribe to location updates
    _subscribeToLocationUpdates();

    print('✅ Geofence Monitor Service initialized');
  }

  /// Load all active geofences for the current user
  static Future<void> _loadActiveGeofences() async {
    try {
      final geofencesData = await GeofenceService.getUserGeofences();
      _activeGeofences =
          geofencesData
              .where((g) => g['is_active'] == true)
              .map((g) => Geofence.fromSupabase(g))
              .toList();

      print('📍 Loaded ${_activeGeofences.length} active geofences');
    } catch (e) {
      print('❌ Error loading geofences: $e');
    }
  }

  /// Subscribe to real-time geofence changes
  static void _subscribeToGeofenceChanges() {
    _geofenceSubscription?.cancel();

    _geofenceSubscription = _client
        .from('geofences:user_id=eq.$currentUserId')
        .stream(primaryKey: ['id'])
        .listen((data) {
          print('🔄 Geofences updated, reloading...');
          _activeGeofences =
              data
                  .where((g) => g['is_active'] == true)
                  .map((g) => Geofence.fromSupabase(g))
                  .toList();

          print('📍 Updated to ${_activeGeofences.length} active geofences');
        });
  }

  /// Subscribe to real-time location updates (only NEW updates)
  static void _subscribeToLocationUpdates() {
    _locationSubscription?.cancel();

    // Get all devices for the current user
    _client
        .from('devices')
        .select('id, device_id')
        .eq('user_id', currentUserId!)
        .then((devices) async {
          if (devices.isEmpty) {
            print('⚠️ No devices found for user');
            return;
          }

          final deviceIds =
              devices.map((d) => d['device_id'] as String).toList();
          print('📱 Monitoring ${devices.length} devices for geofence events');
          print('📱 Device IDs: $deviceIds');

          // Load initial state from last known locations
          await _loadInitialStates(deviceIds);

          // Mark that we've loaded initial state
          _hasLoadedInitialState = true;

          print('⏰ Starting real-time monitoring');

          // Subscribe to location_history changes for user's devices
          _locationSubscription = _client
              .from('location_history')
              .stream(primaryKey: ['id'])
              .listen(
                (data) {
                  if (data.isEmpty) return;

                  print('📡 Stream update received: ${data.length} records');
                  print('   Has loaded initial state: $_hasLoadedInitialState');
                  print(
                    '   Processed IDs count: ${_processedLocationIds.length}',
                  );

                  // Process only NEW real-time locations
                  int newCount = 0;
                  int skippedCount = 0;

                  for (final location in data) {
                    final deviceId = location['device_id'];
                    if (!deviceIds.contains(deviceId)) continue;

                    final locationId = location['id'].toString();

                    // Skip if we've already processed this location
                    if (_processedLocationIds.contains(locationId)) {
                      skippedCount++;
                      continue;
                    }

                    // Mark as processed
                    _processedLocationIds.add(locationId);
                    newCount++;

                    print(
                      '🆕 NEW real-time location for $deviceId (ID: $locationId)',
                    );
                    _processLocationUpdate(location);
                  }

                  print('   Processed: $newCount new, $skippedCount skipped');
                },
                onError: (error) {
                  print('❌ Location stream error: $error');
                },
              );
        })
        .catchError((e) {
          print('❌ Error subscribing to location updates: $e');
        });
  }

  /// Load initial geofence states from the last known location of each device
  static Future<void> _loadInitialStates(List<String> deviceIds) async {
    try {
      print('🔄 Loading initial states for devices...');

      // First, get ALL existing location IDs and mark them as processed
      // This prevents processing historical data
      print('🔄 Fetching all existing location IDs to mark as processed...');
      final allLocations = await _client
          .from('location_history')
          .select('id')
          .inFilter('device_id', deviceIds);

      for (final loc in allLocations) {
        _processedLocationIds.add(loc['id'].toString());
      }

      print(
        '✅ Marked ${_processedLocationIds.length} existing locations as processed',
      );

      // Now get the latest location per device for initial state
      for (final deviceId in deviceIds) {
        final latestLocation =
            await _client
                .from('location_history')
                .select()
                .eq('device_id', deviceId)
                .order('timestamp', ascending: false)
                .limit(1)
                .maybeSingle();

        if (latestLocation == null) {
          print('⚠️ No location history found for device: $deviceId');
          continue;
        }

        final latitude = (latestLocation['latitude'] as num).toDouble();
        final longitude = (latestLocation['longitude'] as num).toDouble();
        final timestamp = DateTime.parse(latestLocation['timestamp'] as String);
        final locationId = latestLocation['id'].toString();
        final currentLocation = LatLng(latitude, longitude);

        print(
          '📍 Last known location for $deviceId: ($latitude, $longitude) at $timestamp (ID: $locationId)',
        );

        // Check this location against all geofences to establish initial state
        for (final geofence in _activeGeofences) {
          final stateKey = '$deviceId:${geofence.id}';
          final isInside = GeofenceUtils.isPointInPolygon(
            currentLocation,
            geofence.points,
          );

          // Store the initial state WITHOUT triggering notification
          _deviceGeofenceStates[stateKey] = GeofenceState(
            deviceId: deviceId,
            geofenceId: geofence.id,
            isInside: isInside,
            lastUpdate: timestamp,
          );

          print(
            '💾 Initial state: $deviceId in ${geofence.name} = ${isInside ? "INSIDE" : "OUTSIDE"}',
          );
        }
      }

      print('✅ Initial states loaded successfully');
    } catch (e) {
      print('❌ Error loading initial states: $e');
    }
  }

  /// Process a location update and check geofence status
  static Future<void> _processLocationUpdate(
    Map<String, dynamic> locationData,
  ) async {
    try {
      final deviceId = locationData['device_id'] as String;
      final latitude = (locationData['latitude'] as num).toDouble();
      final longitude = (locationData['longitude'] as num).toDouble();
      final timestamp = DateTime.parse(locationData['timestamp'] as String);

      final currentLocation = LatLng(latitude, longitude);

      print(
        '📍 Processing location for device: $deviceId at ($latitude, $longitude)',
      );

      // Check against all active geofences
      for (final geofence in _activeGeofences) {
        await _checkGeofenceStatus(
          deviceId: deviceId,
          geofence: geofence,
          currentLocation: currentLocation,
          timestamp: timestamp,
        );
      }
    } catch (e) {
      print('❌ Error processing location update: $e');
    }
  }

  /// Check if device entered or exited a geofence
  static Future<void> _checkGeofenceStatus({
    required String deviceId,
    required Geofence geofence,
    required LatLng currentLocation,
    required DateTime timestamp,
  }) async {
    final stateKey = '$deviceId:${geofence.id}';
    final isInside = GeofenceUtils.isPointInPolygon(
      currentLocation,
      geofence.points,
    );

    print('🔍 Checking $deviceId vs ${geofence.name}:');
    print(
      '   Location: (${currentLocation.latitude}, ${currentLocation.longitude})',
    );
    print('   Is Inside: $isInside');
    print('   Geofence points: ${geofence.points.length}');
    print('   State Key: $stateKey');

    // Get previous state
    final previousState = _deviceGeofenceStates[stateKey];

    if (previousState == null) {
      // This shouldn't happen since we load initial states, but handle it anyway
      _deviceGeofenceStates[stateKey] = GeofenceState(
        deviceId: deviceId,
        geofenceId: geofence.id,
        isInside: isInside,
        lastUpdate: timestamp,
      );

      print(
        '⚠️ No previous state found (unexpected). Setting initial state: ${isInside ? "INSIDE" : "OUTSIDE"}',
      );
      print(
        '   This is likely the first location for this device-geofence pair',
      );
      return; // Don't notify
    }

    print(
      '📊 Previous state: ${previousState.isInside ? "INSIDE" : "OUTSIDE"} (updated at: ${previousState.lastUpdate})',
    );
    print(
      '📊 Current state: ${isInside ? "INSIDE" : "OUTSIDE"} (timestamp: $timestamp)',
    );
    print('📊 State changed? ${previousState.isInside != isInside}');

    // Check for state change
    if (previousState.isInside != isInside) {
      print(
        '🔔 State change detected for $deviceId in ${geofence.name}: ${previousState.isInside ? "INSIDE" : "OUTSIDE"} → ${isInside ? "INSIDE" : "OUTSIDE"}',
      );

      // Update state
      _deviceGeofenceStates[stateKey] = GeofenceState(
        deviceId: deviceId,
        geofenceId: geofence.id,
        isInside: isInside,
        lastUpdate: timestamp,
      );

      // Create notification based on transition
      if (isInside && !previousState.isInside) {
        // OUTSIDE → INSIDE (Entry)
        print(
          '🟢 Triggering ENTRY notification for $deviceId entering ${geofence.name}',
        );
        await _createGeofenceNotification(
          deviceId: deviceId,
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          notificationType: 'geofence_entry',
          location: currentLocation,
        );
      } else if (!isInside && previousState.isInside) {
        // INSIDE → OUTSIDE (Exit)
        print('🔴 Triggering EXIT notification');
        await _createGeofenceNotification(
          deviceId: deviceId,
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          notificationType: 'geofence_exit',
          location: currentLocation,
        );
      }
    } else {
      print('✅ State unchanged - no notification needed');
      // State unchanged, just update timestamp
      _deviceGeofenceStates[stateKey] = previousState.copyWith(
        lastUpdate: timestamp,
      );
    }
  }

  /// Create a geofence notification in the database
  static Future<void> _createGeofenceNotification({
    required String deviceId,
    required String geofenceId,
    required String geofenceName,
    required String notificationType,
    required LatLng location,
  }) async {
    try {
      print('📝 Creating notification:');
      print('   Device ID: $deviceId (length: ${deviceId.length})');
      print('   Geofence ID: $geofenceId');
      print('   Type: $notificationType');

      // Get device info
      final deviceData =
          await _client
              .from('devices')
              .select('device_name')
              .eq('device_id', deviceId)
              .single();

      final deviceName = deviceData['device_name'] as String;
      print('   Device Name: $deviceName');

      // Generate notification message
      final String title;
      final String message;

      if (notificationType == 'geofence_entry') {
        title = '🟢 Geofence Entry';
        message = '$deviceName entered $geofenceName';
      } else {
        title = '🔴 Geofence Exit';
        message = '$deviceName left $geofenceName';
      }

      // Parse geofence_id as integer (geofences table uses INTEGER for id)
      final geofenceIdInt = int.tryParse(geofenceId);
      if (geofenceIdInt == null) {
        print('❌ Invalid geofence_id: $geofenceId (cannot parse to integer)');
        return;
      }

      // Insert notification
      final insertData = {
        'user_id': currentUserId!,
        'device_id': deviceId,
        'geofence_id': geofenceIdInt,
        'notification_type': notificationType,
        'title': title,
        'message': message,
        'is_read': false,
        'metadata': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'geofence_name': geofenceName,
          'device_name': deviceName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      print('📤 Inserting notification data: ${insertData.toString()}');

      await _client.from('notifications').insert(insertData);

      print(
        '✅ Created $notificationType notification for $deviceName in $geofenceName',
      );
    } catch (e) {
      print('❌ Error creating geofence notification: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Manually check a specific location against all geofences
  static Future<List<GeofenceCheckResult>> checkLocation({
    required String deviceId,
    required LatLng location,
  }) async {
    final results = <GeofenceCheckResult>[];

    for (final geofence in _activeGeofences) {
      final isInside = GeofenceUtils.isPointInPolygon(
        location,
        geofence.points,
      );
      results.add(GeofenceCheckResult(geofence: geofence, isInside: isInside));
    }

    return results;
  }

  /// Manually process latest location for a device (useful for debugging)
  static Future<void> manualCheckDevice(String deviceId) async {
    try {
      print('🔧 Manual check for device: $deviceId');

      // Get latest location
      final locationData =
          await _client
              .from('location_history')
              .select('*')
              .eq('device_id', deviceId)
              .order('timestamp', ascending: false)
              .limit(1)
              .single();

      print(
        '📍 Found location: ${locationData['latitude']}, ${locationData['longitude']}',
      );

      // Process it
      await _processLocationUpdate(locationData);

      print('✅ Manual check completed');
    } catch (e) {
      print('❌ Manual check failed: $e');
    }
  }

  /// Force recheck all devices (useful for debugging)
  static Future<void> recheckAllDevices() async {
    try {
      print('🔧 Rechecking all devices...');

      final devices = await _client
          .from('devices')
          .select('device_id')
          .eq('user_id', currentUserId!);

      for (final device in devices) {
        await manualCheckDevice(device['device_id']);
      }

      print('✅ All devices rechecked');
    } catch (e) {
      print('❌ Recheck all failed: $e');
    }
  }

  /// Get current state for a device-geofence combination
  static GeofenceState? getDeviceGeofenceState(
    String deviceId,
    String geofenceId,
  ) {
    return _deviceGeofenceStates['$deviceId:$geofenceId'];
  }

  /// Get all states for a specific device
  static Map<String, GeofenceState> getDeviceStates(String deviceId) {
    return Map.fromEntries(
      _deviceGeofenceStates.entries.where((e) => e.value.deviceId == deviceId),
    );
  }

  /// Reset state for a specific device-geofence combination
  static void resetState(String deviceId, String geofenceId) {
    _deviceGeofenceStates.remove('$deviceId:$geofenceId');
    print('🔄 Reset state for $deviceId in geofence $geofenceId');
  }

  /// Reset all states for a device
  static void resetDeviceStates(String deviceId) {
    _deviceGeofenceStates.removeWhere(
      (key, value) => value.deviceId == deviceId,
    );
    print('🔄 Reset all states for device $deviceId');
  }

  /// Clear all states
  static void clearAllStates() {
    _deviceGeofenceStates.clear();
    _processedLocationIds.clear();
    _hasLoadedInitialState = false;
    print('🔄 Cleared all geofence states and processed location IDs');
  }

  /// Dispose and cleanup
  static void dispose() {
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _deviceGeofenceStates.clear();
    _processedLocationIds.clear();
    _activeGeofences.clear();
    _hasLoadedInitialState = false;
    print('🛑 Geofence Monitor Service disposed');
  }
}

/// Represents the state of a device relative to a geofence
class GeofenceState {
  final String deviceId;
  final String geofenceId;
  final bool isInside;
  final DateTime lastUpdate;

  GeofenceState({
    required this.deviceId,
    required this.geofenceId,
    required this.isInside,
    required this.lastUpdate,
  });

  GeofenceState copyWith({
    String? deviceId,
    String? geofenceId,
    bool? isInside,
    DateTime? lastUpdate,
  }) {
    return GeofenceState(
      deviceId: deviceId ?? this.deviceId,
      geofenceId: geofenceId ?? this.geofenceId,
      isInside: isInside ?? this.isInside,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() {
    return 'GeofenceState(device: $deviceId, geofence: $geofenceId, inside: $isInside, updated: $lastUpdate)';
  }
}

/// Result of checking a location against a geofence
class GeofenceCheckResult {
  final Geofence geofence;
  final bool isInside;

  GeofenceCheckResult({required this.geofence, required this.isInside});
}
