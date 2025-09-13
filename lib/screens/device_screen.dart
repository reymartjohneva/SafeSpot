import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDevices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    if (!DeviceService.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final devices = await DeviceService.getUserDevices();
      setState(() => _devices = devices);

      // Load location history for each device
      for (var device in devices) {
        _loadDeviceLocationHistory(device.deviceId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load devices: $e')));
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
      _loadDevices(); // Refresh the list
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
        _loadDevices();
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
      final latestLocation =
          locations.first; // First is most recent due to DESC order
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
                        final locations = _deviceLocations[device.deviceId];
                        final latestLocation =
                            locations?.isNotEmpty == true
                                ? locations!.first
                                : null;

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
                              child: Icon(
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

            // Device location markers
            MarkerLayer(
              markers:
                  _deviceLocations.entries.expand((entry) {
                    final deviceId = entry.key;
                    final locations = entry.value;
                    if (locations.isEmpty) return <Marker>[];

                    final device = _devices.firstWhere(
                      (d) => d.deviceId == deviceId,
                    );
                    final latestLocation = locations.first;
                    final isSelected = _selectedDeviceId == deviceId;

                    return [
                      Marker(
                        point: LatLng(
                          latestLocation.latitude,
                          latestLocation.longitude,
                        ),
                        width: isSelected ? 50 : 40,
                        height: isSelected ? 50 : 40,
                        builder:
                            (context) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    device.isActive ? Colors.blue : Colors.grey,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  device.deviceName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSelected ? 16 : 14,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ];
                  }).toList(),
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
                    child: Text(device.deviceName),
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
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
