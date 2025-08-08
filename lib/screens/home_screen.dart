import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Geofence model
class Geofence {
  final String id;
  final String name;
  final List<LatLng> points;
  final Color color;
  final DateTime createdAt;
  bool isActive;

  Geofence({
    required this.id,
    required this.name,
    required this.points,
    required this.color,
    required this.createdAt,
    this.isActive = true,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final MapController _mapController = MapController();

  // Location tracking variables
  Position? _currentPosition;
  bool _isLocationServiceEnabled = false;
  bool _isTrackingLocation = false;
  List<LatLng> _locationHistory = [];

  // Geofence variables
  List<Geofence> _geofences = [];
  bool _isDrawingGeofence = false;
  List<LatLng> _currentGeofencePoints = [];
  final TextEditingController _geofenceNameController = TextEditingController();

  // Initialize local notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
    _initializeNotifications(); // Initialize notifications
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _geofenceNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
  }

  // Initialize notification plugin
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String geofenceName, String action) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Alerts',
      channelDescription: 'Notification channel for geofence entry and exit alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '$action Geofence: $geofenceName',
      'You have $action the geofence: $geofenceName',
      platformChannelSpecifics,
      payload: 'Geofence Notification',
    );
  }

  Future<void> _initializeLocation() async {
    await _requestLocationPermissions();
    await _checkLocationService();
    if (_isLocationServiceEnabled) {
      await _getCurrentLocation();
      _startLocationTracking();
    }
  }

  Future<void> _requestLocationPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _checkLocationService() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isLocationServiceEnabled = isEnabled;
    });

    if (!isEnabled) {
      _showLocationServiceDialog();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use the map features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
          _locationHistory.add(LatLng(position.latitude, position.longitude));
        });

        // Center map on current location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _startLocationTracking() {
    if (!_isTrackingLocation) {
      setState(() {
        _isTrackingLocation = true;
      });

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Position position) {
        setState(() {
          _currentPosition = position;
          _locationHistory.add(LatLng(position.latitude, position.longitude));

          // Keep only last 100 locations to prevent memory issues
          if (_locationHistory.length > 100) {
            _locationHistory.removeAt(0);
          }
        });

        // Check geofence status
        _checkGeofenceStatus(position);
      });
    }
  }

  void _checkGeofenceStatus(Position position) {
    for (var geofence in _geofences) {
      if (geofence.isActive) {
        bool isInside = _isPointInPolygon(
          LatLng(position.latitude, position.longitude),
          geofence.points,
        );

        if (isInside) {
          _showGeofenceAlert(geofence.name, "Entered", Colors.green);
          _showNotification(geofence.name, "Entered");  // Push notification on entry
        } else {
          _showGeofenceAlert(geofence.name, "Exited", Colors.red);
          _showNotification(geofence.name, "Exited");  // Push notification on exit
        }
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;

      if (((polygon[i].latitude <= point.latitude && point.latitude < polygon[j].latitude) ||
          (polygon[j].latitude <= point.latitude && point.latitude < polygon[i].latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) *
              (point.latitude - polygon[i].latitude) /
              (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        intersectCount++;
      }
    }

    return (intersectCount % 2) == 1;
  }

  void _showGeofenceAlert(String geofenceName, String action, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action geofence: $geofenceName'),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _stopLocationTracking() {
    setState(() {
      _isTrackingLocation = false;
    });
  }

  void _centerMapOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    }
  }

  void _startDrawingGeofence() {
    setState(() {
      _isDrawingGeofence = true;
      _currentGeofencePoints.clear();
    });
  }

  void _stopDrawingGeofence() {
    if (_currentGeofencePoints.length >= 3) {
      _showCreateGeofenceDialog();
    } else {
      setState(() {
        _isDrawingGeofence = false;
        _currentGeofencePoints.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence needs at least 3 points')),
      );
    }
  }

  void _showCreateGeofenceDialog() {
    _geofenceNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Geofence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _geofenceNameController,
              decoration: const InputDecoration(
                labelText: 'Geofence Name',
                hintText: 'Enter a name for this geofence',
              ),
            ),
            const SizedBox(height: 16),
            Text('Points: ${_currentGeofencePoints.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDrawingGeofence = false;
                _currentGeofencePoints.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_geofenceNameController.text.isNotEmpty) {
                _createGeofence(_geofenceNameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createGeofence(String name) {
    final geofence = Geofence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      points: List.from(_currentGeofencePoints),
      color: Colors.primaries[_geofences.length % Colors.primaries.length],
      createdAt: DateTime.now(),
    );

    setState(() {
      _geofences.add(geofence);
      _isDrawingGeofence = false;
      _currentGeofencePoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Geofence "$name" created successfully')),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingGeofence) {
      setState(() {
        _currentGeofencePoints.add(point);
      });
    }
  }

  void _showGeofencesList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Geofences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _geofences.isEmpty
                  ? const Center(child: Text('No geofences created yet'))
                  : ListView.builder(
                itemCount: _geofences.length,
                itemBuilder: (context, index) {
                  final geofence = _geofences[index];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: geofence.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(geofence.name),
                      subtitle: Text(
                        '${geofence.points.length} points • ${geofence.isActive ? "Active" : "Inactive"}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: geofence.isActive,
                            onChanged: (value) {
                              setState(() {
                                geofence.isActive = value;
                              });
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _geofences.removeAt(index);
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(),
          // Placeholder screens for navigation
          const Center(child: Text('Settings Screen')),
          const Center(child: Text('Messages Screen')),
          const Center(child: Text('Profile Screen')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red.shade300,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        // App Bar
        Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100,
                Colors.red.shade100,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green.shade800,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SafeSpot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade300,
                    ),
                  ),
                  if (_currentPosition != null)
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _showGeofencesList,
                icon: Icon(
                  Icons.layers,
                  color: Colors.grey.shade700,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Implement notifications
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Drawing instructions
        if (_isDrawingGeofence)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Tap on the map to add points to your geofence'),
                ),
                TextButton(
                  onPressed: _stopDrawingGeofence,
                  child: const Text('Finish'),
                ),
              ],
            ),
          ),

        // Map Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : LatLng(8.9511, 125.5439), // Default to Cagayan de Oro
                      zoom: 15.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      onTap: _onMapTap,
                    ),
                    children: [
                      // Tile Layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.safespot',
                      ),

                      // Geofences Polygons
                      PolygonLayer(
                        polygons: [
                          // Existing geofences
                          ..._geofences.map((geofence) => Polygon(
                            points: geofence.points,
                            color: geofence.color.withOpacity(0.2),
                            borderColor: geofence.color,
                            borderStrokeWidth: 2.0,
                          )),
                          // Current drawing geofence
                          if (_currentGeofencePoints.length >= 3)
                            Polygon(
                              points: _currentGeofencePoints,
                              color: Colors.orange.withOpacity(0.2),
                              borderColor: Colors.orange,
                              borderStrokeWidth: 2.0,
                            ),
                        ],
                      ),

                      // Geofence markers for drawing
                      if (_currentGeofencePoints.isNotEmpty)
                        MarkerLayer(
                          markers: _currentGeofencePoints
                              .asMap()
                              .entries
                              .map((entry) => Marker(
                            point: entry.value,
                            builder: (context) => Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ))
                              .toList(),
                        ),

                      // Location History Polyline
                      if (_locationHistory.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _locationHistory,
                              strokeWidth: 3.0,
                              color: Colors.blue.withOpacity(0.7),
                            ),
                          ],
                        ),

                      // Current Location Marker
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              builder: (context) => Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Map controls
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "zoom_in",
                          onPressed: () {
                            var currentZoom = _mapController.zoom;
                            _mapController.move(_mapController.center, currentZoom + 1);
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.add, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "zoom_out",
                          onPressed: () {
                            var currentZoom = _mapController.zoom;
                            _mapController.move(_mapController.center, currentZoom - 1);
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.remove, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "my_location",
                          onPressed: _centerMapOnCurrentLocation,
                          backgroundColor: _isTrackingLocation ? Colors.blue.shade100 : Colors.white,
                          child: Icon(
                            Icons.my_location,
                            color: _isTrackingLocation ? Colors.blue : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "tracking_toggle",
                          onPressed: () {
                            if (_isTrackingLocation) {
                              _stopLocationTracking();
                            } else {
                              _startLocationTracking();
                            }
                          },
                          backgroundColor: _isTrackingLocation ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            _isTrackingLocation ? Icons.pause : Icons.play_arrow,
                            color: _isTrackingLocation ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "draw_geofence",
                          onPressed: _isDrawingGeofence ? _stopDrawingGeofence : _startDrawingGeofence,
                          backgroundColor: _isDrawingGeofence ? Colors.orange.shade100 : Colors.white,
                          child: Icon(
                            _isDrawingGeofence ? Icons.stop : Icons.draw,
                            color: _isDrawingGeofence ? Colors.orange : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location info overlay
                  if (_currentPosition != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              'Speed: ${_currentPosition!.speed.toStringAsFixed(1)}m/s',
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              'History: ${_locationHistory.length} points',
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              'Geofences: ${_geofences.length}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // No location overlay
                  if (_currentPosition == null && _isLocationServiceEnabled)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Getting your location...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Location disabled overlay
                  if (!_isLocationServiceEnabled)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Location services are disabled',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Geolocator.openLocationSettings();
                                },
                                child: const Text('Enable Location'),
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

        // Quick Actions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement emergency alert
                  },
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text("Emergency Alert"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Clear location history
                    setState(() {
                      _locationHistory.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location history cleared')),
                    );
                  },
                  icon: const Icon(Icons.clear_all, color: Colors.black),
                  label: const Text("Clear History"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
