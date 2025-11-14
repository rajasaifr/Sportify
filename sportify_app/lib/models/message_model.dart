/// Enum for the different types of messages in a room.
enum MessageType { chat, system }

/// Model for Message, based on the Analysis Class Diagram.
/// This represents a single chat or system message in a room.
class Message {
  final String messageId;
  final String roomId; // Links to the Room
  final String senderId; // Links to the UserModel or 'system'
  final String content;
  final DateTime? timestamp;
  final MessageType messageType;

  Message({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.timestamp,
    required this.messageType,
  });

  /// Converts this Message instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'messageType': messageType.name, // Stores enum as a string (e.g., 'chat')
    };
  }

  /// Creates a Message instance from a JSON Map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      // Converts string back to enum, defaulting to 'chat' if invalid
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.chat,
      ),
    );
  }
}
