import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
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
        _showErrorSnackBar('Failed to load devices: $e');
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
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isAddingDevice = true);
    try {
      await DeviceService.addDevice(deviceId: deviceId, deviceName: deviceName);

      _showSuccessSnackBar('Device "$deviceName" added successfully');
      _deviceIdController.clear();
      _deviceNameController.clear();
      setState(() => _showAddDeviceForm = false);
      await _loadDevices();
    } catch (e) {
      _showErrorSnackBar('Failed to add device: $e');
    } finally {
      if (mounted) setState(() => _isAddingDevice = false);
    }
  }

  Future<void> _deleteDevice(Device device) async {
    final confirmed = await _showDeleteConfirmation(device.deviceName);
    if (confirmed == true) {
      try {
        await DeviceService.deleteDevice(device.id);
        _showSuccessSnackBar('Device deleted successfully');
        await _loadDevices();
      } catch (e) {
        _showErrorSnackBar('Failed to delete device: $e');
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String deviceName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Device'),
          ],
        ),
        content: Text('Are you sure you want to delete "$deviceName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        children: [_buildDevicesTab(), _buildMapTab()],
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
                child: _buildStatsCard(),
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
          child: _showAddDeviceForm ? _buildAddDeviceForm() : null,
        ),

        // Devices list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDevices,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                    ? _buildEmptyState()
                    : _buildDevicesList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    final activeDevices = _devices.where((d) => d.isActive).length;
    final devicesWithLocation = _devices.where((d) => 
        _deviceLocations[d.deviceId]?.isNotEmpty == true).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem('Total', _devices.length.toString(), Icons.devices),
              const SizedBox(width: 16),
              _buildStatItem('Active', activeDevices.toString(), Icons.radio_button_checked),
              const SizedBox(width: 16),
              _buildStatItem('Located', devicesWithLocation.toString(), Icons.location_on),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAddDeviceForm() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Device',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _deviceIdController,
            enabled: !_isAddingDevice,
            decoration: InputDecoration(
              labelText: 'Device ID',
              hintText: 'Enter unique device identifier',
              prefixIcon: const Icon(Icons.perm_device_information),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _deviceNameController,
            enabled: !_isAddingDevice,
            decoration: InputDecoration(
              labelText: 'Device Name',
              hintText: 'Enter a friendly name for this device',
              prefixIcon: const Icon(Icons.label),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAddingDevice ? null : _addDevice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isAddingDevice
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Adding Device...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Add Device'),
                      ],
                    ),
            ),
          ),
        ],
      ),
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

  Widget _buildDevicesList() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final locations = _deviceLocations[device.deviceId] ?? [];
        final latestLocation = locations.isNotEmpty ? locations.first : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(16),
            shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getDeviceColor(device.deviceId),
                                _getDeviceColor(device.deviceId).withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getDeviceColor(device.deviceId).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            device.isActive ? Icons.smartphone : Icons.smartphone_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.deviceName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildStatusChip(device.isActive, latestLocation != null),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${device.deviceId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteDevice(device);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDeviceDetails(device, latestLocation, locations, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool isActive, bool hasLocation) {
    final theme = Theme.of(context);
    Color chipColor;
    String text;
    IconData icon;

    if (isActive && hasLocation) {
      chipColor = Colors.green;
      text = 'Online';
      icon = Icons.radio_button_checked;
    } else if (isActive && !hasLocation) {
      chipColor = Colors.orange;
      text = 'No GPS';
      icon = Icons.gps_off;
    } else {
      chipColor = Colors.grey;
      text = 'Offline';
      icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDetails(Device device, LocationHistory? latestLocation, 
      List<LocationHistory> locations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.access_time,
            'Added',
            _formatDateSmart(device.createdAt),
            theme,
          ),
          if (latestLocation != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_history,
              'Last seen',
              _formatDateSmart(latestLocation.createdAt),
              theme,
            ),
            if (latestLocation.speed != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.speed,
                'Speed',
                _formatSpeed(latestLocation.speed!),
                theme,
                valueColor: _getSpeedColor(latestLocation.speed),
              ),
            ],
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.timeline,
              'History',
              '${locations.length} points',
              theme,
            ),
          ] else
            _buildDetailRow(
              Icons.location_disabled,
              'Status',
              'No location data available',
              theme,
              valueColor: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, 
      ThemeData theme, {Color? valueColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(8.9511, 125.5439),
                zoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safespot',
                ),
                // Location history lines
                PolylineLayer(
                  polylines: _deviceLocations.entries
                      .where((entry) => entry.value.length > 1)
                      .map((entry) {
                        final deviceId = entry.key;
                        final locations = entry.value;
                        final device = _findDeviceById(deviceId);

                        if (device == null) return null;

                        final isSelected = _selectedDeviceId == null ||
                            _selectedDeviceId == deviceId;

                        if (!isSelected) return null;

                        final points = locations.reversed
                            .map((location) => LatLng(
                                location.latitude, location.longitude))
                            .toList();

                        return Polyline(
                          points: points,
                          strokeWidth: isSelected && _selectedDeviceId == deviceId
                              ? 3.0
                              : 2.0,
                          color: _getDeviceColor(device.deviceId).withOpacity(0.7),
                        );
                      })
                      .where((polyline) => polyline != null)
                      .cast<Polyline>()
                      .toList(),
                ),
                // Historical markers
                MarkerLayer(
                  markers: _deviceLocations.entries.expand((entry) {
                    final deviceId = entry.key;
                    final locations = entry.value;
                    if (locations.isEmpty) return <Marker>[];

                    final device = _findDeviceById(deviceId);
                    if (device == null) return <Marker>[];

                    final isSelected = _selectedDeviceId == null ||
                        _selectedDeviceId == deviceId;

                    if (!isSelected || locations.length <= 1) return <Marker>[];

                    final locationsList = locations.skip(1).toList();
                    return locationsList.map((location) {
                      return Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 12,
                        height: 12,
                        builder: (context) => Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getDeviceColor(device.deviceId),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  }).toList(),
                ),

                // Latest location markers
                MarkerLayer(
                  markers: _deviceLocations.entries.expand((entry) {
                    final deviceId = entry.key;
                    final locations = entry.value;
                    if (locations.isEmpty) return <Marker>[];

                    final device = _findDeviceById(deviceId);
                    if (device == null) return <Marker>[];

                    final latestLocation = locations.first;
                    final isSelected = _selectedDeviceId == deviceId;
                    final isVisible = _selectedDeviceId == null ||
                        _selectedDeviceId == deviceId;

                    if (!isVisible) return <Marker>[];

                    return [
                      Marker(
                        point: LatLng(
                          latestLocation.latitude,
                          latestLocation.longitude,
                        ),
                        width: isSelected ? 70 : 60,
                        height: isSelected ? 70 : 60,
                        builder: (context) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDeviceId =
                                  _selectedDeviceId == deviceId ? null : deviceId;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  latestLocation.speed != null
                                      ? _getSpeedColor(latestLocation.speed)
                                      : _getDeviceColor(device.deviceId),
                                  (latestLocation.speed != null
                                          ? _getSpeedColor(latestLocation.speed)
                                          : _getDeviceColor(device.deviceId))
                                      .withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: isSelected ? Colors.yellow : Colors.white,
                                width: isSelected ? 4 : 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  device.isActive
                                      ? Icons.smartphone
                                      : Icons.smartphone_outlined,
                                  color: Colors.white,
                                  size: isSelected ? 24 : 20,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 2),
                                  Flexible(
                                    child: Text(
                                      device.deviceName.length > 8
                                          ? '${device.deviceName.substring(0, 8)}...'
                                          : device.deviceName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ];
                  }).toList(),
                ),

                // Device info popup
                if (_selectedDeviceId != null &&
                    _deviceLocations[_selectedDeviceId]?.isNotEmpty == true)
                  MarkerLayer(
                    markers: [
                      () {
                        final locations = _deviceLocations[_selectedDeviceId]!;
                        final device = _findDeviceById(_selectedDeviceId!);
                        if (device == null) return null;

                        final latestLocation = locations.first;
                        final theme = Theme.of(context);

                        return Marker(
                          point: LatLng(
                            latestLocation.latitude,
                            latestLocation.longitude,
                          ),
                          width: constraints.maxWidth > 300
                              ? 220
                              : constraints.maxWidth - 80,
                          height: 140,
                          builder: (context) => Transform.translate(
                            offset: const Offset(0, -120),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth - 80,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getDeviceColor(device.deviceId),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getDeviceColor(device.deviceId),
                                        ),
                                        child: const Icon(
                                          Icons.smartphone,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          device.deviceName,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Last seen',
                                    _formatDateSmart(latestLocation.createdAt),
                                    theme,
                                  ),
                                  if (latestLocation.speed != null)
                                    _buildInfoRow(
                                      Icons.speed,
                                      'Speed',
                                      _formatSpeed(latestLocation.speed!),
                                      theme,
                                      valueColor: _getSpeedColor(latestLocation.speed),
                                    ),
                                  _buildInfoRow(
                                    Icons.timeline,
                                    'History',
                                    '${locations.length} points',
                                    theme,
                                  ),
                                  _buildInfoRow(
                                    Icons.radio_button_checked,
                                    'Status',
                                    device.isActive ? 'Active' : 'Inactive',
                                    theme,
                                    valueColor: device.isActive ? Colors.green : Colors.orange,
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

            // Enhanced device selector
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDeviceId,
                        hint: const Text('Select device to view'),
                        isExpanded: true,
                        underline: Container(),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.visibility, size: 16),
                                SizedBox(width: 8),
                                Text('Show all devices'),
                              ],
                            ),
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
                                  Expanded(
                                    child: Text(
                                      device.deviceName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_deviceLocations[device.deviceId]?.length ?? 0}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 10),
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
                  ],
                ),
              ),
            ),

            // Enhanced legend with better design
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 400
                      ? 240
                      : constraints.maxWidth - 100,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Map Legend',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      Icons.radio_button_unchecked,
                      'Historical points',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      Icons.smartphone,
                      'Current location',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Movement path',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Speed indicators:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildSpeedLegend('< 5', Colors.red),
                        _buildSpeedLegend('5-30', Colors.orange),
                        _buildSpeedLegend('30-60', Colors.blue),
                        _buildSpeedLegend('> 60', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'km/h',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating action button for map controls
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      // Center map on all devices
                      if (_devices.isNotEmpty) {
                        final allPoints = <LatLng>[];
                        for (var device in _devices) {
                          final locations = _deviceLocations[device.deviceId];
                          if (locations != null && locations.isNotEmpty) {
                            allPoints.add(LatLng(
                              locations.first.latitude,
                              locations.first.longitude,
                            ));
                          }
                        }
                        if (allPoints.isNotEmpty) {
                          // Calculate bounds and fit map
                          double minLat = allPoints.first.latitude;
                          double maxLat = allPoints.first.latitude;
                          double minLng = allPoints.first.longitude;
                          double maxLng = allPoints.first.longitude;

                          for (var point in allPoints) {
                            minLat = minLat < point.latitude ? minLat : point.latitude;
                            maxLat = maxLat > point.latitude ? maxLat : point.latitude;
                            minLng = minLng < point.longitude ? minLng : point.longitude;
                            maxLng = maxLng > point.longitude ? maxLng : point.longitude;
                          }

                          _mapController.fitBounds(
                            LatLngBounds(
                              LatLng(minLat, minLng),
                              LatLng(maxLat, maxLng),
                            ),
                            options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
                          );
                        }
                      }
                    },
                    heroTag: "fit_bounds",
                    child: const Icon(Icons.fit_screen),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      _mapController.move(LatLng(8.9511, 125.5439), 13.0);
                    },
                    heroTag: "center_map",
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? theme.colorScheme.onSurface,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSpeedLegend(String range, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          range,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String _formatDateSmart(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatSpeed(double speedMps) {
    final speedKmh = speedMps * 3.6;
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  Color _getSpeedColor(double? speed) {
    if (speed == null) return Colors.grey;

    final speedKmh = speed * 3.6;

    if (speedKmh < 5) return Colors.red;
    if (speedKmh < 30) return Colors.orange;
    if (speedKmh < 60) return Colors.blue;
    return Colors.green;
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