import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'device_screen_state.dart';

mixin DeviceScreenLocationMixin<T extends StatefulWidget> on State<T> {
  DeviceScreenStateData get state;
  MapController get mapController;

  Future<void> initializeLocation() async {
    setState(() {
      state.isGettingLocation = true;
    });

    try {
      await requestLocationPermissions();
      await checkLocationService();
      if (state.isLocationServiceEnabled) {
        await getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
    } finally {
      setState(() {
        state.isGettingLocation = false;
      });
    }
  }

  Future<void> reinitializeLocation() async {
    bool wasLocationEnabled = state.isLocationServiceEnabled;
    await checkLocationService();
    if (!wasLocationEnabled && state.isLocationServiceEnabled) {
      await initializeLocation();
    }
  }

  Future<void> requestLocationPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<void> checkLocationService() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      state.isLocationServiceEnabled = isEnabled;
    });

    if (!isEnabled && mounted) {
      showLocationServiceDialog();
    }
  }

  void showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DeviceScreenColors.cardBackground,
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: DeviceScreenColors.textPrimary),
        ),
        content: const Text(
          'Please enable location services to display your location marker.',
          style: TextStyle(color: DeviceScreenColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DeviceScreenColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text(
              'Settings',
              style: TextStyle(color: DeviceScreenColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    if (!state.isLocationServiceEnabled) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        if (mounted) {
          setState(() {
            state.currentPosition = position;
          });
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void centerMapOnCurrentLocation() {
    if (state.currentPosition != null) {
      mapController.move(
        LatLng(state.currentPosition!.latitude, state.currentPosition!.longitude),
        15.0,
      );
    } else if (state.isLocationServiceEnabled) {
      getCurrentLocation();
    }
  }

  Future<void> refreshLocation() async {
    setState(() {
      state.isGettingLocation = true;
    });

    await checkLocationService();
    if (state.isLocationServiceEnabled) {
      await getCurrentLocation();
    }

    setState(() {
      state.isGettingLocation = false;
    });
  }
}