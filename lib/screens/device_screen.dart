import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_state.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_location_mixin.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_device_mixin.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_geofence_mixin.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_road_snapping_mixin.dart';
import 'package:safe_spot/screens/device_screen_components/device_screen_ui.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        DeviceScreenLocationMixin,
        DeviceScreenDeviceMixin,
        DeviceScreenGeofenceMixin,
        DeviceScreenRoadSnappingMixin {
  late TabController tabController;
  final MapController mapController = MapController();

  // State variables from DeviceScreenState
  final DeviceScreenStateData state = DeviceScreenStateData();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tabController = TabController(length: 2, vsync: this);
    initializeLocation();
    loadDevices();
    loadGeofences();
    startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeRoadSnapping();
    state.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reinitializeLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeviceScreenUI.buildScreen(
      context: context,
      state: state,
      tabController: tabController,
      mapController: mapController,
      onShowAddDeviceModal: showAddDeviceModal,
      onLoadDevices: loadDevices,
      onDeleteDevice: deleteDevice,
      onCenterMapOnDevice: centerMapOnDevice,
      onDeviceSelected: (deviceId) {
        setState(() {
          state.selectedDeviceId = deviceId;
        });
      },
      onCenterMapOnCurrentLocation: centerMapOnCurrentLocation,
      onMapTap: onMapTap,
      onMapLongPress: onMapLongPress,
      findDeviceById: findDeviceById,
      onStartDrawing: startDrawingGeofence,
      onStopDrawing: stopDrawingGeofence,
      onClearPoints: () {
        setState(() {
          state.currentGeofencePoints.clear();
          state.isDragging = false;
          state.draggedPointIndex = null;
        });
      },
      onLoadGeofences: loadGeofences,
      onToggleGeofenceStatus: toggleGeofenceStatus,
      onDeleteGeofence: deleteGeofence,
      // NEW: Add history points visibility toggle
      showHistoryPoints: state.showHistoryPoints,
      onToggleHistoryPoints: () {
        setState(() {
          state.showHistoryPoints = !state.showHistoryPoints;
        });
      },
    );
  }
}
