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

class _DeviceListWidgetState extends State<DeviceListWidget>
    with TickerProviderStateMixin {
  String? expandedDeviceId;
  late AnimationController pulseController;
  late AnimationController slideController;

  // Dark theme colors matching the nav bar
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkSurfaceVariant = Color(0xFF3A3A3A);
  static const Color orangeAccent = Color(0xFFFF8A50);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    pulseController.dispose();
    slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.devices.isEmpty) {
      return buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 120) {
          return buildUltraCompactView();
        } else if (constraints.maxHeight < 200) {
          return buildHorizontalView();
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: slideController, curve: Curves.elasticOut),
          ),
          child: Column(
            children: [
              buildModernHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.devices.length,
                  itemBuilder: (context, index) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: slideController,
                          curve: Interval(
                            index * 0.1,
                            (index * 0.1) + 0.3,
                            curve: Curves.elasticOut,
                          ),
                        ),
                      ),
                      child: buildModernDeviceCard(
                        widget.devices[index],
                        index,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildUltraCompactView() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkSurface, darkSurfaceVariant.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: orangeAccent.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: orangeAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: orangeAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.devices_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.devices.length} Connected Devices',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkOnSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.devices.where((d) => d.isActive).length} active',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showDeviceListModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View All'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHorizontalView() {
    return Container(
      height: 140,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkSurface, darkSurfaceVariant.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: orangeAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orangeAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.devices_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Connected Devices',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkOnSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.devices.where((d) => d.isActive).length} of ${widget.devices.length} devices online',
                        style: const TextStyle(
                          color: darkOnSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: orangeAccent.withOpacity(
                          0.1 + (pulseController.value * 0.1),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: orangeAccent.withOpacity(
                            0.3 + (pulseController.value * 0.2),
                          ),
                        ),
                      ),
                      child: Text(
                        '${widget.devices.length}',
                        style: const TextStyle(
                          color: orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
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
                return buildHorizontalDeviceCard(widget.devices[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHorizontalDeviceCard(Device device, int index) {
    final locations = widget.deviceLocations[device.deviceId] ?? [];
    final latestLocation = locations.isNotEmpty ? locations.first : null;
    final deviceColor = DeviceUtils.getDeviceColor(device.deviceId);

    return GestureDetector(
      onTap: () => showDeviceDetails(device),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkSurface, darkSurfaceVariant.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: deviceColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: deviceColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [deviceColor, deviceColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: deviceColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    device.isActive
                        ? Icons.smartphone
                        : Icons.smartphone_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  if (device.isActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: AnimatedBuilder(
                        animation: pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 8 + (pulseController.value * 2),
                            height: 8 + (pulseController.value * 2),
                            decoration: BoxDecoration(
                              color:
                                  latestLocation != null
                                      ? Colors.green
                                      : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (latestLocation != null
                                          ? Colors.green
                                          : Colors.orange)
                                      .withOpacity(0.6),
                                  blurRadius: 4 + (pulseController.value * 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              device.deviceName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: darkOnSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    device.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                device.isActive ? 'Online' : 'Offline',
                style: TextStyle(
                  color:
                      device.isActive
                          ? Colors.green.shade300
                          : Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildModernHeader() {
    final activeDevices = widget.devices.where((d) => d.isActive).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkSurface,
            darkSurfaceVariant.withOpacity(0.8),
            darkBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: orangeAccent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: orangeAccent.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [orangeAccent, orangeAccent.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: orangeAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Control Center',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkOnSurface,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitor and manage all connected devices',
                      style: TextStyle(
                        color: darkOnSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: buildStatCard(
                  '${widget.devices.length}',
                  'Total Devices',
                  Icons.devices_rounded,
                  orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    return buildStatCard(
                      '$activeDevices',
                      'Active Now',
                      Icons.radio_button_checked,
                      Colors.green,
                      isPulsing: true,
                      pulseValue: pulseController.value,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildStatCard(
                  '${widget.devices.length - activeDevices}',
                  'Offline',
                  Icons.radio_button_unchecked,
                  Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color, {
    bool isPulsing = false,
    double pulseValue = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSurfaceVariant.withOpacity(
          0.3 + (isPulsing ? pulseValue * 0.1 : 0),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4 + (isPulsing ? pulseValue * 0.2 : 0)),
          width: 1 + (isPulsing ? pulseValue : 0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 24,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: darkOnSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildModernDeviceCard(Device device, int index) {
    final locations = widget.deviceLocations[device.deviceId] ?? [];
    final latestLocation = locations.isNotEmpty ? locations.first : null;
    final deviceColor = DeviceUtils.getDeviceColor(device.deviceId);
    final isExpanded = expandedDeviceId == device.deviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: isExpanded ? 8 : 3,
        borderRadius: BorderRadius.circular(20),
        shadowColor: deviceColor.withOpacity(0.3),
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isExpanded
                      ? [
                        darkSurface,
                        darkSurfaceVariant.withOpacity(0.8),
                        darkBackground,
                      ]
                      : [darkSurface, darkSurfaceVariant],
            ),
            border: Border.all(
              color: deviceColor.withOpacity(isExpanded ? 0.5 : 0.3),
              width: isExpanded ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    () => setState(
                      () =>
                          expandedDeviceId =
                              isExpanded ? null : device.deviceId,
                    ),
                onLongPress: () => showDeviceDetails(device),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [deviceColor, deviceColor.withOpacity(0.7)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: deviceColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              device.isActive
                                  ? Icons.smartphone
                                  : Icons.smartphone_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            if (device.isActive)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: AnimatedBuilder(
                                  animation: pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 12 + (pulseController.value * 2),
                                      height: 12 + (pulseController.value * 2),
                                      decoration: BoxDecoration(
                                        color:
                                            latestLocation != null
                                                ? Colors.green
                                                : Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (latestLocation != null
                                                    ? Colors.green
                                                    : Colors.orange)
                                                .withOpacity(0.6),
                                            blurRadius:
                                                6 + (pulseController.value * 3),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkOnSurface,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                buildModernStatusChip(device, latestLocation),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: darkSurfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DeviceUtils.formatDateSmart(
                                      device.createdAt,
                                    ),
                                    style: const TextStyle(
                                      color: darkOnSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: deviceColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.expand_more,
                            color: deviceColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child:
                    isExpanded
                        ? buildModernExpandedContent(
                          device,
                          latestLocation,
                          locations,
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildModernExpandedContent(
    Device device,
    LocationHistory? latestLocation,
    List<LocationHistory> locations,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  darkOnSurfaceVariant.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: buildModernActionButton(
                  'Details',
                  Icons.info_outline,
                  () => showDeviceDetails(device),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildModernActionButton(
                  'Center',
                  Icons.center_focus_strong,
                  () => widget.onCenterMapOnDevice(device.deviceId),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildModernActionButton(
                  'Delete',
                  Icons.delete_outline,
                  () => confirmDelete(device),
                  Colors.red,
                ),
              ),
            ],
          ),
          if (latestLocation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkSurfaceVariant.withOpacity(0.5),
                    darkSurfaceVariant.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: darkOnSurfaceVariant.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildInfoColumn(
                    'Last Seen',
                    DeviceUtils.formatDateSmart(latestLocation.timestamp),
                    Icons.access_time,
                    orangeAccent,
                  ),
                  if (latestLocation.speed != null)
                    buildInfoColumn(
                      'Speed',
                      DeviceUtils.formatSpeed(latestLocation.speed!),
                      Icons.speed,
                      DeviceUtils.getSpeedColor(latestLocation.speed),
                    ),
                  buildInfoColumn(
                    'Points',
                    '${locations.length}',
                    Icons.timeline,
                    Colors.cyan,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildInfoColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: darkOnSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget buildModernActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildModernStatusChip(Device device, LocationHistory? latestLocation) {
    Color chipColor;
    String text;
    IconData icon;

    if (device.isActive && latestLocation != null) {
      chipColor = Colors.green;
      text = 'Online';
      icon = Icons.radio_button_checked;
    } else if (device.isActive && latestLocation == null) {
      chipColor = Colors.orange;
      text = 'No GPS';
      icon = Icons.gps_off;
    } else {
      chipColor = Colors.grey;
      text = 'Offline';
      icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [chipColor.withOpacity(0.2), chipColor.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: chipColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      color: darkBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    orangeAccent.withOpacity(0.2),
                    orangeAccent.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.devices_rounded,
                size: 64,
                color: orangeAccent.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Devices Connected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkOnSurface,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first device to start tracking',
              style: TextStyle(color: darkOnSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Add device functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }

  void showDeviceDetails(Device device) {
    final locations = widget.deviceLocations[device.deviceId] ?? [];
    final latestLocation = locations.isNotEmpty ? locations.first : null;
    final deviceColor = DeviceUtils.getDeviceColor(device.deviceId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkBackground, darkSurface],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: darkOnSurfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        darkSurface,
                        darkSurfaceVariant.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: deviceColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [deviceColor, deviceColor.withOpacity(0.8)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: deviceColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          device.isActive
                              ? Icons.smartphone
                              : Icons.smartphone_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.deviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkOnSurface,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: darkSurfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ID: ${device.deviceId}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: darkOnSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: darkOnSurface),
                        style: IconButton.styleFrom(
                          backgroundColor: darkSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onCenterMapOnDevice(device.deviceId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Center on Map'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDeleteDevice(device);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        buildInfoCard('Device Status', [
                          buildInfoRow(
                            'Status',
                            device.isActive ? 'Active' : 'Inactive',
                            device.isActive ? Colors.green : Colors.grey,
                          ),
                          buildInfoRow(
                            'Added',
                            DeviceUtils.formatDateSmart(device.createdAt),
                            null,
                          ),
                        ]),
                        if (latestLocation != null) ...[
                          const SizedBox(height: 20),
                          buildInfoCard('Location Data', [
                            buildInfoRow(
                              'Last Update',
                              DeviceUtils.formatDateSmart(
                                latestLocation.timestamp,
                              ),
                              null,
                            ),
                            if (latestLocation.speed != null)
                              buildInfoRow(
                                'Speed',
                                DeviceUtils.formatSpeed(latestLocation.speed!),
                                DeviceUtils.getSpeedColor(latestLocation.speed),
                              ),
                            buildInfoRow(
                              'History Points',
                              '${locations.length}',
                              null,
                            ),
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

  Widget buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            darkSurfaceVariant.withOpacity(0.5),
            darkSurfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkOnSurfaceVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: darkOnSurface,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: darkOnSurfaceVariant, fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (valueColor ?? orangeAccent).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? darkOnSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showDeviceListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkBackground, darkSurface],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: darkOnSurfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        darkSurface,
                        darkSurfaceVariant.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: orangeAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              orangeAccent,
                              orangeAccent.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.list_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Connected Devices',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkOnSurface,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              '${widget.devices.length} devices registered',
                              style: const TextStyle(
                                color: darkOnSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: darkOnSurface),
                        style: IconButton.styleFrom(
                          backgroundColor: darkSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: widget.devices.length,
                    itemBuilder: (context, index) {
                      final device = widget.devices[index];
                      final locations =
                          widget.deviceLocations[device.deviceId] ?? [];
                      final latestLocation =
                          locations.isNotEmpty ? locations.first : null;
                      final deviceColor = DeviceUtils.getDeviceColor(
                        device.deviceId,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              showDeviceDetails(device);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    darkSurface,
                                    darkSurfaceVariant.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: deviceColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          deviceColor,
                                          deviceColor.withOpacity(0.8),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: deviceColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      device.isActive
                                          ? Icons.smartphone
                                          : Icons.smartphone_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          device.deviceName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darkOnSurface,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            buildModernStatusChip(
                                              device,
                                              latestLocation,
                                            ),
                                            const Spacer(),
                                            if (latestLocation != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: darkSurfaceVariant
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  DeviceUtils.formatDateSmart(
                                                    latestLocation.timestamp,
                                                  ),
                                                  style: const TextStyle(
                                                    color: darkOnSurfaceVariant,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: deviceColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: deviceColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  void confirmDelete(Device device) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delete Device',
                  style: TextStyle(color: darkOnSurface),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${device.deviceName}"? This action cannot be undone.',
              style: const TextStyle(color: darkOnSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: darkOnSurfaceVariant),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDeleteDevice(device);
                  setState(() => expandedDeviceId = null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
