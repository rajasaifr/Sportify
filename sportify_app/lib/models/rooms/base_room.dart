import 'package:sportify_app/models/room_model.dart';

/// Abstract base class for different room types
/// Applies Inheritance and Polymorphism - different room types can extend this
/// Applies Open/Closed Principle (OCP) - open for extension, closed for modification
abstract class BaseRoom {
  final String roomId;
  final String name;
  final String? description;
  final String contentId;
  final List<String> participants;
  final DateTime? createdAt;
  final String hostId;

  BaseRoom({
    required this.roomId,
    required this.name,
    this.description,
    required this.contentId,
    this.participants = const [],
    this.createdAt,
    required this.hostId,
  });

  /// Abstract method - each room type must implement its own validation
  /// Applies Polymorphism - different implementations for different room types
  bool validate();

  /// Abstract method - each room type must implement its own creation logic
  Room toRoomModel();

  /// Get room type - must be implemented by subclasses
  RoomType get roomType;
}

/// Public Room implementation
/// Applies Inheritance - extends BaseRoom
class PublicRoom extends BaseRoom {
  PublicRoom({
    required super.roomId,
    required super.name,
    super.description,
    required super.contentId,
    super.participants,
    super.createdAt,
    required super.hostId,
  });

  @override
  bool validate() {
    // Public rooms have minimal validation
    return name.isNotEmpty && contentId.isNotEmpty;
  }

  @override
  Room toRoomModel() {
    return Room(
      roomId: roomId,
      name: name,
      description: description,
      roomType: RoomType.public,
      contentId: contentId,
      participants: participants,
      createdAt: createdAt ?? DateTime.now(),
      hostId: hostId,
    );
  }

  @override
  RoomType get roomType => RoomType.public;
}

/// Private Room implementation
/// Applies Inheritance - extends BaseRoom
class PrivateRoom extends BaseRoom {
  final Map<String, dynamic> privacySettings;

  PrivateRoom({
    required super.roomId,
    required super.name,
    super.description,
    required super.contentId,
    super.participants,
    super.createdAt,
    required super.hostId,
    required this.privacySettings,
  });

  @override
  bool validate() {
    // Private rooms require privacy settings
    return name.isNotEmpty && 
           contentId.isNotEmpty && 
           privacySettings.isNotEmpty;
  }

  @override
  Room toRoomModel() {
    return Room(
      roomId: roomId,
      name: name,
      description: description,
      roomType: RoomType.private,
      contentId: contentId,
      participants: participants,
      createdAt: createdAt ?? DateTime.now(),
      hostId: hostId,
      privacySettings: privacySettings,
    );
  }

  @override
  RoomType get roomType => RoomType.private;
}

/// Rival Room implementation
/// Applies Inheritance - extends BaseRoom
class RivalRoom extends BaseRoom {
  final String team1Name;
  final String team2Name;

  RivalRoom({
    required super.roomId,
    required super.name,
    super.description,
    required super.contentId,
    super.participants,
    super.createdAt,
    required super.hostId,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  bool validate() {
    // Rival rooms require both team names
    return name.isNotEmpty && 
           contentId.isNotEmpty && 
           team1Name.isNotEmpty && 
           team2Name.isNotEmpty &&
           team1Name != team2Name; // Teams must be different
  }

  @override
  Room toRoomModel() {
    return Room(
      roomId: roomId,
      name: name,
      description: description,
      roomType: RoomType.rival,
      contentId: contentId,
      participants: participants,
      createdAt: createdAt ?? DateTime.now(),
      hostId: hostId,
      team1Name: team1Name,
      team2Name: team2Name,
      competitiveFeatures: true,
    );
  }

  @override
  RoomType get roomType => RoomType.rival;
}

