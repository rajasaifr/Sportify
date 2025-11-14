/// Model for Reaction, based on the Analysis Class Diagram.
/// This represents a single emoji reaction sent by a user in a room.
class Reaction {
  final String reactionId;
  final String roomId; // Links to Room
  final String userId; // Links to UserModel
  final String emoji; // The emoji string itself, e.g., "👍"
  final int videoPosition; // Position in seconds when reaction happened
  final DateTime? timestamp;

  Reaction({
    required this.reactionId,
    required this.roomId,
    required this.userId,
    required this.emoji,
    required this.videoPosition,
    this.timestamp,
  });

  /// Converts this Reaction instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'reactionId': reactionId,
      'roomId': roomId,
      'userId': userId,
      'emoji': emoji,
      'videoPosition': videoPosition,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// Creates a Reaction instance from a JSON Map.
  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      reactionId: json['reactionId'],
      roomId: json['roomId'],
      userId: json['userId'],
      emoji: json['emoji'],
      videoPosition: json['videoPosition'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }
}
