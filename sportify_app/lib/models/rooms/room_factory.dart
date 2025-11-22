import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/rooms/base_room.dart';

/// Factory pattern for creating different room types
/// Applies Polymorphism - creates different room types based on RoomType
/// Applies Open/Closed Principle (OCP) - easy to add new room types without modifying existing code
class RoomFactory {
  /// Factory method to create appropriate room type
  /// Applies Polymorphism - returns BaseRoom but creates specific implementations
  static BaseRoom createRoom({
    required String roomId,
    required String name,
    String? description,
    required String contentId,
    required String hostId,
    required RoomType roomType,
    List<String>? participants,
    DateTime? createdAt,
    Map<String, dynamic>? privacySettings,
    String? team1Name,
    String? team2Name,
  }) {
    switch (roomType) {
      case RoomType.public:
        return PublicRoom(
          roomId: roomId,
          name: name,
          description: description,
          contentId: contentId,
          hostId: hostId,
          participants: participants ?? [],
          createdAt: createdAt,
        );

      case RoomType.private:
        return PrivateRoom(
          roomId: roomId,
          name: name,
          description: description,
          contentId: contentId,
          hostId: hostId,
          participants: participants ?? [],
          createdAt: createdAt,
          privacySettings: privacySettings ?? {},
        );

      case RoomType.rival:
        if (team1Name == null || team2Name == null) {
          throw ArgumentError('Rival rooms require both team1Name and team2Name');
        }
        return RivalRoom(
          roomId: roomId,
          name: name,
          description: description,
          contentId: contentId,
          hostId: hostId,
          participants: participants ?? [],
          createdAt: createdAt,
          team1Name: team1Name,
          team2Name: team2Name,
        );
    }
  }

  /// Create room from Room model (for deserialization)
  static BaseRoom fromRoomModel(Room room) {
    return createRoom(
      roomId: room.roomId,
      name: room.name,
      description: room.description,
      contentId: room.contentId,
      hostId: room.hostId,
      roomType: room.roomType,
      participants: room.participants,
      createdAt: room.createdAt,
      privacySettings: room.privacySettings,
      team1Name: room.team1Name,
      team2Name: room.team2Name,
    );
  }
}

