import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_screen.dart';
import 'connections_screen.dart';  // Add this import

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
  bool _isGettingLocation = false;
  List<LatLng> _locationHistory = [];

  // Geofence variables
  List<Geofence> _geofences = [];
  bool _isDrawingGeofence = false;
  List<LatLng> _currentGeofencePoints = [];
  final TextEditingController _geofenceNameController = TextEditingController();

  // Drag functionality variables
  bool _isDragging = false;
  int? _draggedPointIndex;
  LatLng? _draggedPointOriginalPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
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
      _reinitializeLocation();
    }
  }

  Future<void> _reinitializeLocation() async {
    // Check if location service was enabled while app was in background
    bool wasLocationEnabled = _isLocationServiceEnabled;
    await _checkLocationService();

    // If location service was just enabled, reinitialize everything
    if (!wasLocationEnabled && _isLocationServiceEnabled) {
      await _initializeLocation();
    }
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      await _requestLocationPermissions();
      await _checkLocationService();

      if (_isLocationServiceEnabled) {
        await _getCurrentLocation();
        if (_currentPosition != null) {
          _startLocationTracking();
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _requestLocationPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    // Also check Geolocator permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> _checkLocationService() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _isLocationServiceEnabled = isEnabled;
    });

    if (!isEnabled && mounted) {
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
    if (!_isLocationServiceEnabled) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10), // Add timeout
        );

        if (mounted) {
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
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startLocationTracking() {
    if (!_isTrackingLocation && _isLocationServiceEnabled) {
      setState(() {
        _isTrackingLocation = true;
      });

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(
            (Position position) {
          if (mounted) {
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
          }
        },
        onError: (error) {
          print('Location stream error: $error');
          if (mounted) {
            setState(() {
              _isTrackingLocation = false;
            });
          }
        },
      );
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
        } else {
          _showGeofenceAlert(geofence.name, "Exited", Colors.red);
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action geofence: $geofenceName'),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
    } else if (_isLocationServiceEnabled) {
      // Try to get location again
      _getCurrentLocation();
    }
  }

  void _startDrawingGeofence() {
    setState(() {
      _isDrawingGeofence = true;
      _currentGeofencePoints.clear();
      _isDragging = false;
      _draggedPointIndex = null;
    });
  }

  void _stopDrawingGeofence() {
    if (_currentGeofencePoints.length >= 3) {
      _showCreateGeofenceDialog();
    } else {
      setState(() {
        _isDrawingGeofence = false;
        _currentGeofencePoints.clear();
        _isDragging = false;
        _draggedPointIndex = null;
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
            const SizedBox(height: 8),
            const Text(
              'Tip: You can drag points to adjust the geofence shape',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDrawingGeofence = false;
                _currentGeofencePoints.clear();
                _isDragging = false;
                _draggedPointIndex = null;
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
      _isDragging = false;
      _draggedPointIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Geofence "$name" created successfully')),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingGeofence) {
      if (_isDragging && _draggedPointIndex != null) {
        // Move the dragged point to the tapped location
        setState(() {
          _currentGeofencePoints[_draggedPointIndex!] = point;
          _isDragging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Point ${_draggedPointIndex! + 1} moved to new position'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );

        _draggedPointIndex = null;
        _draggedPointOriginalPosition = null;
      } else {
        // Add new point
        setState(() {
          _currentGeofencePoints.add(point);
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Point ${_currentGeofencePoints.length} added. Long press on any point to move it.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Handle long press to start dragging a point
  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (_isDrawingGeofence && _currentGeofencePoints.isNotEmpty) {
      // Find the closest point to start dragging
      int closestPointIndex = _findClosestPoint(point);
      if (closestPointIndex != -1) {
        setState(() {
          _isDragging = true;
          _draggedPointIndex = closestPointIndex;
          _draggedPointOriginalPosition = _currentGeofencePoints[closestPointIndex];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tap on map to move point ${closestPointIndex + 1} to new position.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Cancel',
              onPressed: () {
                setState(() {
                  _isDragging = false;
                  _draggedPointIndex = null;
                  if (_draggedPointOriginalPosition != null) {
                    _currentGeofencePoints[closestPointIndex] = _draggedPointOriginalPosition!;
                  }
                });
              },
            ),
          ),
        );
      }
    }
  }

  // Find the closest point to the given location
  int _findClosestPoint(LatLng targetPoint) {
    if (_currentGeofencePoints.isEmpty) return -1;

    double minDistance = double.infinity;
    int closestIndex = -1;

    for (int i = 0; i < _currentGeofencePoints.length; i++) {
      double distance = _calculateDistance(targetPoint, _currentGeofencePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Only return the index if the point is reasonably close (within ~50 meters on screen)
    // This threshold might need adjustment based on zoom level
    if (minDistance < 0.0005) { // Roughly 50 meters at typical zoom levels
      return closestIndex;
    }

    return -1;
  }

  // Calculate distance between two LatLng points
  double _calculateDistance(LatLng point1, LatLng point2) {
    double dx = point1.latitude - point2.latitude;
    double dy = point1.longitude - point2.longitude;
    return dx * dx + dy * dy; // Squared distance is sufficient for comparison
  }

  // Remove a point with double tap
  void _removePoint(int index) {
    if (_currentGeofencePoints.length > 3) { // Keep at least 3 points
      setState(() {
        _currentGeofencePoints.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Point ${index + 1} removed'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Simple undo - add point back (would need more sophisticated undo for exact position)
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence must have at least 3 points'),
          backgroundColor: Colors.orange,
        ),
      );
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

  // Manual refresh function
  Future<void> _refreshLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    await _checkLocationService();
    if (_isLocationServiceEnabled) {
      await _getCurrentLocation();
      if (_currentPosition != null && !_isTrackingLocation) {
        _startLocationTracking();
      }
    }

    setState(() {
      _isGettingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(),
          // Messages screen - will be replaced with ConnectionsScreen
          const ConnectionsScreen(),
          // Notifications screen placeholder
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Location alerts and notifications will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const ProfileScreen(),
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
              icon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
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
              Expanded(
                child: Column(
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
              ),
              IconButton(
                onPressed: _showGeofencesList,
                icon: Icon(
                  Icons.layers,
                  color: Colors.grey.shade700,
                ),
              ),
              // Add refresh button
              IconButton(
                onPressed: _isGettingLocation ? null : _refreshLocation,
                icon: Icon(
                  Icons.refresh,
                  color: _isGettingLocation ? Colors.grey : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Drawing instructions
        if (_isDrawingGeofence)
          Container(
            padding: const EdgeInsets.all(16),
            color: _isDragging ? Colors.orange.shade200 : Colors.orange.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                        _isDragging ? Icons.touch_app : Icons.info,
                        color: Colors.orange.shade800
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isDragging
                            ? 'Moving point ${_draggedPointIndex! + 1}. Tap anywhere on map to place it.'
                            : 'Tap to add points • Long press near a point to move it',
                      ),
                    ),
                    if (_isDragging)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isDragging = false;
                            if (_draggedPointOriginalPosition != null && _draggedPointIndex != null) {
                              _currentGeofencePoints[_draggedPointIndex!] = _draggedPointOriginalPosition!;
                            }
                            _draggedPointIndex = null;
                            _draggedPointOriginalPosition = null;
                          });
                        },
                        child: const Text('Cancel'),
                      )
                    else
                      TextButton(
                        onPressed: _stopDrawingGeofence,
                        child: const Text('Finish'),
                      ),
                  ],
                ),
                if (_currentGeofencePoints.isNotEmpty && !_isDragging)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_currentGeofencePoints.length} points added • ${_currentGeofencePoints.length >= 3 ? "Ready to create!" : "Need ${3 - _currentGeofencePoints.length} more point(s)"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                  // Flutter Map with simplified gesture handling
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
                      onLongPress: _onMapLongPress,
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
                              borderColor: _isDragging ? Colors.orange.shade700 : Colors.orange,
                              borderStrokeWidth: _isDragging ? 3.0 : 2.0,
                            ),
                        ],
                      ),

                      // Geofence markers for drawing with enhanced visuals
                      if (_currentGeofencePoints.isNotEmpty)
                        MarkerLayer(
                          markers: _currentGeofencePoints
                              .asMap()
                              .entries
                              .map((entry) => Marker(
                            point: entry.value,
                            width: _draggedPointIndex == entry.key ? 28 : 24,
                            height: _draggedPointIndex == entry.key ? 28 : 24,
                            builder: (context) => Container(
                              width: _draggedPointIndex == entry.key ? 28 : 24,
                              height: _draggedPointIndex == entry.key ? 28 : 24,
                              decoration: BoxDecoration(
                                color: _draggedPointIndex == entry.key
                                    ? Colors.orange.shade700
                                    : Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white,
                                    width: _draggedPointIndex == entry.key ? 3 : 2
                                ),
                                boxShadow: [
                                  if (_draggedPointIndex == entry.key)
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _draggedPointIndex == entry.key ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ))
                              .toList(),
                        ),

                      // Connection lines between points (when drawing)
                      if (_currentGeofencePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _currentGeofencePoints,
                              strokeWidth: _isDragging ? 3.0 : 2.0,
                              color: (_isDragging ? Colors.orange.shade700 : Colors.orange).withOpacity(0.8),
                            ),
                          ],
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

                      // Current Location Marker with accuracy circle
                      if (_currentPosition != null)
                        CircleLayer(
                          circles: [
                            // Accuracy circle
                            CircleMarker(
                              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              radius: _currentPosition!.accuracy,
                              useRadiusInMeter: true,
                              color: Colors.blue.withOpacity(0.1),
                              borderColor: Colors.blue.withOpacity(0.3),
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),

                      // Current Location Marker
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              width: 40,
                              height: 40,
                              builder: (context) => Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.shade600,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Direction indicator (if speed > 1 m/s)
                            if (_currentPosition!.speed > 1.0)
                              Marker(
                                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                width: 60,
                                height: 60,
                                builder: (context) => Transform.rotate(
                                  angle: (_currentPosition!.heading * 3.141592653589793) / 180,
                                  child: Icon(
                                    Icons.navigation,
                                    color: Colors.blue.shade700,
                                    size: 30,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(1, 1),
                                        blurRadius: 2,
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
                        // Clear current geofence button (only when drawing)
                        if (_isDrawingGeofence && _currentGeofencePoints.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "clear_geofence",
                            onPressed: () {
                              setState(() {
                                _currentGeofencePoints.clear();
                                _isDragging = false;
                                _draggedPointIndex = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Geofence points cleared'),
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            },
                            backgroundColor: Colors.red.shade100,
                            child: const Icon(Icons.clear, color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Enhanced location info overlay
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
                            if (_isDrawingGeofence) ...[
                              const Divider(height: 8),
                              Text(
                                'Drawing: ${_currentGeofencePoints.length} points',
                                style: const TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                              if (_isDragging)
                                Text(
                                  'Dragging point ${_draggedPointIndex! + 1}',
                                  style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Loading overlay for getting location
                  if (_isGettingLocation && _isLocationServiceEnabled)
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
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _refreshLocation,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Check Again'),
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
        const SizedBox(height: 20),
      ],
    );
  }
}