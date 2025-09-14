import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../services/device_service.dart';
import 'widgets/device_list_widget.dart';
import 'widgets/device_map_widget.dart';
import 'widgets/device_stats_widget.dart';
import 'widgets/add_device_form_widget.dart';
import '../utils/device_utils.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  // Controllers
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();

  // State variables
  List<Device> _devices = [];
  Map<String, List<LocationHistory>> _deviceLocations = {};
  bool _isLoading = false;
  bool _isAddingDevice = false;
  String? _selectedDeviceId;
  bool _showAddDeviceForm = false;

  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDevices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

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
      setState(() => _showAddDeviceForm = false);
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
        title: Text(
          'Device Tracking',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
          DeviceMapWidget(
            mapController: _mapController,
            devices: _devices,
            deviceLocations: _deviceLocations,
            selectedDeviceId: _selectedDeviceId,
            onDeviceSelected: (deviceId) {
              setState(() {
                _selectedDeviceId = deviceId;
              });
            },
            onCenterMapOnDevice: _centerMapOnDevice,
            findDeviceById: _findDeviceById,
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header with stats and add button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DeviceStatsWidget(
                  devices: _devices,
                  deviceLocations: _deviceLocations,
                ),
              ),
              const SizedBox(width: 16),
              FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _showAddDeviceForm = !_showAddDeviceForm;
                  });
                },
                icon: Icon(_showAddDeviceForm ? Icons.close : Icons.add),
                label: Text(_showAddDeviceForm ? 'Cancel' : 'Add Device'),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ),

        // Add device form (collapsible)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showAddDeviceForm ? null : 0,
          child: _showAddDeviceForm 
              ? AddDeviceFormWidget(
                  deviceIdController: _deviceIdController,
                  deviceNameController: _deviceNameController,
                  isAddingDevice: _isAddingDevice,
                  onAddDevice: _addDevice,
                )
              : null,
        ),

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
            onPressed: () {
              setState(() {
                _showAddDeviceForm = true;
              });
            },
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