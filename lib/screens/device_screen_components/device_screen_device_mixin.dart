import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/utils/device_utils.dart';
import 'package:safe_spot/screens/widgets/add_device_form_widget.dart';
import 'device_screen_state.dart';

mixin DeviceScreenDeviceMixin<T extends StatefulWidget> on State<T> {
  DeviceScreenStateData get state;
  MapController get mapController;
  TabController get tabController;

  void startAutoRefresh() {
    state.refreshTimer = Timer.periodic(
      DeviceScreenStateData.refreshInterval,
      (timer) {
        if (mounted && DeviceService.isAuthenticated) {
          loadDeviceLocationsOnly();
        }
      },
    );
  }

  void stopAutoRefresh() {
    state.refreshTimer?.cancel();
    state.refreshTimer = null;
  }

  Future<void> loadDeviceLocationsOnly() async {
    if (!DeviceService.isAuthenticated) return;

    try {
      for (var device in state.devices) {
        final history = await DeviceService.getDeviceLocationHistory(
          deviceId: device.deviceId,
          limit: 100,
        );
        if (mounted) {
          setState(() {
            state.deviceLocations[device.deviceId] = history;
          });
        }
      }
    } catch (e) {
      print('Error refreshing location data: $e');
    }
  }

  Future<void> loadDevices() async {
    if (!DeviceService.isAuthenticated) return;

    setState(() => state.isLoading = true);
    try {
      final devices = await DeviceService.getUserDevices();
      setState(() => state.devices = devices);

      for (var device in devices) {
        await loadDeviceLocationHistory(device.deviceId);
      }

      stopAutoRefresh();
      startAutoRefresh();
    } catch (e) {
      print('Error loading devices: $e');
      if (mounted) {
        DeviceUtils.showErrorSnackBar(context, 'Failed to load devices: $e');
      }
    } finally {
      if (mounted) setState(() => state.isLoading = false);
    }
  }

  Future<void> loadDeviceLocationHistory(String deviceId) async {
    try {
      final history = await DeviceService.getDeviceLocationHistory(
        deviceId: deviceId,
      );
      if (mounted) {
        setState(() {
          state.deviceLocations[deviceId] = history;
        });
      }
    } catch (e) {
      print('Failed to load location history for $deviceId: $e');
    }
  }

  void showAddDeviceModal() {
    state.deviceIdController.clear();
    state.deviceNameController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: DeviceScreenColors.cardBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Modal handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: DeviceScreenColors.textSecondary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: AddDeviceFormWidget(
                        deviceIdController: state.deviceIdController,
                        deviceNameController: state.deviceNameController,
                        isAddingDevice: state.isAddingDevice,
                        onAddDevice: () async {
                          setModalState(() => state.isAddingDevice = true);
                          await addDevice();
                          setModalState(() => state.isAddingDevice = false);
                          if (mounted && !state.isAddingDevice) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> addDevice() async {
    final deviceId = state.deviceIdController.text.trim();
    final deviceName = state.deviceNameController.text.trim();

    if (deviceId.isEmpty || deviceName.isEmpty) {
      DeviceUtils.showErrorSnackBar(context, 'Please fill in all fields');
      return;
    }

    setState(() => state.isAddingDevice = true);
    try {
      await DeviceService.addDevice(deviceId: deviceId, deviceName: deviceName);

      DeviceUtils.showSuccessSnackBar(context, 'Device "$deviceName" added successfully');
      state.deviceIdController.clear();
      state.deviceNameController.clear();
      await loadDevices();
    } catch (e) {
      DeviceUtils.showErrorSnackBar(context, 'Failed to add device: $e');
    } finally {
      if (mounted) setState(() => state.isAddingDevice = false);
    }
  }

  Future<void> deleteDevice(Device device) async {
    final confirmed = await DeviceUtils.showDeleteConfirmation(context, device.deviceName);
    if (confirmed == true) {
      try {
        await DeviceService.deleteDevice(device.id);
        DeviceUtils.showSuccessSnackBar(context, 'Device deleted successfully');
        await loadDevices();
      } catch (e) {
        DeviceUtils.showErrorSnackBar(context, 'Failed to delete device: $e');
      }
    }
  }

  void centerMapOnDevice(String deviceId) {
    final locations = state.deviceLocations[deviceId];
    if (locations != null && locations.isNotEmpty) {
      final latestLocation = locations.first;
      mapController.move(
        LatLng(latestLocation.latitude, latestLocation.longitude),
        15.0,
      );
      setState(() {
        state.selectedDeviceId = deviceId;
      });
      tabController.animateTo(1);
    }
  }

  Device? findDeviceById(String deviceId) {
    try {
      return state.devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }
}