import 'package:flutter/material.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/device_utils.dart';

class DeviceListWidget extends StatefulWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final Function(Device) onDeleteDevice;
  final Function(String) onCenterMapOnDevice;

  const DeviceListWidget({
    Key? key,
    required this.devices,
    required this.deviceLocations,
    required this.onDeleteDevice,
    required this.onCenterMapOnDevice,
  }) : super(key: key);

  @override
  State<DeviceListWidget> createState() => _DeviceListWidgetState();
}

class _DeviceListWidgetState extends State<DeviceListWidget> {
  String? expandedDeviceId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.devices.isEmpty) {
      return _buildEmptyState(theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 120) {
          return _buildUltraCompactView(theme);
        } else if (constraints.maxHeight < 200) {
          return _buildHorizontalView(theme);
        }
        
        return Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.devices.length,
                itemBuilder: (context, index) {
                  return _buildDeviceCard(widget.devices[index], theme, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUltraCompactView(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.devices_rounded, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${widget.devices.length} Devices', 
                     style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text('${widget.devices.where((d) => d.isActive).length} active', 
                     style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDeviceListModal(),
            child: Text('View All', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalView(ThemeData theme) {
    return Container(
      height: 120,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.devices_rounded, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('Your Devices', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${widget.devices.length}', 
                             style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.devices.length,
              itemBuilder: (context, index) {
                final device = widget.devices[index];
                final locations = widget.deviceLocations[device.deviceId] ?? [];
                final latestLocation = locations.isNotEmpty ? locations.first : null;
                final deviceColor = DeviceUtils.getDeviceColor(device.deviceId);

                return GestureDetector(
                  onTap: () => _showDeviceDetails(device),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: deviceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: deviceColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: deviceColor,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(device.isActive ? Icons.smartphone : Icons.smartphone_outlined, 
                                   color: Colors.white, size: 16),
                              if (device.isActive)
                                Positioned(
                                  top: 3, right: 3,
                                  child: Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: latestLocation != null ? Colors.green : Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(device.deviceName, 
                             style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                             maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.devices_rounded, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Management', 
                     style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('Monitor your connected devices', 
                     style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${widget.devices.where((d) => d.isActive).length}/${widget.devices.length}',
                     style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Device device, ThemeData theme, int index) {
    final locations = widget.deviceLocations[device.deviceId] ?? [];
    final latestLocation = locations.isNotEmpty ? locations.first : null;
    final deviceColor = DeviceUtils.getDeviceColor(device.deviceId);
    final isExpanded = expandedDeviceId == device.deviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isExpanded ? 4 : 2,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isExpanded ? deviceColor.withOpacity(0.05) : theme.colorScheme.surface,
            border: Border.all(color: deviceColor.withOpacity(isExpanded ? 0.3 : 0.1)),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => expandedDeviceId = isExpanded ? null : device.deviceId),
                onLongPress: () => _showDeviceDetails(device),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: deviceColor, shape: BoxShape.circle),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(device.isActive ? Icons.smartphone : Icons.smartphone_outlined, 
                                 color: Colors.white, size: 24),
                            if (device.isActive)
                              Positioned(
                                top: 6, right: 6,
                                child: Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: latestLocation != null ? Colors.green : Colors.orange,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(device.deviceName, 
                                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                 overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusChip(device, latestLocation, theme),
                                const Spacer(),
                                Text(DeviceUtils.formatDateSmart(device.createdAt), 
                                     style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isExpanded ? _buildExpandedContent(device, latestLocation, locations, theme) : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Device device, LocationHistory? latestLocation, List<LocationHistory> locations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton('Details', Icons.info_outline, () => _showDeviceDetails(device), theme, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton('Center', Icons.center_focus_strong, () => widget.onCenterMapOnDevice(device.deviceId), theme, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionButton('Delete', Icons.delete_outline, () => _confirmDelete(device), theme, Colors.red)),
            ],
          ),
          if (latestLocation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last seen', style: theme.textTheme.bodySmall),
                      Text(DeviceUtils.formatDateSmart(latestLocation.createdAt), 
                           style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  if (latestLocation.speed != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Speed', style: theme.textTheme.bodySmall),
                        Text(DeviceUtils.formatSpeed(latestLocation.speed!), 
                             style: theme.textTheme.bodyMedium?.copyWith(
                               fontWeight: FontWeight.w500,
                               color: DeviceUtils.getSpeedColor(latestLocation.speed),
                             )),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Points', style: theme.textTheme.bodySmall),
                      Text('${locations.length}', 
                           style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, ThemeData theme, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Device device, LocationHistory? latestLocation, ThemeData theme) {
    Color chipColor;
    String text;
    
    if (device.isActive && latestLocation != null) {
      chipColor = Colors.green;
      text = 'Online';
    } else if (device.isActive && latestLocation == null) {
      chipColor = Colors.orange;
      text = 'No GPS';
    } else {
      chipColor = Colors.grey;
      text = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: chipColor, fontWeight: FontWeight.w500, fontSize: 11)),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No Devices Found', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Add a device to start tracking', 
               style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
        ],
      ),
    );
  }

  void _showDeviceDetails(Device device) {
    final locations = widget.deviceLocations[device.deviceId] ?? [];
    final latestLocation = locations.isNotEmpty ? locations.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: DeviceUtils.getDeviceColor(device.deviceId), shape: BoxShape.circle),
                    child: Icon(device.isActive ? Icons.smartphone : Icons.smartphone_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.deviceName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('ID: ${device.deviceId}', 
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                               color: Theme.of(context).colorScheme.onSurfaceVariant, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCenterMapOnDevice(device.deviceId);
                      },
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Center on Map'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDeleteDevice(device);
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoCard('Device Status', [
                      _buildInfoRow('Status', device.isActive ? 'Active' : 'Inactive', device.isActive ? Colors.green : Colors.grey),
                      _buildInfoRow('Added', DeviceUtils.formatDateSmart(device.createdAt), null),
                    ]),
                    if (latestLocation != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard('Location Data', [
                        _buildInfoRow('Last Update', DeviceUtils.formatDateSmart(latestLocation.createdAt), null),
                        if (latestLocation.speed != null)
                          _buildInfoRow('Speed', DeviceUtils.formatSpeed(latestLocation.speed!), DeviceUtils.getSpeedColor(latestLocation.speed)),
                        _buildInfoRow('History Points', '${locations.length}', null),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  void _showDeviceListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.list_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('All Devices', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.devices.length,
                itemBuilder: (context, index) {
                  final device = widget.devices[index];
                  final locations = widget.deviceLocations[device.deviceId] ?? [];
                  final latestLocation = locations.isNotEmpty ? locations.first : null;
                  
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showDeviceDetails(device);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DeviceUtils.getDeviceColor(device.deviceId).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: DeviceUtils.getDeviceColor(device.deviceId), shape: BoxShape.circle),
                            child: Icon(device.isActive ? Icons.smartphone : Icons.smartphone_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.deviceName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildStatusChip(device, latestLocation, Theme.of(context)),
                                    const Spacer(),
                                    if (latestLocation != null)
                                      Text(DeviceUtils.formatDateSmart(latestLocation.createdAt), 
                                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                             color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  void _confirmDelete(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete "${device.deviceName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteDevice(device);
              setState(() => expandedDeviceId = null);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}