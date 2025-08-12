import 'package:flutter/material.dart';

// Models for user data
class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.isOnline = false,
    this.lastSeen,
  });
}

class ConnectionRequest {
  final String id;
  final User sender;
  final User receiver;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  ConnectionRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });
}

// Main Connections Screen with tabs
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with actual data from your backend
  List<User> friends = [
    User(
      id: '1',
      name: 'Alice Johnson',
      email: 'alice@example.com',
      profileImage: null,
      isOnline: true,
    ),
    User(
      id: '2',
      name: 'Bob Smith',
      email: 'bob@example.com',
      profileImage: null,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    User(
      id: '3',
      name: 'Carol Davis',
      email: 'carol@example.com',
      profileImage: null,
      isOnline: true,
    ),
  ];

  List<ConnectionRequest> pendingRequests = [
    ConnectionRequest(
      id: '1',
      sender: User(
        id: '4',
        name: 'David Wilson',
        email: 'david@example.com',
        isOnline: false,
      ),
      receiver: User(id: 'current', name: 'You', email: 'you@example.com'),
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ConnectionRequest(
      id: '2',
      sender: User(
        id: '5',
        name: 'Emma Brown',
        email: 'emma@example.com',
        isOnline: true,
      ),
      receiver: User(id: 'current', name: 'You', email: 'you@example.com'),
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Connections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red.shade300,
          labelColor: Colors.red.shade300,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: [
            Tab(
              text: 'Friends (${friends.length})',
              icon: const Icon(Icons.people),
            ),
            Tab(
              text: 'Requests (${pendingRequests.length})',
              icon: const Icon(Icons.person_add),
            ),
            const Tab(
              text: 'Add Friend',
              icon: Icon(Icons.search),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showScanQRCode(context);
            },
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
          _buildAddFriend(),
        ],
      ),
    );
  }

  // Friends List Tab
  Widget _buildFriendsList() {
    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Friends Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add friends to share your location and stay connected',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendCard(friend);
      },
    );
  }

  Widget _buildFriendCard(User friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.red.shade100,
              child: friend.profileImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  friend.profileImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
                  : Text(
                friend.name.split(' ').map((n) => n[0]).take(2).join(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade300,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: friend.isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(friend.email),
            const SizedBox(height: 4),
            Text(
              friend.isOnline
                  ? 'Online'
                  : friend.lastSeen != null
                  ? 'Last seen ${_formatLastSeen(friend.lastSeen!)}'
                  : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: friend.isOnline ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_location':
                _viewFriendLocation(friend);
                break;
              case 'message':
                _messageFriend(friend);
                break;
              case 'remove':
                _removeFriend(friend);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_location',
              child: ListTile(
                leading: Icon(Icons.location_on),
                title: Text('View Location'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'message',
              child: ListTile(
                leading: Icon(Icons.message),
                title: Text('Send Message'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.person_remove, color: Colors.red),
                title: Text('Remove Friend', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Connection Requests Tab
  Widget _buildRequestsList() {
    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Pending Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll see friend requests here when people want to connect with you',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(ConnectionRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.orange.shade100,
                child: request.sender.profileImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    request.sender.profileImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : Text(
                  request.sender.name.split(' ').map((n) => n[0]).take(2).join(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
              title: Text(
                request.sender.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.sender.email),
                  const SizedBox(height: 4),
                  Text(
                    'Sent ${_formatRequestTime(request.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add Friend Tab
  Widget _buildAddFriend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Friends',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Search by email
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by email',
              hintText: 'Enter friend\'s email address',
              prefixIcon: const Icon(Icons.email),
              suffixIcon: IconButton(
                onPressed: () {
                  // Implement search functionality
                  _searchUserByEmail();
                },
                icon: const Icon(Icons.search),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Other ways to connect
          const Text(
            'Other Ways to Connect',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // QR Code option
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code, color: Colors.blue),
              ),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Scan a friend\'s QR code to connect instantly'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showScanQRCode(context),
            ),
          ),

          const SizedBox(height: 12),

          // Share your QR code
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: Colors.green),
              ),
              title: const Text('Share Your QR Code'),
              subtitle: const Text('Let others scan your code to send you requests'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showShareQRCode(context),
            ),
          ),

          const SizedBox(height: 12),

          // Nearby users
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.orange),
              ),
              title: const Text('Find Nearby Users'),
              subtitle: const Text('Discover SafeSpot users near your location'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _findNearbyUsers(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatRequestTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Action methods
  void _acceptRequest(ConnectionRequest request) {
    setState(() {
      pendingRequests.remove(request);
      friends.add(request.sender);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You are now connected with ${request.sender.name}'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Location',
          textColor: Colors.white,
          onPressed: () => _viewFriendLocation(request.sender),
        ),
      ),
    );
  }

  void _declineRequest(ConnectionRequest request) {
    setState(() {
      pendingRequests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Declined request from ${request.sender.name}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _removeFriend(User friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.name} from your friends list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                friends.remove(friend);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${friend.name} has been removed from your friends'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewFriendLocation(User friend) {
    // Navigate back to home tab and show friend's location
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${friend.name}\'s location on map'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _messageFriend(User friend) {
    // Navigate to message screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${friend.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _searchUserByEmail() {
    // Implement email search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for user...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showScanQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text('QR Code scanner would open here'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showShareQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your QR Code'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code, size: 120, color: Colors.green),
            SizedBox(height: 16),
            Text('Others can scan this code to send you a friend request'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement share functionality
              Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _findNearbyUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for nearby users...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}