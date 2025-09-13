import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_screen.dart';
import 'device_screen.dart';
import '../services/geofence_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final MapController _mapController = MapController();

  // Static location for marker display only (no tracking)
  Position? _currentPosition;
  bool _isLocationServiceEnabled = false;
  bool _isGettingLocation = false;

  // Geofence variables
  List<Geofence> _geofences = [];
  bool _isDrawingGeofence = false;
  List<LatLng> _currentGeofencePoints = [];
  final TextEditingController _geofenceNameController = TextEditingController();
  bool _isLoadingGeofences = false;
  bool _isSavingGeofence = false;

  // Drag functionality variables
  bool _isDragging = false;
  int? _draggedPointIndex;
  LatLng? _draggedPointOriginalPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocation();
    _loadGeofences();
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

  // Load geofences from Supabase
  Future<void> _loadGeofences() async {
    if (!GeofenceService.isAuthenticated) {
      print('User not authenticated, skipping geofence loading');
      return;
    }

    setState(() {
      _isLoadingGeofences = true;
    });

    try {
      final geofenceData = await GeofenceService.getUserGeofences();
      final geofences =
          geofenceData.map((data) => Geofence.fromSupabase(data)).toList();

      if (mounted) {
        setState(() {
          _geofences = geofences;
          _isLoadingGeofences = false;
        });
      }
    } catch (e) {
      print('Error loading geofences: $e');
      if (mounted) {
        setState(() {
          _isLoadingGeofences = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load geofences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reinitializeLocation() async {
    // Check if location service was enabled while app was in background
    bool wasLocationEnabled = _isLocationServiceEnabled;
    await _checkLocationService();

    // If location service was just enabled, get location once
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
        content: const Text(
          'Please enable location services to display your location marker.',
        ),
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
          timeLimit: const Duration(seconds: 10),
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
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

  void _centerMapOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    } else if (_isLocationServiceEnabled) {
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
            onPressed: _isSavingGeofence
                ? null
                : () async {
                    final name = _geofenceNameController.text.trim();
                    final validationError = GeofenceUtils.validateGeofence(
                      name,
                      _currentGeofencePoints,
                    );

                    if (validationError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(validationError),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await _createGeofence(name);
                    Navigator.pop(context);
                  },
            child: _isSavingGeofence
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGeofence(String name) async {
    if (!GeofenceService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to create geofences'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSavingGeofence = true;
    });

    try {
      // Convert LatLng points to the format expected by Supabase
      final points = _currentGeofencePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();

      final color = GeofenceUtils.getRandomColor(_geofences.length);
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      // Save to Supabase
      final geofenceData = await GeofenceService.createGeofence(
        name: name,
        points: points,
        color: colorHex,
      );

      // Create local geofence object
      final geofence = Geofence.fromSupabase(geofenceData);

      setState(() {
        _geofences.add(geofence);
        _isDrawingGeofence = false;
        _currentGeofencePoints.clear();
        _isDragging = false;
        _draggedPointIndex = null;
        _isSavingGeofence = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geofence "$name" created successfully')),
      );
    } catch (e) {
      setState(() {
        _isSavingGeofence = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create geofence: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingGeofence) {
      if (_isDragging && _draggedPointIndex != null) {
        setState(() {
          _currentGeofencePoints[_draggedPointIndex!] = point;
          _isDragging = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Point ${_draggedPointIndex! + 1} moved to new position',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );

        _draggedPointIndex = null;
        _draggedPointOriginalPosition = null;
      } else {
        setState(() {
          _currentGeofencePoints.add(point);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Point ${_currentGeofencePoints.length} added. Long press on any point to move it.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (_isDrawingGeofence && _currentGeofencePoints.isNotEmpty) {
      int closestPointIndex = GeofenceUtils.findClosestPointIndex(
        point,
        _currentGeofencePoints,
      );
      if (closestPointIndex != -1) {
        setState(() {
          _isDragging = true;
          _draggedPointIndex = closestPointIndex;
          _draggedPointOriginalPosition =
              _currentGeofencePoints[closestPointIndex];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tap on map to move point ${closestPointIndex + 1} to new position.',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Cancel',
              onPressed: () {
                setState(() {
                  _isDragging = false;
                  _draggedPointIndex = null;
                  if (_draggedPointOriginalPosition != null) {
                    _currentGeofencePoints[closestPointIndex] =
                        _draggedPointOriginalPosition!;
                  }
                });
              },
            ),
          ),
        );
      }
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_isLoadingGeofences)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      onPressed: _loadGeofences,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _geofences.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isLoadingGeofences
                                ? 'Loading geofences...'
                                : 'No geofences created yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          if (!_isLoadingGeofences) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tap the draw button to create your first geofence',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${geofence.points.length} points • ${geofence.isActive ? "Active" : "Inactive"}',
                                ),
                                Text(
                                  'Created: ${geofence.createdAt.day}/${geofence.createdAt.month}/${geofence.createdAt.year}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: geofence.isActive,
                                  onChanged: (value) async {
                                    await _toggleGeofenceStatus(
                                      geofence.id,
                                      value,
                                    );
                                  },
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await _deleteGeofence(
                                      geofence.id,
                                      index,
                                    );
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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

  Future<void> _toggleGeofenceStatus(String geofenceId, bool isActive) async {
    try {
      await GeofenceService.toggleGeofenceStatus(geofenceId, isActive);

      setState(() {
        final index = _geofences.indexWhere((g) => g.id == geofenceId);
        if (index != -1) {
          _geofences[index].isActive = isActive;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update geofence: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGeofence(String geofenceId, int index) async {
    try {
      await GeofenceService.deleteGeofence(geofenceId);

      setState(() {
        _geofences.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete geofence: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    await _checkLocationService();
    if (_isLocationServiceEnabled) {
      await _getCurrentLocation();
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
          const DeviceScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
          padding: const EdgeInsets.only(
            top: 50,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade100, Colors.red.shade100],
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
                icon: Icon(Icons.layers, color: Colors.grey.shade700),
              ),
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
                      color: Colors.orange.shade800,
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
                            if (_draggedPointOriginalPosition != null &&
                                _draggedPointIndex != null) {
                              _currentGeofencePoints[_draggedPointIndex!] =
                                  _draggedPointOriginalPosition!;
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
                  // Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : LatLng(8.9511, 125.5439),
                      zoom: 15.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      onTap: _onMapTap,
                      onLongPress: _onMapLongPress,
                    ),
                    children: [
                      // Tile Layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.safespot',
                      ),

                      // Geofences Polygons
                      PolygonLayer(
                        polygons: [
                          // Existing geofences
                          ..._geofences.map(
                            (geofence) => Polygon(
                              points: geofence.points,
                              color: geofence.color.withOpacity(0.2),
                              borderColor: geofence.color,
                              borderStrokeWidth: 2.0,
                            ),
                          ),
                          // Current drawing geofence
                          if (_currentGeofencePoints.length >= 3)
                            Polygon(
                              points: _currentGeofencePoints,
                              color: Colors.orange.withOpacity(0.2),
                              borderColor: _isDragging
                                  ? Colors.orange.shade700
                                  : Colors.orange,
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
                              .map(
                                (entry) => Marker(
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
                                        width: _draggedPointIndex == entry.key ? 3 : 2,
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
                                ),
                              )
                              .toList(),
                        ),

                      // Connection lines between points (when drawing)
                      if (_currentGeofencePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _currentGeofencePoints,
                              strokeWidth: _isDragging ? 3.0 : 2.0,
                              color: (_isDragging
                                      ? Colors.orange.shade700
                                      : Colors.orange)
                                  .withOpacity(0.8),
                            ),
                          ],
                        ),

                      // Current Location Marker with accuracy circle (static display only)
                      if (_currentPosition != null)
                        CircleLayer(
                          circles: [
                            // Accuracy circle
                            CircleMarker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              radius: _currentPosition!.accuracy,
                              useRadiusInMeter: true,
                              color: Colors.blue.withOpacity(0.1),
                              borderColor: Colors.blue.withOpacity(0.3),
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),

                      // Current Location Marker (static display only)
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 30,
                              height: 30,
                              builder: (context) => Container(
                                width: 30,
                                height: 30,
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
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
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
                          ],
                        ),
                    ],
                  ),

                  // Map controls (removed tracking toggle button)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "zoom_in",
                          onPressed: () {
                            var currentZoom = _mapController.zoom;
                            _mapController.move(
                              _mapController.center,
                              currentZoom + 1,
                            );
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.add, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "zoom_out",
                          onPressed: () {
                            var currentZoom = _mapController.zoom;
                            _mapController.move(
                              _mapController.center,
                              currentZoom - 1,
                            );
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.remove,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "my_location",
                          onPressed: _centerMapOnCurrentLocation,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "draw_geofence",
                          onPressed: _isDrawingGeofence
                              ? _stopDrawingGeofence
                              : _startDrawingGeofence,
                          backgroundColor: _isDrawingGeofence
                              ? Colors.orange.shade100
                              : Colors.white,
                          child: Icon(
                            _isDrawingGeofence ? Icons.stop : Icons.draw,
                            color: _isDrawingGeofence
                                ? Colors.orange
                                : Colors.black54,
                          ),
                        ),
                        // Clear current geofence button (only when drawing)
                        if (_isDrawingGeofence &&
                            _currentGeofencePoints.isNotEmpty) ...[
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

                  // Simplified info overlay (removed location-related info)
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
                            'Map Info',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Geofences: ${_geofences.length}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          if (_isDrawingGeofence) ...[
                            const Divider(height: 8),
                            Text(
                              'Drawing: ${_currentGeofencePoints.length} points',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                            if (_isDragging)
                              Text(
                                'Dragging point ${_draggedPointIndex! + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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