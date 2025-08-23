import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  List<UserProfile> _searchResults = [];
  List<Friendship> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];

  bool _isSearching = false;
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    FriendService.notificationStream.listen((request) {
      if (mounted) {
        if (request.recipientId == FriendService.currentUserId) {
          // Incoming request
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New friend request from ${request.senderName ?? "Unknown"}',
              ),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => _tabController.animateTo(1),
              ),
            ),
          );
          _loadRequests();
        } else if (request.senderId == FriendService.currentUserId) {
          // Response to our request
          final statusText =
              request.status == RequestStatus.accepted
                  ? 'accepted'
                  : 'declined';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your friend request was $statusText'),
              backgroundColor:
                  request.status == RequestStatus.accepted
                      ? Colors.green
                      : Colors.red,
            ),
          );
          if (request.status == RequestStatus.accepted) {
            _loadFriends();
          }
          _loadRequests();
        }
      }
    });
  }

  Future<void> _loadData() async {
    await Future.wait([_loadFriends(), _loadRequests()]);
  }

  Future<void> _loadFriends() async {
    if (!FriendService.isAuthenticated) return;

    setState(() => _isLoadingFriends = true);
    try {
      final friends = await FriendService.getFriends();
      if (mounted) {
        setState(() => _friends = friends);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load friends: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  Future<void> _loadRequests() async {
    if (!FriendService.isAuthenticated) return;

    setState(() => _isLoadingRequests = true);
    try {
      final incoming = await FriendService.getIncomingRequests();
      final outgoing = await FriendService.getOutgoingRequests();
      if (mounted) {
        setState(() {
          _incomingRequests = incoming;
          _outgoingRequests = outgoing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await FriendService.searchUsersByEmail(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFriendRequest(UserProfile user) async {
    try {
      await FriendService.sendFriendRequest(recipientId: user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.displayName}')),
      );
      _loadRequests(); // Refresh requests
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      await FriendService.respondToFriendRequest(
        requestId: requestId,
        accept: accept,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Request accepted' : 'Request declined'),
        ),
      );
      _loadData(); // Refresh all data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FriendService.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connections')),
        body: const Center(child: Text('Please log in to view connections')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(
              text: 'Requests (${_incomingRequests.length})',
              icon: Icon(Icons.inbox),
            ),
            Tab(text: 'Friends (${_friends.length})', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSearchTab(), _buildRequestsTab(), _buildFriendsTab()],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _isSearching
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _searchUsers(),
            onSubmitted: (_) => _searchUsers(),
          ),
        ),
        Expanded(
          child:
              _searchResults.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                    child:
                        _isSearching
                            ? const CircularProgressIndicator()
                            : const Text('No users found'),
                  )
                  : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                            child:
                                user.avatarUrl == null
                                    ? Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0].toUpperCase()
                                          : '?',
                                    )
                                    : null,
                          ),
                          title: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName
                                : 'Unknown User',
                          ),
                          subtitle: Text(user.email),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _sendFriendRequest(user),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Friend'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_incomingRequests.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Incoming Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _incomingRequests.length,
                itemBuilder: (context, index) {
                  final request = _incomingRequests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          request.senderName?.isNotEmpty == true
                              ? request.senderName![0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(request.senderName ?? 'Unknown User'),
                      subtitle: Text(request.senderEmail ?? 'No email'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed:
                                () => _respondToRequest(request.id, false),
                            child: const Text('Decline'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                () => _respondToRequest(request.id, true),
                            child: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_outgoingRequests.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sent Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _outgoingRequests.length,
                itemBuilder: (context, index) {
                  final request = _outgoingRequests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.schedule, color: Colors.white),
                      ),
                      title: Text(
                        'Request to ${request.senderName ?? "Unknown User"}',
                      ),
                      subtitle: Text(
                        'Sent on ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                      ),
                      trailing: const Chip(
                        label: Text('Pending'),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_incomingRequests.isEmpty && _outgoingRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No friend requests'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return RefreshIndicator(
      onRefresh: _loadFriends,
      child:
          _isLoadingFriends
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No friends yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Text(
                      'Search for users to add friends',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friendship = _friends[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          friendship.friendName?.isNotEmpty == true
                              ? friendship.friendName![0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(friendship.friendName ?? 'Unknown User'),
                      subtitle: Text(friendship.friendEmail ?? 'No email'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showFriendOptions(friendship),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _showFriendOptions(Friendship friendship) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('View Location'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement location viewing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location viewing coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text(
                    'Remove Friend',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _removeFriend(friendship),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _removeFriend(Friendship friendship) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Friend'),
            content: Text(
              'Remove ${friendship.friendName ?? "this user"} from your friends?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FriendService.removeFriend(friendship.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend removed')));
        _loadFriends();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove friend: $e')));
      }
    }
  }
}
