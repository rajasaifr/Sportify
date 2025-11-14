/// Enum for the different states an invitation can be in.
enum InvitationStatus { pending, accepted, declined }

/// Model for Invitation, based on the Analysis Class Diagram.
/// This represents an invitation for a user to join a room.
class Invitation {
  final String invitationId;
  final String roomId; // Links to Room
  final String senderId; // Links to UserModel (who sent it)
  final String recipientId; // Links to UserModel (who received it)
  final String? message;
  final InvitationStatus status;
  final DateTime? createdAt;

  Invitation({
    required this.invitationId,
    required this.roomId,
    required this.senderId,
    required this.recipientId,
    this.message,
    this.status = InvitationStatus.pending, // Default status
    this.createdAt,
  });

  /// Converts this Invitation instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'roomId': roomId,
      'senderId': senderId,
      'recipientId': recipientId,
      'message': message,
      'status': status.name, // Stores enum as a string
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Creates an Invitation instance from a JSON Map.
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      invitationId: json['invitationId'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      message: json['message'],
      // Converts string back to enum, defaulting to 'pending' if invalid
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
