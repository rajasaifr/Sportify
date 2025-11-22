import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking video playback state in a room
class PlaybackState {
  final String roomId;
  final String userId;
  final bool isPlaying;
  final double currentTime; // Current playback time in seconds
  final DateTime lastUpdated;
  final bool isHost;

  PlaybackState({
    required this.roomId,
    required this.userId,
    required this.isPlaying,
    required this.currentTime,
    required this.lastUpdated,
    required this.isHost,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'isPlaying': isPlaying,
      'currentTime': currentTime,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isHost': isHost,
    };
  }

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      roomId: json['roomId'] ?? '',
      userId: json['userId'] ?? '',
      isPlaying: json['isPlaying'] ?? false,
      currentTime: (json['currentTime'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] is Timestamp
              ? (json['lastUpdated'] as Timestamp).toDate()
              : DateTime.parse(json['lastUpdated'].toString()))
          : DateTime.now(),
      isHost: json['isHost'] ?? false,
    );
  }

  PlaybackState copyWith({
    String? roomId,
    String? userId,
    bool? isPlaying,
    double? currentTime,
    DateTime? lastUpdated,
    bool? isHost,
  }) {
    return PlaybackState(
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      isPlaying: isPlaying ?? this.isPlaying,
      currentTime: currentTime ?? this.currentTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isHost: isHost ?? this.isHost,
    );
  }
}
