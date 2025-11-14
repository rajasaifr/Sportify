/// Enum for the different states a friendship can be in.
enum FriendshipStatus { pending, accepted, declined, blocked }

/// Model for Friendship, based on the Analysis Class Diagram.
/// This represents the connection between two users.
class Friendship {
  final String friendshipId;
  final String user1Id; // The user who sent the request
  final String user2Id; // The user who received the request
  final FriendshipStatus status;
  final DateTime? createdAt;

  Friendship({
    required this.friendshipId,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    this.createdAt,
  });

  /// Converts this Friendship instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'friendshipId': friendshipId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'status': status.name, // Stores enum as a string (e.g., 'pending')
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Creates a Friendship instance from a JSON Map.
  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendshipId: json['friendshipId'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      // Converts string back to enum, defaulting to 'pending' if invalid
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
