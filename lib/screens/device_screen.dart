import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/device_service.dart';
import '../services/geofence_service.dart';
import 'widgets/device_list_widget.dart';
import 'package:safe_spot/screens/widgets/map/device_map_widget.dart';
import 'widgets/device_stats_widget.dart';
import 'widgets/add_device_form_widget.dart';
import 'widgets/device_geofence_overlay.dart';
import '../utils/device_utils.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final MapController _mapController = MapController();

  // Device controllers
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();

  // Device state variables
  List<Device> _devices = [];
  Map<String, List<LocationHistory>> _deviceLocations = {};
  bool _isLoading = false;
  bool _isAddingDevice = false;
  String? _selectedDeviceId;

  // Location state variables
  Position? _currentPosition;
  bool _isLocationServiceEnabled = false;
  bool _isGettingLocation = false;

  // Geofence state variables
  List<Geofence> _geofences = [];
  bool _isDrawingGeofence = false;
  List<LatLng> _currentGeofencePoints = [];
  final TextEditingController _geofenceNameController = TextEditingController();
  bool _isLoadingGeofences = false;
  bool _isSavingGeofence = false;
  bool _isDragging = false;
  int? _draggedPointIndex;
  LatLng? _draggedPointOriginalPosition;

  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocation();
    _loadDevices();
    _loadGeofences();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _tabController.dispose();
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    _geofenceNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reinitializeLocation();
    }
  }

  // Location methods
  Future<void> _reinitializeLocation() async {
    bool wasLocationEnabled = _isLocationServiceEnabled;
    await _checkLocationService();
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

  // Device methods
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted && DeviceService.isAuthenticated) {
        _loadDeviceLocationsOnly();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _loadDeviceLocationsOnly() async {
    if (!DeviceService.isAuthenticated) return;

    try {
      for (var device in _devices) {
        final history = await DeviceService.getDeviceLocationHistory(
          deviceId: device.deviceId,
          limit: 100,
        );
        if (mounted) {
          setState(() {
            _deviceLocations[device.deviceId] = history;
          });
        }
      }
    } catch (e) {
      print('Error refreshing location data: $e');
    }
  }

  Future<void> _loadDevices() async {
    if (!DeviceService.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final devices = await DeviceService.getUserDevices();
      setState(() => _devices = devices);

      for (var device in devices) {
        await _loadDeviceLocationHistory(device.deviceId);
      }

      _stopAutoRefresh();
      _startAutoRefresh();
    } catch (e) {
      print('Error loading devices: $e');
      if (mounted) {
        DeviceUtils.showErrorSnackBar(context, 'Failed to load devices: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeviceLocationHistory(String deviceId) async {
    try {
      final history = await DeviceService.getDeviceLocationHistory(
        deviceId: deviceId,
      );
      if (mounted) {
        setState(() {
          _deviceLocations[deviceId] = history;
        });
      }
    } catch (e) {
      print('Failed to load location history for $deviceId: $e');
    }
  }

  // Show Add Device Modal
  void _showAddDeviceModal() {
    _deviceIdController.clear();
    _deviceNameController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Modal handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: AddDeviceFormWidget(
                        deviceIdController: _deviceIdController,
                        deviceNameController: _deviceNameController,
                        isAddingDevice: _isAddingDevice,
                        onAddDevice: () async {
                          setModalState(() => _isAddingDevice = true);
                          await _addDevice();
                          setModalState(() => _isAddingDevice = false);
                          if (mounted && !_isAddingDevice) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addDevice() async {
    final deviceId = _deviceIdController.text.trim();
    final deviceName = _deviceNameController.text.trim();

    if (deviceId.isEmpty || deviceName.isEmpty) {
      DeviceUtils.showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    setState(() => _isAddingDevice = true);
    try {
      await DeviceService.addDevice(deviceId: deviceId, deviceName: deviceName);

      DeviceUtils.showSuccessSnackBar(context, 'Device "$deviceName" added successfully');
      _deviceIdController.clear();
      _deviceNameController.clear();
      await _loadDevices();
    } catch (e) {
      DeviceUtils.showErrorSnackBar(context, 'Failed to add device: $e');
    } finally {
      if (mounted) setState(() => _isAddingDevice = false);
    }
  }

  Future<void> _deleteDevice(Device device) async {
    final confirmed = await DeviceUtils.showDeleteConfirmation(context, device.deviceName);
    if (confirmed == true) {
      try {
        await DeviceService.deleteDevice(device.id);
        DeviceUtils.showSuccessSnackBar(context, 'Device deleted successfully');
        await _loadDevices();
      } catch (e) {
        DeviceUtils.showErrorSnackBar(context, 'Failed to delete device: $e');
      }
    }
  }

  void _centerMapOnDevice(String deviceId) {
    final locations = _deviceLocations[deviceId];
    if (locations != null && locations.isNotEmpty) {
      final latestLocation = locations.first;
      _mapController.move(
        LatLng(latestLocation.latitude, latestLocation.longitude),
        15.0,
      );
      setState(() {
        _selectedDeviceId = deviceId;
      });
      _tabController.animateTo(1);
    }
  }

  Device? _findDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  // Geofence methods
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
      final points = _currentGeofencePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();

      final color = GeofenceUtils.getRandomColor(_geofences.length);
      final colorHex = '#${color.value.toRadixString(16).substring(2)}';

      final geofenceData = await GeofenceService.createGeofence(
        name: name,
        points: points,
        color: colorHex,
      );

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!DeviceService.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                'Authentication Required',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to manage devices',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        title: Row(
          children: [
            // App Logo
            Image.asset(
              'assets/app1_icon.png',
              height: 50,
              width: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            // App Name
            Text(
              'SafeSpot',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Devices', icon: Icon(Icons.devices)),
                Tab(text: 'Map View', icon: Icon(Icons.map)),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDevicesTab(),
          _buildMapTab(),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Stats widget with full width
        Container(
          padding: const EdgeInsets.all(16),
          child: DeviceStatsWidget(
            devices: _devices,
            deviceLocations: _deviceLocations,
            geofences: _geofences,
          ),
        ),

        // Add device button below stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddDeviceModal,
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Devices list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDevices,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                    ? _buildEmptyState()
                    : DeviceListWidget(
                        devices: _devices,
                        deviceLocations: _deviceLocations,
                        onDeleteDevice: _deleteDevice,
                        onCenterMapOnDevice: _centerMapOnDevice,
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        DeviceMapWidget(
          mapController: _mapController,
          devices: _devices,
          deviceLocations: _deviceLocations,
          selectedDeviceId: _selectedDeviceId,
          currentPosition: _currentPosition,
          geofences: _geofences,
          currentGeofencePoints: _currentGeofencePoints,
          isDrawingGeofence: _isDrawingGeofence,
          isDragging: _isDragging,
          draggedPointIndex: _draggedPointIndex,
          onDeviceSelected: (deviceId) {
            setState(() {
              _selectedDeviceId = deviceId;
            });
          },
          onCenterMapOnDevice: _centerMapOnDevice,
          onCenterMapOnCurrentLocation: _centerMapOnCurrentLocation,
          onMapTap: _onMapTap,
          onMapLongPress: _onMapLongPress,
          findDeviceById: _findDeviceById,
        ),
        DeviceGeofenceOverlay(
          isDrawingGeofence: _isDrawingGeofence,
          isDragging: _isDragging,
          draggedPointIndex: _draggedPointIndex,
          currentGeofencePoints: _currentGeofencePoints,
          geofences: _geofences,
          isLoadingGeofences: _isLoadingGeofences,
          onStartDrawing: _startDrawingGeofence,
          onStopDrawing: _stopDrawingGeofence,
          onClearPoints: () {
            setState(() {
              _currentGeofencePoints.clear();
              _isDragging = false;
              _draggedPointIndex = null;
            });
          },
          onLoadGeofences: _loadGeofences,
          onToggleGeofenceStatus: _toggleGeofenceStatus,
          onDeleteGeofence: _deleteGeofence,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.devices_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No devices added yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first device to start tracking its location',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddDeviceModal,
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}