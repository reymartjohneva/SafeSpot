import 'package:flutter/material.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/geofence_service.dart';

class DeviceStatsWidget extends StatefulWidget {
  final List<Device> devices;
  final Map<String, List<LocationHistory>> deviceLocations;
  final List<Geofence> geofences;

  const DeviceStatsWidget({
    Key? key,
    required this.devices,
    required this.deviceLocations,
    required this.geofences,
  }) : super(key: key);

  @override
  State<DeviceStatsWidget> createState() => _DeviceStatsWidgetState();
}

class _DeviceStatsWidgetState extends State<DeviceStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    final activeDevices = widget.devices.where((d) => d.isActive).length;
    final devicesWithLocation = widget.devices.where((d) => 
        widget.deviceLocations[d.deviceId]?.isNotEmpty == true).length;
    final activeGeofences = widget.geofences.where((g) => g.isActive).length;
    final inactiveGeofences = widget.geofences.length - activeGeofences;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87, // Dark background like navbar
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF8A50).withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(isTablet),
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Device Stats Section
                      _buildDeviceSection(activeDevices, devicesWithLocation, isTablet),
                      
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Progress Indicators
                      _buildProgressSection(activeDevices, devicesWithLocation, isTablet),
                      
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Geofence Section
                      _buildGeofenceSection(activeGeofences, inactiveGeofences, isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isTablet) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A50), // Orange accent
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Real-time device & geofence monitoring',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceSection(int activeDevices, int devicesWithLocation, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                'Total Devices', 
                widget.devices.length.toString(), 
                Icons.devices_rounded, 
                color: const Color(0xFFFF8A50), // Orange
                delay: 0,
                isTablet: isTablet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnimatedStatCard(
                'Active', 
                activeDevices.toString(), 
                Icons.power_settings_new_rounded, 
                color: const Color(0xFF4CAF50), // Green
                delay: 100,
                isTablet: isTablet,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnimatedStatCard(
                'Located', 
                devicesWithLocation.toString(), 
                Icons.location_on_rounded, 
                color: const Color(0xFF2196F3), // Blue
                delay: 200,
                isTablet: isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSection(int activeDevices, int devicesWithLocation, bool isTablet) {
    final deviceActiveRate = widget.devices.isNotEmpty ? activeDevices / widget.devices.length : 0.0;
    final locationRate = widget.devices.isNotEmpty ? devicesWithLocation / widget.devices.length : 0.0;

    return Column(
      children: [
        _buildProgressIndicator(
          'Device Activity Rate',
          deviceActiveRate,
          const Color(0xFF4CAF50),
          isTablet,
        ),
        const SizedBox(height: 12),
        _buildProgressIndicator(
          'Location Coverage',
          locationRate,
          const Color(0xFF2196F3),
          isTablet,
        ),
      ],
    );
  }

  Widget _buildGeofenceSection(int activeGeofences, int inactiveGeofences, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade700,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers_rounded,
                color: const Color(0xFFFF8A50),
                size: isTablet ? 20 : 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Geofences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          
          Row(
            children: [
              Expanded(
                child: _buildCompactStat(
                  'Total',
                  widget.geofences.length.toString(),
                  Icons.layers_outlined,
                  const Color(0xFFFF8A50),
                  isTablet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStat(
                  'Active',
                  activeGeofences.toString(),
                  Icons.check_circle_rounded,
                  const Color(0xFF4CAF50),
                  isTablet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStat(
                  'Inactive',
                  inactiveGeofences.toString(),
                  Icons.pause_circle_rounded,
                  const Color(0xFFFF9800),
                  isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String label, 
    String value, 
    IconData icon, {
    required Color color,
    required int delay,
    required bool isTablet,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade800,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isTablet ? 20 : 16,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                FittedBox(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                FittedBox(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(
    String label,
    double progress,
    Color color,
    bool isTablet,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0.0, end: progress),
      curve: Curves.easeOut,
      builder: (context, animatedProgress, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${(animatedProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: isTablet ? 8 : 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isTablet ? 16 : 14,
          ),
          SizedBox(height: isTablet ? 4 : 2),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 10 : 9,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}