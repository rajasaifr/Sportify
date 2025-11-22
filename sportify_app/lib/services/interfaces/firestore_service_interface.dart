import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/message_model.dart';

/// Interface for Firestore service
/// Applies Dependency Inversion Principle (DIP) - depend on abstractions
abstract class IFirestoreService {
  // Room Functions
  Future<String?> createRoom({
    required String name,
    required String contentId,
    required String hostId,
    required RoomType roomType,
    String? description,
    String? team1Name,
    String? team2Name,
  });

  Stream<List<Room>> getPublicRoomsStream();
  Stream<List<Room>> getAllRoomsStream();
  Future<void> updateRoom(Room room);
  Future<void> deleteRoom(String roomId);

  // Video Content Functions
  Future<List<VideoContent>> getAvailableVideos();

  // Friendship Functions
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
  });

  Stream<List<Friendship>> getFriendshipsForUser(String userId);
  Stream<List<Friendship>> getPendingRequestsReceived(String userId);
  Future<Friendship?> getFriendshipBetweenUsers(String user1Id, String user2Id);
  Future<FriendshipStatus?> getFriendshipStatus(String currentUserId, String otherUserId);
  Future<void> acceptFriendRequest(String friendshipId);
  Future<void> declineFriendRequest(String friendshipId);
  Future<void> deleteFriendship(String friendshipId);
  Future<List<UserModel>> searchUsers(String searchQuery);
  Future<UserModel?> getUserById(String userId);

  // Message Functions
  Future<void> sendChatMessage({
    required String roomId,
    required String senderId,
    required String content,
  });

  Stream<List<Message>> getMessagesStream(String roomId);
}

