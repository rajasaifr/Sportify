import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/message_model.dart';
import 'package:sportify_app/models/team_model.dart';
import 'package:sportify_app/models/sport_model.dart';
import 'package:sportify_app/services/interfaces/firestore_service_interface.dart';
import 'package:sportify_app/repositories/user_repository.dart';
import 'package:sportify_app/repositories/room_repository.dart';
import 'package:sportify_app/repositories/friendship_repository.dart';
import 'package:sportify_app/utils/logger.dart';

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

  /// Generates a random room code for private rooms (format: Cr23AB)
  String _generateRoomCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final numbers = '0123456789';
    
    // Generate 2 letters + 2 numbers + 2 letters (e.g., Cr23AB)
    final letter1 = letters[(random % letters.length)];
    final letter2 = letters[((random ~/ letters.length) % letters.length)];
    final num1 = numbers[((random ~/ (letters.length * letters.length)) % numbers.length)];
    final num2 = numbers[((random ~/ (letters.length * letters.length * numbers.length)) % numbers.length)];
    final letter3 = letters[((random ~/ (letters.length * letters.length * numbers.length * numbers.length)) % letters.length)];
    final letter4 = letters[((random ~/ (letters.length * letters.length * letters.length * numbers.length * numbers.length)) % letters.length)];
    
    return '$letter1$letter2$num1$num2$letter3$letter4';
  }

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
      // Generate room code for private rooms
      final roomCode = roomType == RoomType.private ? _generateRoomCode() : null;
      
      Room newRoom = Room(
        roomId: roomId,
        name: name,
        description: description,
        roomType: roomType,
        contentId: contentId,
        participants: [hostId],
        createdAt: DateTime.now(),
        hostId: hostId,
        roomCode: roomCode,
        team1Name: team1Name,
        team2Name: team2Name,
        competitiveFeatures: roomType == RoomType.rival,
      );

      // Use repository for data access
      await _roomRepository.createRoom(newRoom);
      return roomId;
    } catch (e) {
      Logger.error("Error creating room", error: e, tag: 'FirestoreService');
      return null;
    }
  }

  // --- (UC-11) Gets a real-time stream of all public rooms for the lobby. ---
  @override
  Stream<List<Room>> getPublicRoomsStream() {
    // Use repository for data access (Abstraction)
    return _roomRepository.getPublicRoomsStream();
  }

  /// Gets a real-time stream of all rooms (public and private)
  @override
  Stream<List<Room>> getAllRoomsStream() {
    return _roomRepository.getAllRoomsStream();
  }

  /// Gets a single room by its ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      return await _roomRepository.getRoomById(roomId);
    } catch (e) {
      Logger.error("Error fetching room by ID",
          error: e, tag: 'FirestoreService');
      return null;
    }
  }

  /// Updates an existing room
  @override
  Future<void> updateRoom(Room room) async {
    try {
      await _roomRepository.updateRoom(room);
    } catch (e) {
      Logger.error("Error updating room", error: e, tag: 'FirestoreService');
      throw Exception('Failed to update room');
    }
  }

  /// Deletes a room and all its messages
  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await _roomRepository.deleteRoom(roomId);
    } catch (e) {
      Logger.error("Error deleting room", error: e, tag: 'FirestoreService');
      throw Exception('Failed to delete room');
    }
  }

  // --- Video Content Functions (UC-04) ---

  /// Fetches a single video by contentId
  /// First tries to find by document ID, then queries by contentId field if not found
  Future<VideoContent?> getVideoById(String contentId) async {
    try {
      // First, try to get by document ID (most common case)
      final doc = await _firestore.collection('videos').doc(contentId).get();
      if (doc.exists) {
        Logger.debug("Video found by document ID: $contentId",
            tag: 'FirestoreService');
        final data = doc.data()!;
        // Ensure contentId is set correctly
        return VideoContent.fromJson({
          ...data,
          'contentId': data['contentId'] ?? data['contenId'] ?? contentId,
        });
      }

      // If not found by document ID, query by contentId field
      Logger.debug(
          "Video not found by document ID, querying by contentId field: $contentId",
          tag: 'FirestoreService');
      final querySnapshot = await _firestore
          .collection('videos')
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Logger.debug("Video found by contentId field query",
            tag: 'FirestoreService');
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return VideoContent.fromJson({
          ...data,
          'contentId': data['contentId'] ?? data['contenId'] ?? contentId,
        });
      }

      // Also try with the typo 'contenId' field
      final typoQuerySnapshot = await _firestore
          .collection('videos')
          .where('contenId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (typoQuerySnapshot.docs.isNotEmpty) {
        Logger.debug("Video found by contenId (typo) field query",
            tag: 'FirestoreService');
        final doc = typoQuerySnapshot.docs.first;
        final data = doc.data();
        return VideoContent.fromJson({
          ...data,
          'contentId': data['contentId'] ?? data['contenId'] ?? contentId,
        });
      }

      Logger.warning("Video not found with contentId: $contentId",
          tag: 'FirestoreService');
      return null;
    } catch (e) {
      Logger.error("Error fetching video by ID",
          error: e, tag: 'FirestoreService');
      return null;
    }
  }

  /// Fetches a list of all available videos.
  /// Assumes videos are stored in a collection named 'videos'.
  @override
  Future<List<VideoContent>> getAvailableVideos() async {
    try {
      // 1. Get all documents from the 'videos' collection
      QuerySnapshot snapshot = await _firestore.collection('videos').get();

      // 2. Map each document into a VideoContent object
      List<VideoContent> videos = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Debug: Log document data
          Logger.debug("Processing video document: ${doc.id}",
              tag: 'FirestoreService');
          Logger.debug("Fields: ${data.keys.toList()}",
              tag: 'FirestoreService');

          // Check for common issues
          if (!data.containsKey('contentId') && data.containsKey('contenId')) {
            Logger.warning("Found typo: 'contenId' should be 'contentId'",
                tag: 'FirestoreService');
          }
          if (data['videoUrls'] is String) {
            Logger.debug("videoUrls is a string, will convert to map",
                tag: 'FirestoreService');
          }
          if (data['thumbnailUrl'] is Map) {
            Logger.debug("thumbnailUrl is a map, will extract youtube value",
                tag: 'FirestoreService');
          }

          videos.add(VideoContent.fromJson(data));
        } catch (e, stackTrace) {
          Logger.error("Error parsing video document ${doc.id}",
              error: e, stackTrace: stackTrace, tag: 'FirestoreService');
          // Continue with other documents
        }
      }

      Logger.info("Successfully loaded ${videos.length} videos",
          tag: 'FirestoreService');
      return videos;
    } catch (e) {
      Logger.error("Error fetching videos", error: e, tag: 'FirestoreService');
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
      Logger.error("Error sending friend request",
          error: e, tag: 'FirestoreService');
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
      Logger.error("Error sending chat message",
          error: e, tag: 'FirestoreService');
    }
  }

  /// Gets a real-time stream of messages for a room
  @override
  Stream<List<Message>> getMessagesStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromJson({
          ...doc.data(),
          'messageId': doc.id,
        });
      }).toList();
    });
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
      Logger.error("Error searching users", error: e, tag: 'FirestoreService');
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
      Logger.error("Error accepting friend request",
          error: e, tag: 'FirestoreService');
      throw Exception('Failed to accept friend request');
    }
  }

  @override
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      // Use repository for data access (Abstraction)
      await _friendshipRepository.deleteFriendship(friendshipId);
    } catch (e) {
      Logger.error("Error declining friend request",
          error: e, tag: 'FirestoreService');
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
      Logger.error("Error getting user by ID",
          error: e, tag: 'FirestoreService');
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
      Logger.error("Error checking friendship",
          error: e, tag: 'FirestoreService');
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
      Logger.error("Error getting friendship status",
          error: e, tag: 'FirestoreService');
      return null;
    }
  }

  @override
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      // Use repository for data access (Abstraction)
      await _friendshipRepository.deleteFriendship(friendshipId);
    } catch (e) {
      Logger.error("Error deleting friendship",
          error: e, tag: 'FirestoreService');
      throw Exception('Failed to delete friendship');
    }
  }


  // --- Team Functions ---

  /// Gets teams from Firestore by sport
  Future<List<Team>> getTeamsBySport(String sport, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot;
      
      // Query teams collection filtered by sport
      snapshot = await _firestore
          .collection('teams')
          .where('sport', isEqualTo: sport)
          .limit(limit)
          .get();

      List<Team> teams = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Add document ID if not present
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          teams.add(Team.fromJson(data));
        } catch (e) {
          Logger.error("Error parsing team document ${doc.id}", error: e, tag: 'FirestoreService');
        }
      }

      Logger.info("Fetched ${teams.length} teams for sport: $sport", tag: 'FirestoreService');
      return teams;
    } catch (e) {
      Logger.error("Error fetching teams by sport: $sport", error: e, tag: 'FirestoreService');
      return [];
    }
  }

  /// Gets all teams from Firestore
  Future<List<Team>> getAllTeams({int limit = 100}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('teams')
          .limit(limit)
          .get();

      List<Team> teams = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Add document ID if not present
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          teams.add(Team.fromJson(data));
        } catch (e) {
          Logger.error("Error parsing team document ${doc.id}", error: e, tag: 'FirestoreService');
        }
      }

      Logger.info("Fetched ${teams.length} teams from Firestore", tag: 'FirestoreService');
      return teams;
    } catch (e) {
      Logger.error("Error fetching all teams", error: e, tag: 'FirestoreService');
      return [];
    }
  }

  /// Gets a team by name from Firestore
  Future<Team?> getTeamByName(String teamName) async {
    try {
      // Try exact match first
      QuerySnapshot snapshot = await _firestore
          .collection('teams')
          .where('name', isEqualTo: teamName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Try case-insensitive search by getting all and filtering
        final allTeams = await getAllTeams(limit: 500);
        for (var team in allTeams) {
          if (team.name.toLowerCase() == teamName.toLowerCase()) {
            return team;
          }
        }
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('id')) {
        data['id'] = doc.id;
      }
      return Team.fromJson(data);
    } catch (e) {
      Logger.error("Error fetching team by name: $teamName", error: e, tag: 'FirestoreService');
      return null;
    }
  }

  /// Gets teams stream for real-time updates
  Stream<List<Team>> getTeamsBySportStream(String sport, {int limit = 10}) {
    return _firestore
        .collection('teams')
        .where('sport', isEqualTo: sport)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      List<Team> teams = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          teams.add(Team.fromJson(data));
        } catch (e) {
          Logger.error("Error parsing team document ${doc.id}", error: e, tag: 'FirestoreService');
        }
      }
      return teams;
    });
  }

  // --- Sport Functions ---

  /// Gets sports from Firestore
  Future<List<Sport>> getSports({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sports')
          .limit(limit)
          .get();

      List<Sport> sports = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          // Add document ID if not present
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          sports.add(Sport.fromJson(data));
        } catch (e) {
          Logger.error("Error parsing sport document ${doc.id}", error: e, tag: 'FirestoreService');
        }
      }

      Logger.info("Fetched ${sports.length} sports from Firestore", tag: 'FirestoreService');
      return sports;
    } catch (e) {
      Logger.error("Error fetching sports", error: e, tag: 'FirestoreService');
      return [];
    }
  }

  /// Gets a sport by name from Firestore
  Future<Sport?> getSportByName(String sportName) async {
    try {
      // Try exact match first
      QuerySnapshot snapshot = await _firestore
          .collection('sports')
          .where('name', isEqualTo: sportName)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Try case-insensitive search
        final allSports = await getSports(limit: 100);
        for (var sport in allSports) {
          if (sport.name.toLowerCase() == sportName.toLowerCase()) {
            return sport;
          }
        }
        return null;
      }

      final doc = snapshot.docs.first;
      final data = Map<String, dynamic>.from(doc.data() as Map);
      if (!data.containsKey('id')) {
        data['id'] = doc.id;
      }
      return Sport.fromJson(data);
    } catch (e) {
      Logger.error("Error fetching sport by name: $sportName", error: e, tag: 'FirestoreService');
      return null;
    }
  }

  /// Gets sports stream for real-time updates
  Stream<List<Sport>> getSportsStream({int limit = 10}) {
    return _firestore
        .collection('sports')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      List<Sport> sports = [];
      for (var doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          sports.add(Sport.fromJson(data));
        } catch (e) {
          Logger.error("Error parsing sport document ${doc.id}", error: e, tag: 'FirestoreService');
        }
      }
      return sports;
    });
  }

  // --- Room Rating Functions ---

  /// Submits a rating for a room (1-5 stars)
  /// If user has already rated, updates their existing rating
  Future<void> submitRoomRating({
    required String roomId,
    required String userId,
    required int stars, // 1-5
  }) async {
    try {
      if (stars < 1 || stars > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if user has already rated this room
      final existingRatingDoc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('ratings')
          .doc(userId)
          .get();

      final int previousRating;
      if (existingRatingDoc.exists) {
        previousRating = existingRatingDoc.data()?['stars'] ?? 0;
      } else {
        previousRating = 0;
      }

      // Save the rating
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('ratings')
          .doc(userId)
          .set({
        'stars': stars,
        'userId': userId,
        'roomId': roomId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Update room's average rating
      await _updateRoomAverageRating(roomId, previousRating, stars);
    } catch (e) {
      Logger.error("Error submitting room rating", error: e, tag: 'FirestoreService');
      rethrow;
    }
  }

  /// Updates the room's average rating based on all ratings
  Future<void> _updateRoomAverageRating(
    String roomId,
    int previousRating,
    int newRating,
  ) async {
    try {
      // Get all ratings for this room
      final ratingsSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        // No ratings, set to null
        await _firestore.collection('rooms').doc(roomId).update({
          'averageRating': null,
          'totalRatings': 0,
        });
        return;
      }

      // Calculate average
      int totalStars = 0;
      for (var doc in ratingsSnapshot.docs) {
        final stars = doc.data()['stars'] as int? ?? 0;
        totalStars += stars;
      }

      final totalRatings = ratingsSnapshot.docs.length;
      final averageRating = totalStars / totalRatings;

      // Update room document
      await _firestore.collection('rooms').doc(roomId).update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      Logger.error("Error updating room average rating", error: e, tag: 'FirestoreService');
      rethrow;
    }
  }

  /// Gets a user's rating for a room
  Future<int?> getUserRoomRating(String roomId, String userId) async {
    try {
      final ratingDoc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (ratingDoc.exists) {
        return ratingDoc.data()?['stars'] as int?;
      }
      return null;
    } catch (e) {
      Logger.error("Error getting user room rating", error: e, tag: 'FirestoreService');
      return null;
    }
  }

  /// Search public rooms by name, sorted by rating (descending)
  Future<List<Room>> searchPublicRooms(String query) async {
    try {
      return await _roomRepository.searchPublicRooms(query);
    } catch (e) {
      Logger.error("Error searching rooms", error: e, tag: 'FirestoreService');
      return [];
    }
  }
}
