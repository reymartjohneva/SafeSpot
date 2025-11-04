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
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: DeviceScreenColors.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingIconWidget(),
                      const SizedBox(height: 24),
                      const Text(
                        'Authentication Required',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: DeviceScreenColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please log in to manage devices',
                        style: TextStyle(
                          fontSize: 15,
                          color: DeviceScreenColors.textSecondary,
                          height: 1.4,
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
    );
  }

  static PreferredSizeWidget _buildAppBar(TabController tabController) {
    return AppBar(
      elevation: 0,
      backgroundColor: DeviceScreenColors.darkBackground,
      surfaceTintColor: DeviceScreenColors.darkBackground,
      toolbarHeight: 72,
      title: Row(
        children: [
          Hero(
            tag: 'app_icon',
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: (1 - value.clamp(0.0, 1.0)) * 3.14159 * 2,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/app1_icon.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 32,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value.clamp(0.0, 1.0))),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFFFB74D)],
                    ).createShader(bounds),
                    child: const Text(
                      'SafeSpot',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: DeviceScreenColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: DeviceScreenColors.textSecondary,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.devices, size: 18),
                    SizedBox(width: 6),
                    Text('Devices'),
                  ],
                ),
              ),
              Tab(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 18),
                    SizedBox(width: 6),
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
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  DeviceScreenColors.primaryOrange,
                ),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: const Text(
                    'Loading devices...',
                    style: TextStyle(
                      color: DeviceScreenColors.textSecondary,
                      fontSize: 14,
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
      onShowDevicesModal: () => _showDevicesModal(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Header
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value.clamp(0.0, 1.0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Control Center',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: DeviceScreenColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage your devices and monitor activity',
                          style: TextStyle(
                            fontSize: 15,
                            color: DeviceScreenColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Animated Stats Container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: _buildStatsContainer(state),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Animated Quick Actions
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value.clamp(0.0, 1.0))),
                    child: _buildQuickActions(
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

  static Widget _buildStatsContainer(DeviceScreenStateData state) {
    return Container(
      decoration: BoxDecoration(
        color: DeviceScreenColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.2),
                      const Color(0xFFFF9800).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: DeviceScreenColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DeviceScreenColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AnimatedStatCard(
                  icon: Icons.devices,
                  label: 'Total',
                  value: state.devices.length,
                  color: const Color(0xFF4CAF50),
                  delay: 100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedStatCard(
                  icon: Icons.wifi,
                  label: 'Online',
                  value: state.deviceLocations.length,
                  color: const Color(0xFF2196F3),
                  delay: 200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedStatCard(
                  icon: Icons.shield,
                  label: 'Geofences',
                  value: state.geofences.length,
                  color: const Color(0xFFFF9800),
                  delay: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickActions({
    required BuildContext context,
    required DeviceScreenStateData state,
    required VoidCallback onShowAddDeviceModal,
    required VoidCallback onShowDevicesModal,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DeviceScreenColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.2),
                      const Color(0xFF66BB6A).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.touch_app_outlined,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DeviceScreenColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Add Device Button with Hover Effect
          _AnimatedActionButton(
            onPressed: onShowAddDeviceModal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add New Device',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // View Devices Button
          _AnimatedDeviceListButton(
            onTap: onShowDevicesModal,
            deviceCount: state.devices.length,
          ),
        ],
      ),
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
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * (1 - value.clamp(0.0, 1.0)) * 0.3),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: DeviceScreenColors.darkBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.devices,
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
                                    'My Devices',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: DeviceScreenColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${state.devices.length} device${state.devices.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: DeviceScreenColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              color: DeviceScreenColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Device List
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: onLoadDevices,
                          color: DeviceScreenColors.primaryOrange,
                          backgroundColor: DeviceScreenColors.cardBackground,
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
    );
  }

  static Widget _buildEmptyState(VoidCallback onShowAddDeviceModal) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value.clamp(0.0, 1.0),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: DeviceScreenColors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FloatingIconWidget(),
                        const SizedBox(height: 24),
                        const Text(
                          'No Devices Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: DeviceScreenColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Add your first device to start tracking\nits location in real-time',
                          style: TextStyle(
                            fontSize: 15,
                            color: DeviceScreenColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _AnimatedActionButton(
                          onPressed: onShowAddDeviceModal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, size: 20, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add Your First Device',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Pulsing Icon Widget for Authentication Screen
class _PulsingIconWidget extends StatefulWidget {
  @override
  State<_PulsingIconWidget> createState() => _PulsingIconWidgetState();
}

class _PulsingIconWidgetState extends State<_PulsingIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 20 * _animation.value,
                  spreadRadius: 5 * (_animation.value - 0.9),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

// Floating Icon Widget for Empty State
class _FloatingIconWidget extends StatefulWidget {
  @override
  State<_FloatingIconWidget> createState() => _FloatingIconWidgetState();
}

class _FloatingIconWidgetState extends State<_FloatingIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B35).withOpacity(0.2),
                  const Color(0xFFFF9800).withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.devices_outlined,
              size: 64,
              color: DeviceScreenColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

// Animated Stat Card Widget
class _AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final int delay;

  const _AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + widget.delay),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue.clamp(0.0, 1.0),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: DeviceScreenColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.value),
                    duration: Duration(milliseconds: 1000 + widget.delay),
                    curve: Curves.easeOut,
                    builder: (context, intValue, child) {
                      return Text(
                        intValue.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: DeviceScreenColors.textSecondary,
                    ),
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

// Animated Action Button Widget
class _AnimatedActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedActionButton({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(_isPressed ? 0.2 : 0.4),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Animated Device List Button
class _AnimatedDeviceListButton extends StatefulWidget {
  final VoidCallback onTap;
  final int deviceCount;

  const _AnimatedDeviceListButton({
    required this.onTap,
    required this.deviceCount,
  });

  @override
  State<_AnimatedDeviceListButton> createState() =>
      _AnimatedDeviceListButtonState();
}

class _AnimatedDeviceListButtonState extends State<_AnimatedDeviceListButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DeviceScreenColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    blurRadius: 8 + _elevationAnimation.value,
                    offset: Offset(0, 2 + _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.devices,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View All Devices',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DeviceScreenColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.deviceCount} device${widget.deviceCount != 1 ? 's' : ''} registered',
                          style: const TextStyle(
                            fontSize: 13,
                            color: DeviceScreenColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_controller.value * 4, 0),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: DeviceScreenColors.textSecondary,
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
    return DecoratedBox(
      decoration: decoration,
      child: this,
    );
  }
}