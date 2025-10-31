import 'package:flutter/material.dart';
import 'package:safe_spot/services/geofence_monitor_service.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/geofence_service.dart';

class GeofenceDebugScreen extends StatefulWidget {
  const GeofenceDebugScreen({Key? key}) : super(key: key);

  @override
  State<GeofenceDebugScreen> createState() => _GeofenceDebugScreenState();
}

class _GeofenceDebugScreenState extends State<GeofenceDebugScreen> {
  List<Device> _devices = [];
  Map<String, GeofenceState> _states = {};
  bool _isLoading = false;
  String _statusMessage = 'Ready';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await DeviceService.getUserDevices();
      setState(() {
        _devices = devices;
        _statusMessage = 'Loaded ${devices.length} devices';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error loading devices: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStates() async {
    setState(() => _isLoading = true);
    try {
      final allStates = <String, GeofenceState>{};
      for (final device in _devices) {
        final states = GeofenceMonitorService.getDeviceStates(device.deviceId);
        allStates.addAll(states);
      }
      setState(() {
        _states = allStates;
        _statusMessage = 'Found ${allStates.length} tracked states';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Error loading states: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _manualCheckDevice(String deviceId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking device $deviceId...';
    });

    try {
      await GeofenceMonitorService.manualCheckDevice(deviceId);
      await _refreshStates();
      setState(() => _statusMessage = 'Manual check completed for $deviceId');
    } catch (e) {
      setState(() => _statusMessage = 'Manual check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recheckAll() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Rechecking all devices...';
    });

    try {
      await GeofenceMonitorService.recheckAllDevices();
      await _refreshStates();
      setState(() => _statusMessage = 'All devices rechecked');
    } catch (e) {
      setState(() => _statusMessage = 'Recheck failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetStates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset All States'),
            content: const Text(
              'This will clear all tracked geofence states. The next location update will be treated as the initial state.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      GeofenceMonitorService.clearAllStates();
      await _refreshStates();
      setState(() => _statusMessage = 'All states cleared');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('States reset. Next location will be initial state.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Geofence Debug'),
        backgroundColor: const Color(0xFF2D2D2D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStates,
            tooltip: 'Refresh States',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _recheckAll,
            tooltip: 'Recheck All',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _resetStates,
            tooltip: 'Reset States',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildStatusBar(),
                  _buildQuickActions(),
                  Expanded(child: _buildDeviceList()),
                  if (_states.isNotEmpty) _buildStatesSection(),
                ],
              ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2D2D2D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_devices.length} devices • ${_states.length} tracked states',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _recheckAll,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Recheck All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _resetStates,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Reset States'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _refreshStates,
                icon: const Icon(Icons.info, size: 18),
                label: const Text('View States'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) {
      return const Center(
        child: Text('No devices found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Card(
          color: const Color(0xFF2D2D2D),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.blue),
            title: Text(
              device.deviceName,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              device.deviceId,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _manualCheckDevice(device.deviceId),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Check'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatesSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tracked States (${_states.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _states.length,
              itemBuilder: (context, index) {
                final entry = _states.entries.elementAt(index);
                final state = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        state.isInside ? Icons.check_circle : Icons.cancel,
                        color: state.isInside ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              state.isInside ? 'INSIDE' : 'OUTSIDE',
                              style: TextStyle(
                                color:
                                    state.isInside ? Colors.green : Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(state.lastUpdate),
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
