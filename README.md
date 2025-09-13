# SafeSpot

SafeSpot is a Flutter application designed to help users create, manage, and monitor geofenced safe zones with real-time location tracking. Geofencing allows users to define virtual boundaries around real-world locations, and the app provides notifications when a device enters or leaves these zones. It is ideal for personal safety, family monitoring, and device management scenarios.

## Features
- **Real-Time Location Tracking:** Monitor your current location and view your movement history on an interactive map.
- **Geofence Creation:** Draw custom geofence zones directly on the map by adding and moving points.
- **Geofence Management:** Activate, deactivate, and delete geofences. View all your geofences in a convenient list.
- **Location History:** Track and display your recent locations for review, allowing you to analyze movement patterns over time or in case of an emergency.
- **User Authentication:** Secure login and registration flows.
- **Profile & Device Management:** Manage your user profile and connected devices.

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code
- Android/iOS device or emulator

### Installation
1. Clone the repository:
    ```bash
    git clone https://github.com/reymartjohneva/SafeSpot.git
    ```

2. Navigate to the project folder:
    ```bash
    cd safe_spot
    ```

3. Install dependencies:
    ```bash
    flutter pub get
    ```

4. Run the app on Android/iOS:
    ```bash
    flutter run
    ```

    For iOS, make sure to run `pod install` from the `ios/` directory if you haven't already set up the necessary CocoaPods.

## Key Dependencies
- **flutter_map** – A flexible and interactive map widget for rendering geofences and tracking location.
- **geolocator** – Provides location services and permissions, enabling real-time location tracking.
- **latlong2** – Handles geographical coordinates for accurate geofence placement.
- **permission_handler** – Manages device permissions like location access, ensuring proper app functionality.

## Contributing
We welcome contributions! Please fork the repository, create a feature branch, and submit a pull request. For more detailed instructions on contributing, please refer to our [CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgments
- **Flutter & Dart teams** – For providing the foundation to build cross-platform mobile applications. [Flutter](https://flutter.dev/) | [Dart](https://dart.dev/)
- **OpenStreetMap** – For providing the map data. [OpenStreetMap](https://www.openstreetmap.org/)
- **All contributors to SafeSpot** – For their ongoing support and contributions.
