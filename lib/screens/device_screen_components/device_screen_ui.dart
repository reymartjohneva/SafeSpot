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
    // NEW: History points visibility parameters
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
            // NEW: Pass history points visibility
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: DeviceScreenColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: DeviceScreenColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to manage devices',
              style: TextStyle(
                fontSize: 16,
                color: DeviceScreenColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static PreferredSizeWidget _buildAppBar(TabController tabController) {
    return AppBar(
      elevation: 0,
      backgroundColor: DeviceScreenColors.darkBackground,
      surfaceTintColor: DeviceScreenColors.darkBackground,
      title: Row(
        children: [
          // App Logo
          Image.asset(
            'assets/app1_icon.png',
            height: 50,
            width: 50,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          // App Name
          const Text(
            'SafeSpot',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: DeviceScreenColors.textPrimary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DeviceScreenColors.surfaceColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: DeviceScreenColors.primaryOrange,
              borderRadius: BorderRadius.circular(24),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: DeviceScreenColors.textSecondary,
            tabs: const [
              Tab(text: 'Devices', icon: Icon(Icons.devices)),
              Tab(text: 'Map View', icon: Icon(Icons.map)),
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
    return Column(
      children: [
        // Stats widget with full width
        Container(
          padding: const EdgeInsets.all(16),
          child: DeviceStatsWidget(
            devices: state.devices,
            deviceLocations: state.deviceLocations,
            geofences: state.geofences,
          ),
        ),

        // Add device button below stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onShowAddDeviceModal,
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: DeviceScreenColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: DeviceScreenColors.primaryOrange.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Devices list
        Expanded(
          child: RefreshIndicator(
            onRefresh: onLoadDevices,
            color: DeviceScreenColors.primaryOrange,
            backgroundColor: DeviceScreenColors.cardBackground,
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(DeviceScreenColors.primaryOrange),
                    ),
                  )
                : state.devices.isEmpty
                    ? _buildEmptyState(onShowAddDeviceModal)
                    : DeviceListWidget(
                        devices: state.devices,
                        deviceLocations: state.deviceLocations,
                        onDeleteDevice: onDeleteDevice,
                        onCenterMapOnDevice: onCenterMapOnDevice,
                      ),
          ),
        ),
      ],
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
    // NEW: History points visibility parameters
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
      // NEW: Pass history points visibility to map widget
      showHistoryPoints: showHistoryPoints,
      onToggleHistoryPoints: onToggleHistoryPoints,
    );
  }

  static Widget _buildEmptyState(VoidCallback onShowAddDeviceModal) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DeviceScreenColors.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.devices_outlined,
              size: 64,
              color: DeviceScreenColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No devices added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: DeviceScreenColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first device to start tracking its location',
            style: TextStyle(
              fontSize: 16,
              color: DeviceScreenColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onShowAddDeviceModal,
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: DeviceScreenColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: DeviceScreenColors.primaryOrange.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}