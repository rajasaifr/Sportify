import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Room Functions (UC-08, UC-09, UC-10) ---

  /// Creates a new room (public, private, or rival) and saves it to Firestore.
  /// Returns the ID of the newly created room.
  Future<String?> createRoom({
    required String name,
    required String contentId,
    required String hostId,
    required RoomType roomType,
    String? description,
    // For Rival Rooms
    String? team1Name,
    String? team2Name,
  }) async {
    try {
      // 1. Create a new document reference in the 'rooms' collection
      DocumentReference roomDoc = _firestore.collection('rooms').doc();

      // 2. Create our new Room object
      Room newRoom = Room(
        roomId: roomDoc.id, // Use the unique ID from the doc reference
        name: name,
        description: description,
        roomType: roomType,
        contentId: contentId,
        participants: [hostId], // The host is the first participant
        createdAt: DateTime.now(),
        hostId: hostId,
        // Rival room fields will be null if not provided
        team1Name: team1Name,
        team2Name: team2Name,
        competitiveFeatures: roomType == RoomType.rival,
      );

      // 3. Save the new room to Firestore by calling toJson()
      await roomDoc.set(newRoom.toJson());

      // 4. Return the new room's ID so we can navigate to it
      return roomDoc.id;
    } catch (e) {
      print("Error creating room: $e"); // Use logger in production
      return null;
    }
  }

  // --- (UC-11) Gets a real-time stream of all public rooms for the lobby. ---
  Stream<List<Room>> getPublicRoomsStream() {
    return _firestore
        .collection('rooms')
        // 2. Filter to only show rooms where 'roomType' is 'public'
        .where('roomType', isEqualTo: RoomType.public.name)
        // --- THIS IS THE FIX ---
        // .orderBy('createdAt', descending: true) // <-- REMOVED this line to avoid needing a composite index
        // --- END OF FIX ---
        .snapshots()
        .map((snapshot) {
      // 5. Convert each document into a Room object
      return snapshot.docs
          .map((doc) => Room.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
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

      // Save to Firestore
      await _firestore
          .collection('friendships')
          .doc(docId)
          .set(newRequest.toJson());
    } catch (e) {
      print("Error sending friend request: $e"); // Use logger
    }
  }

  // --- Message Functions (UC-16) ---

  /// Sends a chat message to a specific room.
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
}
