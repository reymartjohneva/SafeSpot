import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async'; // Add this import
import '../services/device_service.dart';

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

  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30); // Refresh every 30 seconds

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDevices();
    _startAutoRefresh(); // Start auto-refresh
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer when disposing
    _tabController.dispose();
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted && DeviceService.isAuthenticated) {
        _loadDeviceLocationsOnly(); // Only refresh location data, not device list
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // New method to only refresh location data (faster than full reload)
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
      // Don't show snackbar for background refresh errors
    }
  }

  Future<void> _loadDevices() async {
    if (!DeviceService.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final devices = await DeviceService.getUserDevices();
      setState(() => _devices = devices);

      // Load location history for each device
      for (var device in devices) {
        await _loadDeviceLocationHistory(device.deviceId);
      }
      
      // Restart auto-refresh after loading
      _stopAutoRefresh();
      _startAutoRefresh();
    } catch (e) {
      print('Error loading devices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devices: $e')),
        );
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
      // Don't show error for location history as it's optional
    }
  }

  Future<void> _addDevice() async {
    final deviceId = _deviceIdController.text.trim();
    final deviceName = _deviceNameController.text.trim();

    if (deviceId.isEmpty || deviceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isAddingDevice = true);
    try {
      await DeviceService.addDevice(deviceId: deviceId, deviceName: deviceName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device "$deviceName" added successfully')),
      );

      _deviceIdController.clear();
      _deviceNameController.clear();
      await _loadDevices(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingDevice = false);
    }
  }

  Future<void> _deleteDevice(Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Device'),
            content: Text(
              'Are you sure you want to delete "${device.deviceName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await DeviceService.deleteDevice(device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device deleted successfully')),
        );
        await _loadDevices();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete device: $e')));
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
      _tabController.animateTo(1); // Switch to map tab
    }
  }

  // Safe method to find device by ID
  Device? _findDeviceById(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!DeviceService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Tracking')),
        body: const Center(child: Text('Please log in to manage devices')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Map View', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDevicesTab(), _buildMapTab()],
      ),
    );
  }

  Widget _buildDevicesTab() {
    return Column(
      children: [
        // Add device section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Device',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  hintText: 'Enter unique device identifier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.perm_device_information),
                ),
                enabled: !_isAddingDevice,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'Enter a friendly name for this device',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                enabled: !_isAddingDevice,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAddingDevice ? null : _addDevice,
                  child:
                      _isAddingDevice
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Adding Device...'),
                            ],
                          )
                          : const Text('Add Device'),
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // Devices list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDevices,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _devices.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No devices added yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Add a device to start tracking its location',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final locations =
                            _deviceLocations[device.deviceId] ?? [];
                        final latestLocation =
                            locations.isNotEmpty ? locations.first : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  device.isActive
                                      ? (latestLocation != null
                                          ? Colors.green
                                          : Colors.orange)
                                      : Colors.grey,
                              child: const Icon(
                                Icons.phone_android,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(device.deviceName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${device.deviceId}'),
                                Text('Added: ${_formatDate(device.createdAt)}'),
                                if (latestLocation != null)
                                  Text(
                                    'Last seen: ${_formatDate(latestLocation.createdAt)}',
                                    style: const TextStyle(color: Colors.green),
                                  )
                                else
                                  const Text(
                                    'No location data',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (latestLocation != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () =>
                                            _centerMapOnDevice(device.deviceId),
                                    tooltip: 'View on map',
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      _deleteDevice(device);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: LatLng(8.9511, 125.5439), // Default center
            zoom: 13.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.safespot',
            ),

            // Location history lines (polylines) for each device
            PolylineLayer(
              polylines:
                  _deviceLocations.entries
                      .where((entry) => entry.value.length > 1)
                      .map((entry) {
                        final deviceId = entry.key;
                        final locations = entry.value;
                        final device = _findDeviceById(deviceId);

                        if (device == null) return null;

                        final isSelected =
                            _selectedDeviceId == null ||
                            _selectedDeviceId == deviceId;

                        if (!isSelected) return null;

                        final points =
                            locations.reversed
                                .map(
                                  (location) => LatLng(
                                    location.latitude,
                                    location.longitude,
                                  ),
                                )
                                .toList();

                        return Polyline(
                          points: points,
                          strokeWidth:
                              isSelected && _selectedDeviceId == deviceId
                                  ? 3.0
                                  : 2.0,
                          color: _getDeviceColor(
                            device.deviceId,
                          ).withOpacity(0.7),
                        );
                      })
                      .where((polyline) => polyline != null)
                      .cast<Polyline>()
                      .toList(),
            ),

            // Historical location markers (small dots)
            MarkerLayer(
              markers:
                  _deviceLocations.entries.expand((entry) {
                    final deviceId = entry.key;
                    final locations = entry.value;
                    final device = _findDeviceById(deviceId);

                    if (device == null) return <Marker>[];

                    final isSelected =
                        _selectedDeviceId == null ||
                        _selectedDeviceId == deviceId;

                    if (!isSelected || locations.isEmpty) return <Marker>[];

                    final locationsList = locations.skip(1).toList();
                    return locationsList.map((location) {
                      return Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 12,
                        height: 12,
                        builder:
                            (context) => Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getDeviceColor(device.deviceId),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      );
                    }).toList();
                  }).toList(),
            ),

            // Latest location markers (bigger, with device info)
            MarkerLayer(
              markers:
                  _deviceLocations.entries.expand((entry) {
                    final deviceId = entry.key;
                    final locations = entry.value;
                    if (locations.isEmpty) return <Marker>[];

                    final device = _findDeviceById(deviceId);
                    if (device == null) return <Marker>[];

                    final latestLocation = locations.first;
                    final isSelected = _selectedDeviceId == deviceId;
                    final isVisible =
                        _selectedDeviceId == null ||
                        _selectedDeviceId == deviceId;

                    if (!isVisible) return <Marker>[];

                    return [
                      Marker(
                        point: LatLng(
                          latestLocation.latitude,
                          latestLocation.longitude,
                        ),
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        builder:
                            (context) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDeviceId =
                                      _selectedDeviceId == deviceId
                                          ? null
                                          : deviceId;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getDeviceColor(device.deviceId),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.yellow
                                            : Colors.white,
                                    width: isSelected ? 4 : 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: isSelected ? 8 : 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      device.isActive
                                          ? Icons.phone_android
                                          : Icons.phone_android_outlined,
                                      color: Colors.white,
                                      size: isSelected ? 20 : 16,
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        device.deviceName.length > 8
                                            ? '${device.deviceName.substring(0, 8)}...'
                                            : device.deviceName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ] else
                                      Text(
                                        device.deviceName.isNotEmpty
                                            ? device.deviceName
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ];
                  }).toList(),
            ),

            // Device info popup for selected device
            if (_selectedDeviceId != null &&
                _deviceLocations[_selectedDeviceId]?.isNotEmpty == true)
              MarkerLayer(
                markers:
                    [
                      () {
                        final locations = _deviceLocations[_selectedDeviceId]!;
                        final device = _findDeviceById(_selectedDeviceId!);
                        if (device == null) return null;

                        final latestLocation = locations.first;

                        return Marker(
                          point: LatLng(
                            latestLocation.latitude,
                            latestLocation.longitude,
                          ),
                          width: 200,
                          height: 100,
                          builder:
                              (context) => Transform.translate(
                                offset: const Offset(0, -80),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getDeviceColor(device.deviceId),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        device.deviceName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${device.deviceId}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        'Last seen: ${_formatDate(latestLocation.createdAt)}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        'History: ${locations.length} points',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        'Status: ${device.isActive ? "Active" : "Inactive"}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color:
                                              device.isActive
                                                  ? Colors.green
                                                  : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      }(),
                    ].where((marker) => marker != null).cast<Marker>().toList(),
              ),
          ],
        ),

        // Device selector
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<String>(
              value: _selectedDeviceId,
              hint: const Text('Select device to view'),
              isExpanded: true,
              underline: Container(),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All devices'),
                ),
                ..._devices.map(
                  (device) => DropdownMenuItem<String>(
                    value: device.deviceId,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getDeviceColor(device.deviceId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(device.deviceName)),
                        Text(
                          '(${_deviceLocations[device.deviceId]?.length ?? 0})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (deviceId) {
                setState(() {
                  _selectedDeviceId = deviceId;
                });
                if (deviceId != null) {
                  _centerMapOnDevice(deviceId);
                }
              },
            ),
          ),
        ),

        // Legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Legend',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('History', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Latest', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 2, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text('Path', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Format: DD/MM/YYYY HH:MM:SS
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  // Alternative: 12-hour format with AM/PM
  String _formatDateWithAmPm(DateTime date) {
    final hour12 =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${hour12.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} $amPm';
  }

  // More user-friendly format that shows relative time for recent entries
  String _formatDateSmart(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // For older dates, show full format
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getDeviceColor(String deviceId) {
    final hash = deviceId.hashCode;
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }
}
