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
  static Timer? _pollTimer;

  // Cache for active geofences
  static List<Geofence> _activeGeofences = [];

  // List of device IDs to monitor
  static List<String> _deviceIds = [];

  // Track last processed timestamp per device
  static Map<String, DateTime> _lastProcessedTimestamp = {};

  static String? get currentUserId => _client.auth.currentUser?.id;
  static bool get isAuthenticated => currentUserId != null;

  /// Initialize the geofence monitoring service
  static Future<void> initialize() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    print('🔄 Initializing Geofence Monitor Service...');

    // Reset everything
    _hasLoadedInitialState = false;
    _processedLocationIds.clear();
    _deviceGeofenceStates.clear();

    // Load active geofences
    await _loadActiveGeofences();

    // Load device IDs
    await _loadDeviceIds();

    // Subscribe to geofence changes
    _subscribeToGeofenceChanges();

    // Subscribe to location updates AFTER loading initial states
    await _subscribeToLocationUpdates();

    print('✅ Geofence Monitor Service initialized');
  }

  /// Load device IDs for the current user
  static Future<void> _loadDeviceIds() async {
    try {
      final devices = await _client
          .from('devices')
          .select('device_id')
          .eq('user_id', currentUserId!);

      _deviceIds = devices.map((d) => d['device_id'] as String).toList();
      print('📱 Loaded ${_deviceIds.length} device IDs: $_deviceIds');
    } catch (e) {
      print('❌ Error loading device IDs: $e');
    }
  }

  /// Load all active geofences for the current user
  static Future<void> _loadActiveGeofences() async {
    try {
      final geofencesData = await GeofenceService.getUserGeofences();
      _activeGeofences = geofencesData
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
        .from('geofences')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .listen((data) {
      print('🔄 Geofences updated, reloading...');
      _activeGeofences = data
          .where((g) => g['is_active'] == true)
          .map((g) => Geofence.fromSupabase(g))
          .toList();

      print('📍 Updated to ${_activeGeofences.length} active geofences');
      
      // Clear states for removed geofences
      _cleanupStatesForRemovedGeofences();
    });
  }

  /// Clean up states for geofences that no longer exist
  static void _cleanupStatesForRemovedGeofences() {
    final activeGeofenceIds = _activeGeofences.map((g) => g.id).toSet();
    _deviceGeofenceStates.removeWhere((key, state) =>
        !activeGeofenceIds.contains(state.geofenceId));
  }

  /// Subscribe to real-time location updates
  static Future<void> _subscribeToLocationUpdates() async {
    _locationSubscription?.cancel();
    _pollTimer?.cancel();

    if (_deviceIds.isEmpty) {
      print('⚠️ No devices found for user');
      return;
    }

    print('📱 Monitoring ${_deviceIds.length} devices for geofence events');

    // Load initial states from last known locations
    await _loadInitialStates();

    // Mark that we've loaded initial state
    _hasLoadedInitialState = true;

    print('⏰ Starting real-time monitoring for location_history stream');

    // Subscribe to location_history changes
    _locationSubscription = _client
        .from('location_history')
        .stream(primaryKey: ['id'])
        .inFilter('device_id', _deviceIds)
        .order('timestamp', ascending: false)
        .listen(
          (data) {
            if (data.isEmpty) {
              print('⚠️ Stream update received but data is empty');
              return;
            }

            print('📡 Stream update received: ${data.length} records');
            print('   First 3 device_ids: ${data.take(3).map((e) => e['device_id']).toList()}');

            int newCount = 0;
            int skippedCount = 0;

            for (final location in data) {
              final deviceId = location['device_id'];
              
              // Only process locations for our devices
              if (!_deviceIds.contains(deviceId)) {
                print('⚠️ Skipping location for unknown device: $deviceId');
                continue;
              }

              final locationId = location['id'].toString();

              // Skip if we've already processed this location
              if (_processedLocationIds.contains(locationId)) {
                skippedCount++;
                continue;
              }

              // Mark as processed
              _processedLocationIds.add(locationId);
              newCount++;

              print('🆕 NEW location for $deviceId (ID: $locationId)');
              print('   📍 Latitude: ${location['latitude']}, Longitude: ${location['longitude']}');
              print('   ⏰ Timestamp: ${location['timestamp']}');
              _processLocationUpdate(location);
            }

            print('   ✅ Stream processing complete: $newCount new, $skippedCount skipped');
          },
          onError: (error) {
            print('❌ Location stream error: $error');
          },
        );

    // BACKUP: Also poll for new locations every 10 seconds in case stream fails
    _startPollingForNewLocations();
  }

  /// Poll for new locations periodically (backup mechanism)
  static void _startPollingForNewLocations() {
    _pollTimer?.cancel();
    
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        await _pollForNewLocations();
      } catch (e) {
        print('❌ Polling error: $e');
      }
    });
    
    print('⏰ Started polling for new locations every 10 seconds');
  }

  /// Poll for new locations since last check
  static Future<void> _pollForNewLocations() async {
    for (final deviceId in _deviceIds) {
      try {
        // Get last processed timestamp for this device
        final lastTimestamp = _lastProcessedTimestamp[deviceId];
        
        // Build query
        PostgrestFilterBuilder query = _client
            .from('location_history')
            .select()
            .eq('device_id', deviceId);

        // Filter by timestamp if we have one
        if (lastTimestamp != null) {
          query = query.filter('timestamp', 'gt', lastTimestamp.toIso8601String());
        }

        final newLocations = await query
            .order('timestamp', ascending: true)
            .limit(50);

        if (newLocations.isEmpty) continue;

        print('🔍 Polling found ${newLocations.length} new locations for $deviceId');

        for (final location in newLocations) {
          final locationId = location['id'].toString();
          
          // Skip if already processed
          if (_processedLocationIds.contains(locationId)) continue;

          _processedLocationIds.add(locationId);
          
          final timestamp = DateTime.parse(location['timestamp'] as String);
          _lastProcessedTimestamp[deviceId] = timestamp;

          print('🆕 Polled NEW location for $deviceId (ID: $locationId)');
          await _processLocationUpdate(location);
        }
      } catch (e) {
        print('❌ Error polling for device $deviceId: $e');
      }
    }
  }

  /// Load initial geofence states from the last known location of each device
  static Future<void> _loadInitialStates() async {
    try {
      print('🔄 Loading initial states for devices...');

      final initializationTime = DateTime.now();
      print('📅 Initialization timestamp: $initializationTime');

      // First, get ALL existing location IDs created BEFORE initialization and mark them as processed
      print('🔄 Fetching location IDs created before initialization...');
      final allLocations = await _client
          .from('location_history')
          .select('id, timestamp')
          .inFilter('device_id', _deviceIds)
          .filter('timestamp', 'lt', initializationTime.toIso8601String());

      int markedCount = 0;
      for (final loc in allLocations) {
        _processedLocationIds.add(loc['id'].toString());
        markedCount++;
      }

      print('✅ Marked $markedCount existing locations (before init) as processed');

      // Now get the latest location per device for initial state
      for (final deviceId in _deviceIds) {
        final latestLocation = await _client
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
        final currentLocation = LatLng(latitude, longitude);

        // Track last processed timestamp
        _lastProcessedTimestamp[deviceId] = timestamp;

        print('📍 Last known location for $deviceId: ($latitude, $longitude) at $timestamp');

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

          print('💾 Initial state: $deviceId in ${geofence.name} = ${isInside ? "INSIDE" : "OUTSIDE"}');
        }
      }

      print('✅ Initial states loaded successfully');
    } catch (e) {
      print('❌ Error loading initial states: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  /// Process a location update and check geofence status
  static Future<void> _processLocationUpdate(Map<String, dynamic> locationData) async {
    try {
      final deviceId = locationData['device_id'] as String;
      final latitude = (locationData['latitude'] as num).toDouble();
      final longitude = (locationData['longitude'] as num).toDouble();
      final timestamp = DateTime.parse(locationData['timestamp'] as String);

      final currentLocation = LatLng(latitude, longitude);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 Processing location for device: $deviceId');
      print('   Coordinates: ($latitude, $longitude)');
      print('   Timestamp: $timestamp');
      print('   Active geofences: ${_activeGeofences.length}');

      if (_activeGeofences.isEmpty) {
        print('⚠️ No active geofences to check against!');
        return;
      }

      // Check against all active geofences
      int checksPerformed = 0;
      for (final geofence in _activeGeofences) {
        await _checkGeofenceStatus(
          deviceId: deviceId,
          geofence: geofence,
          currentLocation: currentLocation,
          timestamp: timestamp,
        );
        checksPerformed++;
      }
      
      print('✅ Checked against $checksPerformed geofences');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ Error processing location update: $e');
      print('   Stack trace: ${StackTrace.current}');
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
    print('   Current location: (${currentLocation.latitude}, ${currentLocation.longitude})');
    print('   Is inside: $isInside');

    // Get previous state
    final previousState = _deviceGeofenceStates[stateKey];

    if (previousState == null) {
      // First time seeing this device-geofence combination
      // This shouldn't happen after initial load, but handle it gracefully
      _deviceGeofenceStates[stateKey] = GeofenceState(
        deviceId: deviceId,
        geofenceId: geofence.id,
        isInside: isInside,
        lastUpdate: timestamp,
      );

      print('⚠️ No previous state (creating initial state): ${isInside ? "INSIDE" : "OUTSIDE"}');
      return; // Don't notify on first state
    }

    print('📊 Previous: ${previousState.isInside ? "INSIDE" : "OUTSIDE"} → Current: ${isInside ? "INSIDE" : "OUTSIDE"}');

    // Check for state change
    if (previousState.isInside != isInside) {
      print('🔔 STATE CHANGE DETECTED!');

      // Update state BEFORE creating notification
      _deviceGeofenceStates[stateKey] = GeofenceState(
        deviceId: deviceId,
        geofenceId: geofence.id,
        isInside: isInside,
        lastUpdate: timestamp,
      );

      // Create notification based on transition
      if (isInside && !previousState.isInside) {
        // OUTSIDE → INSIDE (Entry)
        print('🟢 Device ENTERED geofence - Creating ENTRY notification');
        await _createGeofenceNotification(
          deviceId: deviceId,
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          notificationType: 'geofence_entry',
          location: currentLocation,
        );
      } else if (!isInside && previousState.isInside) {
        // INSIDE → OUTSIDE (Exit)
        print('🔴 Device EXITED geofence - Creating EXIT notification');
        await _createGeofenceNotification(
          deviceId: deviceId,
          geofenceId: geofence.id,
          geofenceName: geofence.name,
          notificationType: 'geofence_exit',
          location: currentLocation,
        );
      }
    } else {
      // State unchanged, just update timestamp
      _deviceGeofenceStates[stateKey] = previousState.copyWith(
        lastUpdate: timestamp,
      );
      print('✅ No state change - no notification needed');
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
      print('   Device ID: $deviceId');
      print('   Geofence ID: $geofenceId');
      print('   Type: $notificationType');

      // Get device info
      final deviceData = await _client
          .from('devices')
          .select('device_name')
          .eq('device_id', deviceId)
          .maybeSingle();

      if (deviceData == null) {
        print('❌ Device not found: $deviceId');
        return;
      }

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

      // Parse geofence_id as integer
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

      print('📤 Inserting notification...');

      await _client.from('notifications').insert(insertData);

      print('✅ Successfully created $notificationType notification!');
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
      final locationData = await _client
          .from('location_history')
          .select('*')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      print('📍 Found location: ${locationData['latitude']}, ${locationData['longitude']}');

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

      for (final deviceId in _deviceIds) {
        await manualCheckDevice(deviceId);
      }

      print('✅ All devices rechecked');
    } catch (e) {
      print('❌ Recheck all failed: $e');
    }
  }

  /// Get current state for a device-geofence combination
  static GeofenceState? getDeviceGeofenceState(String deviceId, String geofenceId) {
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
    _deviceGeofenceStates.removeWhere((key, value) => value.deviceId == deviceId);
    print('🔄 Reset all states for device $deviceId');
  }

  /// Clear all states and restart monitoring
  static Future<void> clearAllStates() async {
    _deviceGeofenceStates.clear();
    _processedLocationIds.clear();
    _hasLoadedInitialState = false;
    print('🔄 Cleared all geofence states');
    
    // Reinitialize to reload states
    await initialize();
  }

  /// TEST FUNCTION: Create a test notification to verify notification system
  static Future<void> createTestNotification() async {
    if (!isAuthenticated) {
      print('❌ User not authenticated');
      return;
    }

    if (_deviceIds.isEmpty) {
      print('❌ No devices found');
      return;
    }

    if (_activeGeofences.isEmpty) {
      print('❌ No geofences found');
      return;
    }

    final deviceId = _deviceIds.first;
    final geofence = _activeGeofences.first;

    print('🧪 Creating TEST notification...');
    print('   Device: $deviceId');
    print('   Geofence: ${geofence.name}');

    await _createGeofenceNotification(
      deviceId: deviceId,
      geofenceId: geofence.id,
      geofenceName: geofence.name,
      notificationType: 'geofence_entry',
      location: geofence.points.first,
    );

    print('✅ Test notification created! Check your notifications screen.');
  }

  /// Dispose and cleanup
  static void dispose() {
    _locationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _pollTimer?.cancel();
    _deviceGeofenceStates.clear();
    _processedLocationIds.clear();
    _activeGeofences.clear();
    _deviceIds.clear();
    _lastProcessedTimestamp.clear();
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