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
    final theme = Theme.of(context);
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
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer.withOpacity(0.8),
                    theme.colorScheme.primaryContainer.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
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
                      _buildHeader(theme),
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Device Stats Section
                      _buildDeviceSection(theme, activeDevices, devicesWithLocation, isTablet),
                      
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Progress Indicators
                      _buildProgressSection(theme, activeDevices, devicesWithLocation, isTablet),
                      
                      SizedBox(height: isTablet ? 20 : 16),
                      
                      // Geofence Section
                      _buildGeofenceSection(theme, activeGeofences, inactiveGeofences, isTablet),
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

  Widget _buildHeader(ThemeData theme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Real-time device & geofence monitoring',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
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

  Widget _buildDeviceSection(ThemeData theme, int activeDevices, int devicesWithLocation, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 32) / 3; // Account for spacing
        
        return Row(
          children: [
            Expanded(
              child: _buildAnimatedStatCard(
                'Total Devices', 
                widget.devices.length.toString(), 
                Icons.devices_rounded, 
                theme,
                color: theme.colorScheme.primary,
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
                theme,
                color: Colors.green,
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
                theme,
                color: Colors.blue,
                delay: 200,
                isTablet: isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSection(ThemeData theme, int activeDevices, int devicesWithLocation, bool isTablet) {
    final deviceActiveRate = widget.devices.isNotEmpty ? activeDevices / widget.devices.length : 0.0;
    final locationRate = widget.devices.isNotEmpty ? devicesWithLocation / widget.devices.length : 0.0;

    return Column(
      children: [
        _buildProgressIndicator(
          'Device Activity Rate',
          deviceActiveRate,
          Colors.green,
          theme,
          isTablet,
        ),
        const SizedBox(height: 12),
        _buildProgressIndicator(
          'Location Coverage',
          locationRate,
          Colors.blue,
          theme,
          isTablet,
        ),
      ],
    );
  }

  Widget _buildGeofenceSection(ThemeData theme, int activeGeofences, int inactiveGeofences, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
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
                color: theme.colorScheme.primary,
                size: isTablet ? 20 : 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Geofences',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
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
                  theme.colorScheme.primary,
                  theme,
                  isTablet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStat(
                  'Active',
                  activeGeofences.toString(),
                  Icons.check_circle_rounded,
                  Colors.green,
                  theme,
                  isTablet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStat(
                  'Inactive',
                  inactiveGeofences.toString(),
                  Icons.pause_circle_rounded,
                  Colors.orange,
                  theme,
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
    IconData icon, 
    ThemeData theme, {
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
              color: theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
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
                    color: color.withOpacity(0.1),
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
                    style: (isTablet ? theme.textTheme.headlineSmall : theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 4 : 2),
                FittedBox(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: isTablet ? 12 : 10,
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
    ThemeData theme,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${(animatedProgress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: isTablet ? 8 : 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.3),
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
    ThemeData theme,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          FittedBox(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: isTablet ? 10 : 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}