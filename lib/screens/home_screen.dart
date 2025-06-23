import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Sample data for map markers
  final List<MapMarker> _markers = [
    MapMarker(id: 1, title: "Safe Zone A", lat: 8.9511, lng: 125.5439, isActive: true),
    MapMarker(id: 2, title: "Safe Zone B", lat: 8.9567, lng: 125.5401, isActive: true),
    MapMarker(id: 3, title: "Alert Area", lat: 8.9489, lng: 125.5478, isActive: false),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(),
          _buildSettingsScreen(),
          _buildMessageScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red.shade300,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        // App Bar
        Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100,
                Colors.red.shade100,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade100,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green.shade800,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'SafeSpot',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade300,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Implement notifications
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        // Map Container
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Map placeholder (you'll replace this with actual map widget)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade100,
                          Colors.green.shade50,
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: MapPainter(_markers),
                    ),
                  ),

                  // Map controls
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: "zoom_in",
                          onPressed: () {
                            // Implement zoom in
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.add, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "zoom_out",
                          onPressed: () {
                            // Implement zoom out
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.remove, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: "my_location",
                          onPressed: () {
                            // Center map on user location
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  // Legend
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Safe Zones", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Alert Areas", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Quick Actions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement emergency alert
                  },
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text("Emergency Alert"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implement report incident
                  },
                  icon: const Icon(Icons.report, color: Colors.black),
                  label: const Text("Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your alerts and notifications',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.location_on,
            title: 'Location Services',
            subtitle: 'GPS and location permissions',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Account security settings',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.red.shade300),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMessageScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMessageTile(
            title: 'Emergency Alert System',
            message: 'Safety alert in your area',
            time: '2 min ago',
            isUnread: true,
          ),
          _buildMessageTile(
            title: 'Community Update',
            message: 'New safe zone established nearby',
            time: '1 hour ago',
            isUnread: false,
          ),
          _buildMessageTile(
            title: 'System Notification',
            message: 'Your location services are active',
            time: '3 hours ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile({
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnread ? Colors.red.shade300 : Colors.grey.shade300,
          child: Icon(
            Icons.message,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(message),
        trailing: Text(
          time,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.red.shade100,
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'john.doe@email.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildProfileOption(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.history,
                  title: 'Activity History',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.shield,
                  title: 'Emergency Contacts',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    // Implement logout functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.red.shade300),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Data model for map markers
class MapMarker {
  final int id;
  final String title;
  final double lat;
  final double lng;
  final bool isActive;

  MapMarker({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    required this.isActive,
  });
}

// Custom painter for the map visualization
class MapPainter extends CustomPainter {
  final List<MapMarker> markers;

  MapPainter(this.markers);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 10; i++) {
      double x = (size.width / 10) * i;
      double y = (size.height / 10) * i;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw markers
    for (var marker in markers) {
      final markerPaint = Paint()
        ..color = marker.isActive ? Colors.green : Colors.red;

      double x = (marker.lng - 125.530) * 2000 + size.width * 0.3;
      double y = (8.960 - marker.lat) * 2000 + size.height * 0.3;

      canvas.drawCircle(Offset(x, y), 8, markerPaint);

      // Draw marker border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), 8, borderPaint);
    }

    // Draw roads/paths
    final roadPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
      roadPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}