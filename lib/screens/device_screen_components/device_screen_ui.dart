import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/screens/widgets/device_list_widget.dart';
import 'package:safe_spot/screens/widgets/map/device_map_widget.dart';
import 'package:safe_spot/screens/widgets/device_stats_widget.dart';
import 'device_screen_state.dart';

class DeviceScreenUI {
  static Widget buildScreen({
    required BuildContext context,
    required DeviceScreenStateData state,
    required TabController tabController,
    required MapController mapController,
    required VoidCallback onShowAddDeviceModal,
    required Future<void> Function() onLoadDevices,
    required Future<void> Function(Device) onDeleteDevice,
    required void Function(String) onCenterMapOnDevice,
    required void Function(String?) onDeviceSelected,
    required VoidCallback onCenterMapOnCurrentLocation,
    required void Function(TapPosition, LatLng) onMapTap,
    required void Function(TapPosition, LatLng) onMapLongPress,
    required Device? Function(String) findDeviceById,
    required VoidCallback onStartDrawing,
    required VoidCallback onStopDrawing,
    required VoidCallback onClearPoints,
    required Future<void> Function() onLoadGeofences,
    required Future<void> Function(String, bool) onToggleGeofenceStatus,
    required Future<void> Function(String, int) onDeleteGeofence,
    required bool showHistoryPoints,
    required VoidCallback onToggleHistoryPoints,
  }) {
    if (!DeviceService.isAuthenticated) {
      return _buildUnauthenticatedScreen();
    }

    return Scaffold(
      backgroundColor: DeviceScreenColors.darkBackground,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(tabController),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildDevicesTab(
            context: context,
            state: state,
            onShowAddDeviceModal: onShowAddDeviceModal,
            onLoadDevices: onLoadDevices,
            onDeleteDevice: onDeleteDevice,
            onCenterMapOnDevice: onCenterMapOnDevice,
          ),
          _buildMapTab(
            mapController: mapController,
            state: state,
            onDeviceSelected: onDeviceSelected,
            onCenterMapOnDevice: onCenterMapOnDevice,
            onCenterMapOnCurrentLocation: onCenterMapOnCurrentLocation,
            onMapTap: onMapTap,
            onMapLongPress: onMapLongPress,
            findDeviceById: findDeviceById,
            onStartDrawing: onStartDrawing,
            onStopDrawing: onStopDrawing,
            onClearPoints: onClearPoints,
            onLoadGeofences: onLoadGeofences,
            onToggleGeofenceStatus: onToggleGeofenceStatus,
            onDeleteGeofence: onDeleteGeofence,
            showHistoryPoints: showHistoryPoints,
            onToggleHistoryPoints: onToggleHistoryPoints,
          ),
        ],
      ),
    );
  }

  static Widget _buildUnauthenticatedScreen() {
    return Scaffold(
      backgroundColor: DeviceScreenColors.darkBackground,
      body: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              builder: (context, value, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(value * 0.5, -0.5 + value * 0.3),
                      radius: 1.5,
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.1),
                        DeviceScreenColors.darkBackground,
                        DeviceScreenColors.darkBackground,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Content
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value.clamp(0.0, 1.0) * 0.2),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        color: DeviceScreenColors.surfaceColor,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingIconWidget(),
                          const SizedBox(height: 32),
                          ShaderMask(
                            shaderCallback:
                                (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFFF9800),
                                  ],
                                ).createShader(bounds),
                            child: const Text(
                              'Authentication Required',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please log in to manage your devices\nand access location tracking',
                            style: TextStyle(
                              fontSize: 15,
                              color: DeviceScreenColors.textSecondary
                                  .withOpacity(0.8),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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

  static PreferredSizeWidget _buildAppBar(TabController tabController) {
    return AppBar(
      elevation: 0,
      backgroundColor: DeviceScreenColors.darkBackground,
      surfaceTintColor: DeviceScreenColors.darkBackground,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DeviceScreenColors.darkBackground,
              DeviceScreenColors.darkBackground.withOpacity(0.95),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Hero(
            tag: 'app_icon',
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value.clamp(0.0, 1.0)) * 3.14159 * 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/app1_icon.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 36,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value.clamp(0.0, 1.0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFFFB74D)],
                            ).createShader(bounds),
                        child: const Text(
                          'SafeSpot',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          decoration: BoxDecoration(
            color: DeviceScreenColors.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: DeviceScreenColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.all(6),
            tabs: const [
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Dashboard'),
                  ],
                ),
              ),
              Tab(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Map View'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDevicesTab({
    required BuildContext context,
    required DeviceScreenStateData state,
    required VoidCallback onShowAddDeviceModal,
    required Future<void> Function() onLoadDevices,
    required Future<void> Function(Device) onDeleteDevice,
    required void Function(String) onCenterMapOnDevice,
  }) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: null,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFFF6B35).withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Inner ring
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: null,
                          strokeWidth: 4,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: (value * 0.5 + 0.5).clamp(0.0, 1.0),
                  child: const Text(
                    'Loading your devices...',
                    style: TextStyle(
                      color: DeviceScreenColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    if (state.devices.isEmpty) {
      return _buildEmptyState(onShowAddDeviceModal);
    }

    return _buildDevicesControlCenter(
      context: context,
      state: state,
      onShowAddDeviceModal: onShowAddDeviceModal,
      onShowDevicesModal:
          () => _showDevicesModal(
            context: context,
            state: state,
            onLoadDevices: onLoadDevices,
            onDeleteDevice: onDeleteDevice,
            onCenterMapOnDevice: onCenterMapOnDevice,
          ),
      onLoadDevices: onLoadDevices,
    );
  }

  static Widget _buildDevicesControlCenter({
    required BuildContext context,
    required DeviceScreenStateData state,
    required VoidCallback onShowAddDeviceModal,
    required VoidCallback onShowDevicesModal,
    required Future<void> Function() onLoadDevices,
  }) {
    return RefreshIndicator(
      onRefresh: onLoadDevices,
      color: DeviceScreenColors.primaryOrange,
      backgroundColor: DeviceScreenColors.cardBackground,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Header with gradient text
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value.clamp(0.0, 1.0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF6B35).withOpacity(0.2),
                                    const Color(0xFFFF9800).withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.space_dashboard_rounded,
                                color: DeviceScreenColors.primaryOrange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback:
                                        (bounds) => const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFFFB74D),
                                          ],
                                        ).createShader(bounds),
                                    child: const Text(
                                      'Control Center',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage devices and monitor activity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: DeviceScreenColors.textSecondary
                                          .withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
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
            const SizedBox(height: 28),

            // Enhanced Stats Container with glass effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (value.clamp(0.0, 1.0) * 0.1),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildEnhancedStatsContainer(state),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Enhanced Quick Actions
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - value.clamp(0.0, 1.0))),
                    child: _buildEnhancedQuickActions(
                      context: context,
                      state: state,
                      onShowAddDeviceModal: onShowAddDeviceModal,
                      onShowDevicesModal: onShowDevicesModal,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEnhancedStatsContainer(DeviceScreenStateData state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DeviceScreenColors.surfaceColor,
            DeviceScreenColors.surfaceColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DeviceScreenColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _EnhancedStatCard(
                  icon: Icons.devices_rounded,
                  label: 'Total Devices',
                  value: state.devices.length,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  delay: 100,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _EnhancedStatCard(
                  icon: Icons.wifi_rounded,
                  label: 'Active Now',
                  value: state.deviceLocations.length,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                  ),
                  delay: 200,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _EnhancedStatCard(
                  icon: Icons.shield_rounded,
                  label: 'Geofences',
                  value: state.geofences.length,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                  ),
                  delay: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildEnhancedQuickActions({
    required BuildContext context,
    required DeviceScreenStateData state,
    required VoidCallback onShowAddDeviceModal,
    required VoidCallback onShowDevicesModal,
  }) {
    return Column(
      children: [
        // Add Device Card
        _EnhancedActionCard(
          onPressed: onShowAddDeviceModal,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
          ),
          icon: Icons.add_circle_outline_rounded,
          title: 'Add New Device',
          subtitle: 'Register a device to track',
          delay: 0,
        ),

        const SizedBox(height: 16),

        // View Devices Card
        _EnhancedDeviceListCard(
          onTap: onShowDevicesModal,
          deviceCount: state.devices.length,
        ),
      ],
    );
  }

  static void _showDevicesModal({
    required BuildContext context,
    required DeviceScreenStateData state,
    required Future<void> Function() onLoadDevices,
    required Future<void> Function(Device) onDeleteDevice,
    required void Function(String) onCenterMapOnDevice,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  MediaQuery.of(context).size.height *
                      (1 - value.clamp(0.0, 1.0)) *
                      0.3,
                ),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder:
                        (context, scrollController) => Container(
                          decoration: BoxDecoration(
                            color: DeviceScreenColors.darkBackground,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFFF6B35).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Elegant handle bar
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 8,
                                ),
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFFFF9800),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Enhanced Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  20,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF4CAF50),
                                            Color(0xFF66BB6A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF4CAF50,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.devices_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'My Devices',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  DeviceScreenColors
                                                      .textPrimary,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${state.devices.length} device${state.devices.length != 1 ? 's' : ''} registered',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: DeviceScreenColors
                                                  .textSecondary
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: DeviceScreenColors.surfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.close_rounded),
                                        color: DeviceScreenColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Elegant Divider
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Device List
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: onLoadDevices,
                                  color: DeviceScreenColors.primaryOrange,
                                  backgroundColor:
                                      DeviceScreenColors.cardBackground,
                                  child: DeviceListWidget(
                                    devices: state.devices,
                                    deviceLocations: state.deviceLocations,
                                    onDeleteDevice: onDeleteDevice,
                                    onCenterMapOnDevice: onCenterMapOnDevice,
                                  ),
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
    );
  }

  static Widget _buildMapTab({
    required MapController mapController,
    required DeviceScreenStateData state,
    required void Function(String?) onDeviceSelected,
    required void Function(String) onCenterMapOnDevice,
    required VoidCallback onCenterMapOnCurrentLocation,
    required void Function(TapPosition, LatLng) onMapTap,
    required void Function(TapPosition, LatLng) onMapLongPress,
    required Device? Function(String) findDeviceById,
    required VoidCallback onStartDrawing,
    required VoidCallback onStopDrawing,
    required VoidCallback onClearPoints,
    required Future<void> Function() onLoadGeofences,
    required Future<void> Function(String, bool) onToggleGeofenceStatus,
    required Future<void> Function(String, int) onDeleteGeofence,
    required bool showHistoryPoints,
    required VoidCallback onToggleHistoryPoints,
  }) {
    return DeviceMapWidget(
      mapController: mapController,
      devices: state.devices,
      deviceLocations: state.deviceLocations,
      selectedDeviceId: state.selectedDeviceId,
      currentPosition: state.currentPosition,
      geofences: state.geofences,
      currentGeofencePoints: state.currentGeofencePoints,
      isDrawingGeofence: state.isDrawingGeofence,
      isDragging: state.isDragging,
      draggedPointIndex: state.draggedPointIndex,
      isLoadingGeofences: state.isLoadingGeofences,
      onDeviceSelected: onDeviceSelected,
      onCenterMapOnDevice: onCenterMapOnDevice,
      onCenterMapOnCurrentLocation: onCenterMapOnCurrentLocation,
      onMapTap: onMapTap,
      onMapLongPress: onMapLongPress,
      findDeviceById: findDeviceById,
      onStartDrawing: onStartDrawing,
      onStopDrawing: onStopDrawing,
      onClearPoints: onClearPoints,
      onLoadGeofences: onLoadGeofences,
      onToggleGeofenceStatus: onToggleGeofenceStatus,
      onDeleteGeofence: onDeleteGeofence,
      showHistoryPoints: showHistoryPoints,
      onToggleHistoryPoints: onToggleHistoryPoints,
      snappedPaths: state.snappedPaths,
      showSnappedPaths: state.showSnappedPaths,
    );
  }

  static Widget _buildEmptyState(VoidCallback onShowAddDeviceModal) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value.clamp(0.0, 1.0) * 0.2),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DeviceScreenColors.surfaceColor,
                        DeviceScreenColors.surfaceColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FloatingIconWidget(),
                        const SizedBox(height: 32),
                        ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                              ).createShader(bounds),
                          child: const Text(
                            'No Devices Yet',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start your tracking journey by adding\nyour first device to monitor',
                          style: TextStyle(
                            fontSize: 15,
                            color: DeviceScreenColors.textSecondary.withOpacity(
                              0.8,
                            ),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _EnhancedPrimaryButton(
                          onPressed: onShowAddDeviceModal,
                          icon: Icons.add_circle_rounded,
                          label: 'Add Your First Device',
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
    );
  }
}

