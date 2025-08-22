import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

enum RequestStatus { pending, accepted, declined }

class FriendRequest {
  final String id;
  final String senderId;
  final String recipientId;
  final RequestStatus status;
  final DateTime createdAt;
  final String? senderName;
  final String? senderEmail;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.senderName,
    this.senderEmail,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      recipientId: map['recipient_id'] as String,
      status: _statusFromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      senderName: map['sender_name'] as String?,
      senderEmail: map['sender_email'] as String?,
    );
  }

  static RequestStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'declined':
        return RequestStatus.declined;
      default:
        return RequestStatus.pending;
    }
  }
}

class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final DateTime createdAt;
  final String? friendName;
  final String? friendEmail;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
    this.friendName,
    this.friendEmail,
  });

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      friendId: map['friend_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      friendName: map['friend_name'] as String?,
      friendEmail: map['friend_email'] as String?,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  String get displayName => fullName ?? '$firstName $lastName'.trim();
}

/// Friend service using Supabase
class FriendService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static final StreamController<FriendRequest> _notificationController =
      StreamController<FriendRequest>.broadcast();

  static Stream<FriendRequest> get notificationStream =>
      _notificationController.stream;

  /// Check if user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Initialize the service and set up real-time subscriptions
  static Future<void> init() async {
    if (!isAuthenticated) return;

    try {
      // Set up real-time subscription for friend requests
      _supabase
          .from('friend_requests')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', currentUserId!)
          .listen((List<Map<String, dynamic>> data) {
            for (var item in data) {
              if (item['status'] == 'pending') {
                _notificationController.add(FriendRequest.fromMap(item));
              }
            }
          });
    } catch (e) {
      print('Error initializing friend service: $e');
    }
  }

  /// Search users by email
  static Future<List<UserProfile>> searchUsersByEmail(String email) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, first_name, last_name, full_name, avatar_url')
          .ilike('email', '%$email%')
          .neq('id', currentUserId!)
          .limit(20);

      return response.map((data) => UserProfile.fromMap(data)).toList();
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Get user profile by ID
  static Future<UserProfile?> getUserById(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('id, email, first_name, last_name, full_name, avatar_url')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromMap(response);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Check if users are already friends
  static Future<bool> areAlreadyFriends(String userId1, String userId2) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select('id')
          .or(
            'and(user_id.eq.$userId1,friend_id.eq.$userId2),and(user_id.eq.$userId2,friend_id.eq.$userId1)',
          )
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check for existing pending request between users
  static Future<FriendRequest?> getExistingPendingRequest(
    String userId1,
    String userId2,
  ) async {
    try {
      final response =
          await _supabase
              .from('friend_requests')
              .select('*')
              .or(
                'and(sender_id.eq.$userId1,recipient_id.eq.$userId2),and(sender_id.eq.$userId2,recipient_id.eq.$userId1)',
              )
              .eq('status', 'pending')
              .maybeSingle();

      if (response == null) return null;
      return FriendRequest.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Send a friend request
  static Future<FriendRequest> sendFriendRequest({
    required String recipientId,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final senderId = currentUserId!;

    if (senderId == recipientId) {
      throw Exception('Cannot send request to yourself');
    }

    // Check if already friends
    if (await areAlreadyFriends(senderId, recipientId)) {
      throw Exception('Already friends with this user');
    }

    // Check for existing pending request
    final existing = await getExistingPendingRequest(senderId, recipientId);
    if (existing != null) {
      if (existing.senderId == senderId) {
        throw Exception('Friend request already sent');
      } else {
        throw Exception('This user has already sent you a friend request');
      }
    }

    try {
      final response =
          await _supabase
              .from('friend_requests')
              .insert({
                'sender_id': senderId,
                'recipient_id': recipientId,
                'status': 'pending',
              })
              .select()
              .single();

      final request = FriendRequest.fromMap(response);

      // Notify recipient
      _notificationController.add(request);

      return request;
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Get incoming friend requests with sender details
  static Future<List<FriendRequest>> getIncomingRequests() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // First get the requests
      final requests = await _supabase
          .from('friend_requests')
          .select('*')
          .eq('recipient_id', currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Then get sender details for each request
      List<FriendRequest> requestsWithDetails = [];

      for (var requestData in requests) {
        final senderId = requestData['sender_id'] as String;

        // Get sender profile
        final senderProfile = await getUserById(senderId);

        requestsWithDetails.add(
          FriendRequest(
            id: requestData['id'],
            senderId: requestData['sender_id'],
            recipientId: requestData['recipient_id'],
            status: RequestStatus.pending,
            createdAt: DateTime.parse(requestData['created_at']),
            senderName: senderProfile?.displayName,
            senderEmail: senderProfile?.email,
          ),
        );
      }

      return requestsWithDetails;
    } catch (e) {
      throw Exception('Failed to get incoming requests: $e');
    }
  }

  /// Get outgoing friend requests with recipient details
  static Future<List<FriendRequest>> getOutgoingRequests() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // First get the requests
      final requests = await _supabase
          .from('friend_requests')
          .select('*')
          .eq('sender_id', currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Then get recipient details for each request
      List<FriendRequest> requestsWithDetails = [];

      for (var requestData in requests) {
        final recipientId = requestData['recipient_id'] as String;

        // Get recipient profile
        final recipientProfile = await getUserById(recipientId);

        requestsWithDetails.add(
          FriendRequest(
            id: requestData['id'],
            senderId: requestData['sender_id'],
            recipientId: requestData['recipient_id'],
            status: RequestStatus.pending,
            createdAt: DateTime.parse(requestData['created_at']),
            senderName:
                recipientProfile
                    ?.displayName, // Using senderName field for recipient name in UI
            senderEmail: recipientProfile?.email,
          ),
        );
      }

      return requestsWithDetails;
    } catch (e) {
      throw Exception('Failed to get outgoing requests: $e');
    }
  }

  /// Respond to a friend request (accept or decline)
  static Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Get the request details first
      final requestResponse =
          await _supabase
              .from('friend_requests')
              .select('*')
              .eq('id', requestId)
              .single();

      final request = FriendRequest.fromMap(requestResponse);

      // Update request status
      await _supabase
          .from('friend_requests')
          .update({'status': accept ? 'accepted' : 'declined'})
          .eq('id', requestId);

      if (accept) {
        // Create friendship record (both directions)
        await _supabase.from('friendships').insert({
          'user_id': request.senderId,
          'friend_id': request.recipientId,
        });

        await _supabase.from('friendships').insert({
          'user_id': request.recipientId,
          'friend_id': request.senderId,
        });
      }

      // Notify the sender about the response
      _notificationController.add(
        FriendRequest(
          id: request.id,
          senderId: request.senderId,
          recipientId: request.recipientId,
          status: accept ? RequestStatus.accepted : RequestStatus.declined,
          createdAt: request.createdAt,
        ),
      );
    } catch (e) {
      throw Exception('Failed to respond to friend request: $e');
    }
  }

  /// Get user's friends list
  static Future<List<Friendship>> getFriends() async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Get friendships where current user is the user_id
      final friendships = await _supabase
          .from('friendships')
          .select('*')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      // Get friend details for each friendship
      List<Friendship> friendsWithDetails = [];

      for (var friendshipData in friendships) {
        final friendId = friendshipData['friend_id'] as String;

        // Get friend profile
        final friendProfile = await getUserById(friendId);

        friendsWithDetails.add(
          Friendship(
            id: friendshipData['id'],
            userId: friendshipData['user_id'],
            friendId: friendshipData['friend_id'],
            createdAt: DateTime.parse(friendshipData['created_at']),
            friendName: friendProfile?.displayName,
            friendEmail: friendProfile?.email,
          ),
        );
      }

      return friendsWithDetails;
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  /// Remove a friend (removes both directions)
  static Future<void> removeFriend(String friendshipId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Get the friendship to find the reverse relationship
      final friendship =
          await _supabase
              .from('friendships')
              .select('*')
              .eq('id', friendshipId)
              .single();

      final userId = friendship['user_id'] as String;
      final friendId = friendship['friend_id'] as String;

      // Delete both directions of the friendship
      await _supabase.from('friendships').delete().eq('id', friendshipId);

      // Delete the reverse friendship
      await _supabase
          .from('friendships')
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', userId);
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    _notificationController.close();
  }
}
