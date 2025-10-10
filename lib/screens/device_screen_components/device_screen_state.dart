import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:safe_spot/services/device_service.dart';
import 'package:safe_spot/services/geofence_service.dart';

// Custom color scheme
class DeviceScreenColors {
  static const Color primaryOrange = Color(0xFFFF8A50);
  static const Color darkBackground = Colors.black87;
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
}

// State data class to hold all state variables
class DeviceScreenStateData {
  // Controllers
  final TextEditingController deviceIdController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  final TextEditingController geofenceNameController = TextEditingController();

  // Device state
  List<Device> devices = [];
  Map<String, List<LocationHistory>> deviceLocations = {};
  bool isLoading = false;
  bool isAddingDevice = false;
  String? selectedDeviceId;

  // Location state
  Position? currentPosition;
  bool isLocationServiceEnabled = false;
  bool isGettingLocation = false;

  // Geofence state
  List<Geofence> geofences = [];
  bool isDrawingGeofence = false;
  List<LatLng> currentGeofencePoints = [];
  bool isLoadingGeofences = false;
  bool isSavingGeofence = false;
  bool isDragging = false;
  int? draggedPointIndex;
  LatLng? draggedPointOriginalPosition;

  // Timer
  Timer? refreshTimer;
  static const Duration refreshInterval = Duration(seconds: 30);

  // NEW: History points visibility state
  bool showHistoryPoints = true;

  void dispose() {
    refreshTimer?.cancel();
    deviceIdController.dispose();
    deviceNameController.dispose();
    geofenceNameController.dispose();
  }
}
