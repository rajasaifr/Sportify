import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/message_model.dart';
import 'package:sportify_app/services/interfaces/firestore_service_interface.dart';
import 'package:sportify_app/repositories/user_repository.dart';
import 'package:sportify_app/repositories/room_repository.dart';
import 'package:sportify_app/repositories/friendship_repository.dart';

/// Firestore Service Implementation
/// Applies Single Responsibility Principle (SRP) - coordinates between repositories
/// Implements IFirestoreService interface - Dependency Inversion Principle (DIP)
class FirestoreService implements IFirestoreService {
  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  final RoomRepository _roomRepository;
  final FriendshipRepository _friendshipRepository;

  /// Constructor with dependency injection
  /// Applies Dependency Inversion Principle (DIP)
  FirestoreService({
    FirebaseFirestore? firestore,
    UserRepository? userRepository,
    RoomRepository? roomRepository,
    FriendshipRepository? friendshipRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userRepository = userRepository ?? UserRepository(),
        _roomRepository = roomRepository ?? RoomRepository(),
        _friendshipRepository = friendshipRepository ?? FriendshipRepository();

  // --- Room Functions (UC-08, UC-09, UC-10) ---

  /// Creates a new room (public, private, or rival) and saves it to Firestore.
  /// Returns the ID of the newly created room.
  /// Uses repository pattern (Abstraction, Encapsulation)
  @override
  Future<String?> createRoom({
    required String name,
    required String contentId,
    required String hostId,
    required RoomType roomType,
    String? description,
    String? team1Name,
    String? team2Name,
  }) async {
    try {
      // Create Room object
      final roomId = _firestore.collection('rooms').doc().id;
      Room newRoom = Room(
        roomId: roomId,
        name: name,
        description: description,
        roomType: roomType,
        contentId: contentId,
        participants: [hostId],
        createdAt: DateTime.now(),
        hostId: hostId,
        team1Name: team1Name,
        team2Name: team2Name,
        competitiveFeatures: roomType == RoomType.rival,
      );

      // Use repository for data access
      await _roomRepository.createRoom(newRoom);
      return roomId;
    } catch (e) {
      print("Error creating room: $e");
      return null;
    }
  }

  // --- (UC-11) Gets a real-time stream of all public rooms for the lobby. ---
  @override
  Stream<List<Room>> getPublicRoomsStream() {
    // Use repository for data access (Abstraction)
    return _roomRepository.getPublicRoomsStream();
  }

  // --- Video Content Functions (UC-04) ---

  /// Fetches a list of all available videos.
  /// Assumes videos are stored in a collection named 'videos'.
  Future<List<VideoContent>> getAvailableVideos() async {
    try {
      // 1. Get all documents from the 'videos' collection
      QuerySnapshot snapshot = await _firestore.collection('videos').get();

      // 2. Map each document into a VideoContent object
      List<VideoContent> videos = snapshot.docs.map((doc) {
        // Use fromJson to convert the Map to our model
        return VideoContent.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      return videos;
    } catch (e) {
      print("Error fetching videos: $e"); // Use logger in production
      return []; // Return an empty list on error
    }
  }

  // --- Friendship Functions (UC-03) ---

  /// Sends a friend request by creating a new 'friendship' document.
  @override
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      // Create a unique ID for the friendship document
      String docId = _firestore.collection('friendships').doc().id;

      // Create the friendship model
      Friendship newRequest = Friendship(
        friendshipId: docId,
        user1Id: fromUserId,
        user2Id: toUserId,
        status: FriendshipStatus.pending,
        createdAt: DateTime.now(),
      );

      // Use repository for data access (Abstraction)
      await _friendshipRepository.createFriendship(newRequest);
    } catch (e) {
      print("Error sending friend request: $e");
      rethrow;
    }
  }

  // --- Message Functions (UC-16) ---

  /// Sends a chat message to a specific room.
  @override
  Future<void> sendChatMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Get a new unique ID for the message
      String messageId = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc()
          .id;

      // Create the message model
      Message newMessage = Message(
        messageId: messageId,
        roomId: roomId,
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
        messageType: MessageType.chat,
      );

      // Save it to the 'messages' sub-collection inside the room
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toJson());
    } catch (e) {
      print("Error sending chat message: $e"); // Use logger
    }
  }

  @override
  Stream<List<Friendship>> getFriendshipsForUser(String userId) {
    // Use repository for data access (Abstraction)
    return _friendshipRepository.getFriendshipsForUser(userId);
  }

  @override
  Future<List<UserModel>> searchUsers(String searchQuery) async {
    try {
      // Use repository for data access (Abstraction)
      return await _userRepository.searchUsers(searchQuery);
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  @override
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      // Use repository for data access (Abstraction)
      await _friendshipRepository.updateFriendshipStatus(
        friendshipId,
        FriendshipStatus.accepted,
      );
    } catch (e) {
      print("Error accepting friend request: $e");
      throw Exception('Failed to accept friend request');
    }
  }

  @override
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      // Use repository for data access (Abstraction)
      await _friendshipRepository.deleteFriendship(friendshipId);
    } catch (e) {
      print("Error declining friend request: $e");
      throw Exception('Failed to decline friend request');
    }
  }

  @override
  Stream<List<Friendship>> getPendingRequestsReceived(String userId) {
    // Use repository for data access (Abstraction)
    return _friendshipRepository.getPendingRequestsReceived(userId);
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Use repository for data access (Abstraction)
      return await _userRepository.getUserById(userId);
    } catch (e) {
      print("Error getting user by ID: $e");
      return null;
    }
  }

  @override
  Future<Friendship?> getFriendshipBetweenUsers(
      String user1Id, String user2Id) async {
    try {
      // Use repository for data access (Abstraction)
      return await _friendshipRepository.getFriendshipBetweenUsers(
          user1Id, user2Id);
    } catch (e) {
      print("Error checking friendship: $e");
      return null;
    }
  }

  @override
  Future<FriendshipStatus?> getFriendshipStatus(
      String currentUserId, String otherUserId) async {
    try {
      final friendship =
          await getFriendshipBetweenUsers(currentUserId, otherUserId);
      return friendship?.status;
    } catch (e) {
      print("Error getting friendship status: $e");
      return null;
    }
  }

  @override
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      // Use repository for data access (Abstraction)
      await _friendshipRepository.deleteFriendship(friendshipId);
    } catch (e) {
      print("Error deleting friendship: $e");
      throw Exception('Failed to delete friendship');
    }
  }
}
