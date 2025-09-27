# SafeSpot

SafeSpot is a Flutter application designed to help users create, manage, and monitor geofenced safe zones with real-time location tracking. Geofencing allows users to define virtual boundaries around real-world locations, and the app provides notifications when a device enters or leaves these zones. It is ideal for personal safety, family monitoring, and device management scenarios.

## Features
- **Real-Time Location Tracking:** Monitor your current location and view your movement history on an interactive map.
- **Geofence Creation:** Draw custom geofence zones directly on the map by adding and moving points.
- **Geofence Management:** Activate, deactivate, and delete geofences. View all your geofences in a convenient list.
- **Location History:** Track and display your recent locations for review, allowing you to analyze movement patterns over time or in case of an emergency.
- **Movement Prediction:** Advanced LSTM (Long Short-Term Memory) neural network model analyzes historical location data to predict future movement patterns and potential destinations.
- **Predictive Safety Alerts:** Receive proactive notifications when the prediction model identifies potential routes that may lead outside of safe zones.
- **User Authentication:** Secure login and registration flows.
- **Profile & Device Management:** Manage your user profile and connected devices.

## LSTM Movement Prediction Model

SafeSpot incorporates an intelligent movement prediction system powered by LSTM neural networks to enhance safety monitoring and provide proactive alerts.

### How It Works
The LSTM model analyzes patterns in your location history to predict future movements:

1. **Data Collection:** Continuously gathers location data points including coordinates, timestamps, speed, and direction.
2. **Pattern Recognition:** The LSTM model identifies recurring movement patterns, common routes, and typical destinations based on historical data.
3. **Future Prediction:** Predicts likely next locations and movement trajectories up to several hours in advance.
4. **Safety Analysis:** Evaluates predicted paths against configured geofences to identify potential safety concerns before they occur.

### Key Benefits
- **Proactive Safety:** Receive alerts before potentially unsafe situations arise
- **Route Optimization:** Suggests safer alternative routes based on historical patterns
- **Anomaly Detection:** Identifies unusual movement patterns that may indicate emergencies
- **Adaptive Learning:** Model continuously improves predictions as more location data becomes available

### Technical Implementation
- **TensorFlow Lite integration** for on-device inference
- **Sequence-to-sequence LSTM architecture** optimized for time-series location prediction
- **Privacy-focused design** with local model training and inference
- **Configurable prediction horizons** (15 minutes to 4 hours ahead)
- **Real-time model updates** based on recent movement patterns

### Configuration Options
Users can customize the prediction system through the app settings:
- Enable/disable movement predictions
- Configure predictive alert thresholds
- Train personal movement models

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code
- Android/iOS device or emulator
- TensorFlow Lite (automatically included with dependencies)

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
- **tflite_flutter** – TensorFlow Lite integration for running LSTM models on-device.
- **ml_algo** – Machine learning algorithms for data preprocessing and feature engineering.
- **collection** – Enhanced data structures for efficient location data management.

## Model Training & Data Privacy

SafeSpot prioritizes user privacy in its predictive features:

- **Local Training:** LSTM models are trained entirely on-device using your personal location history
- **No Data Sharing:** Location data and movement patterns never leave your device
- **Federated Learning Ready:** Architecture supports federated learning for improved models while maintaining privacy
- **Data Retention:** Users control how long location history is stored for model training

## Contributing
We welcome contributions! Please fork the repository, create a feature branch, and submit a pull request. For more detailed instructions on contributing, please refer to our [CONTRIBUTING.md](CONTRIBUTING.md).

### Areas for Contribution
- LSTM model improvements and optimization
- Additional machine learning features (anomaly detection, clustering)
- Privacy-preserving machine learning techniques
- Model performance benchmarking and testing

## Acknowledgments
- **Flutter & Dart teams** – For providing the foundation to build cross-platform mobile applications. [Flutter](https://flutter.dev/) | [Dart](https://dart.dev/)
- **OpenStreetMap** – For providing the map data. [OpenStreetMap](https://www.openstreetmap.org/)
- **TensorFlow team** – For TensorFlow Lite enabling on-device machine learning. [TensorFlow](https://www.tensorflow.org/)
- **All contributors to SafeSpot** – For their ongoing support and contributions.