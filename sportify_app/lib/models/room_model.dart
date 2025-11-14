/// Enum for different room types, based on the Analysis Class Diagram.
/// This helps us apply the Open/Closed Principle.
enum RoomType { public, private, rival }

/// Model for Room, combining all room types from the Analysis Class Diagram.
class Room {
  final String roomId;
  final String name;
  final String? description;
  final RoomType roomType;
  final String contentId; // Links to VideoContent
  final List<String> participants; // List of userIds
  final DateTime? createdAt;
  final String hostId; // Links to UserModel
  final Map<String, dynamic>? privacySettings; // For private rooms

  // Fields for RivalRoom
  final String? team1Name;
  final String? team2Name;
  final bool? competitiveFeatures;

  Room({
    required this.roomId,
    required this.name,
    this.description,
    required this.roomType,
    required this.contentId,
    this.participants = const [],
    this.createdAt,
    required this.hostId,
    this.privacySettings,
    this.team1Name,
    this.team2Name,
    this.competitiveFeatures,
  });

  /// Converts this Room instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'name': name,
      'description': description,
      'roomType': roomType.name, // Stores enum as a string (e.g., 'public')
      'contentId': contentId,
      'participants': participants,
      'createdAt': createdAt?.toIso8601String(),
      'hostId': hostId,
      'privacySettings': privacySettings,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'competitiveFeatures': competitiveFeatures,
    };
  }

  /// Creates a Room instance from a JSON Map.
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['roomId'],
      name: json['name'],
      description: json['description'],
      // Converts string back to enum, defaulting to 'public' if invalid
      roomType: RoomType.values.firstWhere(
        (e) => e.name == json['roomType'],
        orElse: () => RoomType.public,
      ),
      contentId: json['contentId'],
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      hostId: json['hostId'],
      privacySettings: json['privacySettings'] != null
          ? Map<String, dynamic>.from(json['privacySettings'])
          : null,
      team1Name: json['team1Name'],
      team2Name: json['team2Name'],
      competitiveFeatures: json['competitiveFeatures'],
    );
  }
}