// Enhanced Pulsing Icon Widget
class _PulsingIconWidget extends StatefulWidget {
  @override
  State<_PulsingIconWidget> createState() => _PulsingIconWidgetState();
}

class _PulsingIconWidgetState extends State<_PulsingIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFF6B35,
                ).withOpacity(_glowAnimation.value),
                blurRadius: 40 * _scaleAnimation.value,
                spreadRadius: 10 * _scaleAnimation.value,
              ),
            ],
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Floating Icon Widget
class _FloatingIconWidget extends StatefulWidget {
  @override
  State<_FloatingIconWidget> createState() => _FloatingIconWidgetState();
}

class _FloatingIconWidgetState extends State<_FloatingIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -12.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFF6B35).withOpacity(0.15),
                    const Color(0xFFFF9800).withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.3),
                      const Color(0xFFFF9800).withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  size: 72,
                  color: DeviceScreenColors.primaryOrange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Stat Card Widget
class _EnhancedStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Gradient gradient;
  final int delay;

  const _EnhancedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    required this.delay,
  });

  @override
  State<_EnhancedStatCard> createState() => _EnhancedStatCardState();
}

class _EnhancedStatCardState extends State<_EnhancedStatCard> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + widget.delay),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.8 + (animValue.clamp(0.0, 1.0) * 0.2),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DeviceScreenColors.cardBackground,
                    DeviceScreenColors.cardBackground.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.gradient.colors.first as Color)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, size: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.value),
                    duration: Duration(milliseconds: 1200 + widget.delay),
                    curve: Curves.easeOutCubic,
                    builder: (context, intValue, child) {
                      return ShaderMask(
                        shaderCallback:
                            (bounds) => widget.gradient.createShader(bounds),
                        child: Text(
                          intValue.toString(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DeviceScreenColors.textSecondary.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Action Card Widget
class _EnhancedActionCard extends StatefulWidget {
  final VoidCallback onPressed;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;

  const _EnhancedActionCard({
    required this.onPressed,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  State<_EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<_EnhancedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient.colors.first as Color).withOpacity(
                      0.5 * _elevationAnimation.value,
                    ),
                    blurRadius: 20 * _elevationAnimation.value,
                    offset: Offset(0, 8 * _elevationAnimation.value),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.3 * _elevationAnimation.value,
                    ),
                    blurRadius: 12 * _elevationAnimation.value,
                    offset: Offset(0, 4 * _elevationAnimation.value),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Primary Button Widget
class _EnhancedPrimaryButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _EnhancedPrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<_EnhancedPrimaryButton> createState() => _EnhancedPrimaryButtonState();
}

class _EnhancedPrimaryButtonState extends State<_EnhancedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Enhanced Device List Card
class _EnhancedDeviceListCard extends StatefulWidget {
  final VoidCallback onTap;
  final int deviceCount;

  const _EnhancedDeviceListCard({
    required this.onTap,
    required this.deviceCount,
  });

  @override
  State<_EnhancedDeviceListCard> createState() =>
      _EnhancedDeviceListCardState();
}

class _EnhancedDeviceListCardState extends State<_EnhancedDeviceListCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DeviceScreenColors.surfaceColor,
                    DeviceScreenColors.surfaceColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.devices_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View All Devices',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DeviceScreenColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.deviceCount} device${widget.deviceCount != 1 ? 's' : ''} available',
                          style: TextStyle(
                            fontSize: 13,
                            color: DeviceScreenColors.textSecondary.withOpacity(
                              0.8,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Extension to add decoratedBox functionality
extension WidgetExtension on Widget {
  Widget decoratedBox({required BoxDecoration decoration}) {
    return DecoratedBox(decoration: decoration, child: this);
  }
}
