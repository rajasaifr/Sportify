/// Model for PlaybackState, based on the Analysis Class Diagram.
/// This tracks the synchronized playback status of a video in a room.
class PlaybackState {
  final String roomId; // The ID of the room this state belongs to
  final String contentId; // Links to VideoContent
  final int currentPosition; // Position in seconds
  final bool isPlaying;
  final DateTime? lastUpdated; // When this state was last changed

  PlaybackState({
    required this.roomId,
    required this.contentId,
    required this.currentPosition,
    required this.isPlaying,
    this.lastUpdated,
  });

  /// Converts this PlaybackState instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'contentId': contentId,
      'currentPosition': currentPosition,
      'isPlaying': isPlaying,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Creates a PlaybackState instance from a JSON Map.
  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      roomId: json['roomId'],
      contentId: json['contentId'],
      currentPosition: json['currentPosition'],
      isPlaying: json['isPlaying'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}
