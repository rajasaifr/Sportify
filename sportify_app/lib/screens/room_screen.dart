import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/message_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/utils/logger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// Required for web platform iframe embedding
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html show IFrameElement;
import 'dart:ui_web' as ui_web;

class RoomScreen extends StatefulWidget {
  final Room room;

  const RoomScreen({super.key, required this.room});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  VideoContent? _videoContent;
  bool _isLoadingVideo = true;
  String? _videoId;
  late Room _currentRoom = widget.room;

  @override
  void initState() {
    super.initState();
    _loadVideoContent();
  }

  Future<void> _loadVideoContent() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    setState(() => _isLoadingVideo = true);
    
    Logger.info("Loading video for room: ${_currentRoom.name}, contentId: ${_currentRoom.contentId}", tag: 'RoomScreen');
    
    try {
      final video = await firestoreService.getVideoById(_currentRoom.contentId);
      
      if (video != null && mounted) {
        Logger.info("Video found: ${video.title}, videoUrls: ${video.videoUrls}", tag: 'RoomScreen');
        
        // Extract YouTube video ID from videoUrls
        String? videoId = _extractYouTubeVideoId(video.videoUrls);
        
        Logger.debug("Extracted video ID from videoUrls: $videoId", tag: 'RoomScreen');
        
        // If extraction failed, try using contentId directly if it looks like a YouTube ID
        if (videoId == null) {
          videoId = _tryContentIdAsVideoId(_currentRoom.contentId);
          Logger.debug("Trying contentId as video ID: $videoId", tag: 'RoomScreen');
        }
        
        if (videoId != null && mounted) {
          Logger.info("Using video ID: $videoId", tag: 'RoomScreen');
          setState(() {
            _videoContent = video;
            _videoId = videoId;
            _isLoadingVideo = false;
          });
        } else {
          // Log for debugging
          Logger.warning("Could not extract video ID. videoUrls: ${video.videoUrls}, contentId: ${_currentRoom.contentId}", tag: 'RoomScreen');
          if (mounted) {
            setState(() {
              _videoContent = video;
              _isLoadingVideo = false;
            });
          }
        }
      } else {
        Logger.warning("Video not found in database for contentId: ${_currentRoom.contentId}", tag: 'RoomScreen');
        // Try using contentId directly as video ID
        String? videoId = _tryContentIdAsVideoId(_currentRoom.contentId);
        if (videoId != null && mounted) {
          Logger.info("Using contentId directly as video ID: $videoId", tag: 'RoomScreen');
          setState(() {
            _videoId = videoId;
            _isLoadingVideo = false;
          });
        } else {
          Logger.warning("ContentId is not a valid YouTube video ID: ${_currentRoom.contentId}", tag: 'RoomScreen');
          if (mounted) {
            setState(() => _isLoadingVideo = false);
          }
        }
      }
    } catch (e) {
      Logger.error("Error loading video content", error: e, tag: 'RoomScreen');
      // Try using contentId directly as fallback
      String? videoId = _tryContentIdAsVideoId(_currentRoom.contentId);
      if (videoId != null && mounted) {
        Logger.info("Using contentId as fallback video ID: $videoId", tag: 'RoomScreen');
        setState(() {
          _videoId = videoId;
          _isLoadingVideo = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingVideo = false);
      }
    }
  }

  String? _tryContentIdAsVideoId(String contentId) {
    // Check if contentId itself is a YouTube video ID (11 characters, alphanumeric)
    if (contentId.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(contentId)) {
      return contentId;
    }
    return null;
  }

  String? _extractYouTubeVideoId(Map<String, String> videoUrls) {
    if (videoUrls.isEmpty) {
      Logger.warning("videoUrls is empty", tag: 'RoomScreen');
      return null;
    }
    
    // Try to find YouTube URL in videoUrls
    for (var entry in videoUrls.entries) {
      final key = entry.key.toLowerCase();
      final url = entry.value;
      
      Logger.debug("Checking videoUrl[$key]: $url", tag: 'RoomScreen');
      
      // Check if key contains 'youtube' or 'youtu'
      if (key.contains('youtube') || key.contains('youtu')) {
        // Extract video ID from various YouTube URL formats
        final regex = RegExp(
          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
        );
        final match = regex.firstMatch(url);
        if (match != null) {
          final videoId = match.group(1);
          Logger.info("Extracted YouTube video ID from URL: $videoId", tag: 'RoomScreen');
          return videoId;
        }
        
        // If it's already a video ID (11 characters, alphanumeric)
        if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
          Logger.info("URL is already a YouTube video ID: $url", tag: 'RoomScreen');
          return url;
        }
      }
    }
    
    // Try all URLs regardless of key
    for (var url in videoUrls.values) {
      // Extract video ID from various YouTube URL formats
      final regex = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      final match = regex.firstMatch(url);
      if (match != null) {
        final videoId = match.group(1);
        Logger.info("Extracted YouTube video ID from any URL: $videoId", tag: 'RoomScreen');
        return videoId;
      }
      
      // If it's already a video ID (11 characters)
      if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        Logger.info("URL is already a YouTube video ID: $url", tag: 'RoomScreen');
        return url;
      }
    }
    
    Logger.warning("Could not extract YouTube video ID from videoUrls: $videoUrls", tag: 'RoomScreen');
    return null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    try {
      await firestoreService.sendChatMessage(
        roomId: _currentRoom.roomId,
        senderId: currentUser.uid,
        content: text,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  bool get _isHost {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    return currentUserId != null && currentUserId == _currentRoom.hostId;
  }

  Future<void> _showEditRoomDialog() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final nameController = TextEditingController(text: _currentRoom.name);
    final descriptionController = TextEditingController(text: _currentRoom.description ?? '');
    
    VideoContent? selectedVideo;
    RoomType selectedRoomType = _currentRoom.roomType;
    late Future<List<VideoContent>> videosFuture = firestoreService.getAvailableVideos();
    
    // Find the current video
    VideoContent? currentVideo;
    try {
      currentVideo = await firestoreService.getVideoById(_currentRoom.contentId);
      selectedVideo = currentVideo;
    } catch (e) {
      Logger.error("Error loading current video", error: e, tag: 'RoomScreen');
    }

    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text(
            'Edit Room',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Room Name
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Video Selector
                  Text(
                    'Select Video',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<VideoContent>>(
                    future: videosFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'No videos available',
                          style: TextStyle(color: Colors.white70),
                        );
                      }
                      
                      final videos = snapshot.data!;
                      return DropdownButtonFormField<VideoContent>(
                        initialValue: selectedVideo,
                        hint: Text(
                          'Select a video',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1a1a2e),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                          ),
                        ),
                        onChanged: (video) {
                          setDialogState(() {
                            selectedVideo = video;
                          });
                        },
                        items: videos.map((video) {
                          return DropdownMenuItem(
                            value: video,
                            child: Text(
                              video.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Room Type Selector
                  Text(
                    'Room Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RoomType>(
                    initialValue: selectedRoomType,
                    dropdownColor: const Color(0xFF1a1a2e),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                      ),
                    ),
                    onChanged: (type) {
                      setDialogState(() {
                        selectedRoomType = type ?? RoomType.public;
                      });
                    },
                    items: RoomType.values.map((type) {
                      String typeName = type.name[0].toUpperCase() + type.name.substring(1);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          typeName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && selectedVideo != null) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    'contentId': selectedVideo!.contentId,
                    'roomType': selectedRoomType,
                  });
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF6C5CE7)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        final updatedRoom = Room(
          roomId: _currentRoom.roomId,
          name: result['name'] as String,
          description: result['description'] as String?,
          roomType: result['roomType'] as RoomType,
          contentId: result['contentId'] as String,
          participants: _currentRoom.participants,
          createdAt: _currentRoom.createdAt,
          hostId: _currentRoom.hostId,
          privacySettings: _currentRoom.privacySettings,
          team1Name: _currentRoom.team1Name,
          team2Name: _currentRoom.team2Name,
          competitiveFeatures: result['roomType'] == RoomType.rival,
        );

        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.updateRoom(updatedRoom);

        // Update the local room state and reload video
        if (mounted) {
          setState(() {
            _currentRoom = updatedRoom;
            _videoContent = null;
            _videoId = null;
            _isLoadingVideo = true;
          });
          
          // Reload video content with new contentId
          _loadVideoContent();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update room: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteRoomDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete Room',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this room? This action cannot be undone and all messages will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteRoom(_currentRoom.roomId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Go back to home screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete room: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        title: Text(
          _currentRoom.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isHost
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showEditRoomDialog,
                  tooltip: 'Edit Room',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteRoomDialog,
                  tooltip: 'Delete Room',
                ),
              ]
            : null,
      ),
      body: Row(
        children: [
          // Left Side - Video Player
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: _isLoadingVideo
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.redAccent,
                      ),
                    )
                  : _videoContent != null
                      ? Column(
                          children: [
                            // Video Player
                            Expanded(
                              child: _videoId != null
                                  ? _buildVideoPlayer(_videoId!)
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                            ),
                            // Video Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: const Color(0xFF1a1a2e),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _videoContent!.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_videoContent!.description.isNotEmpty)
                                    Text(
                                      _videoContent!.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.video_library_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Video not found',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),

          // Right Side - Live Chat
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Chat Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<List<String>>(
                        stream: Stream.value(_currentRoom.participants),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? _currentRoom.participants.length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count 👤',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Messages List
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: Provider.of<FirestoreService>(context)
                        .getMessagesStream(_currentRoom.roomId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages: ${snapshot.error}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  ),
                ),

                // Message Input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a2e),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFF6C5CE7),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid ?? '';
    final isMyMessage = message.senderId == currentUserId;

    return FutureBuilder<UserModel?>(
      future: Provider.of<FirestoreService>(context, listen: false)
          .getUserById(message.senderId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final senderName = user?.displayName ?? 'Unknown User';
        final senderInitial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment:
                isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMyMessage) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      senderInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMyMessage)
                        Text(
                          senderName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (!isMyMessage) const SizedBox(height: 4),
                      Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMyMessage) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      senderInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildVideoPlayer(String videoId) {
    final embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=1&controls=1&rel=0&modestbranding=1';

    if (kIsWeb) {
      // Use HTML iframe for web
      return _buildWebVideoPlayer(embedUrl);
    } else {
      // Use InAppWebView for mobile
      return InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse(embedUrl),
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          ios: IOSInAppWebViewOptions(
            allowsInlineMediaPlayback: true,
          ),
          android: AndroidInAppWebViewOptions(
            useHybridComposition: true,
          ),
        ),
      );
    }
  }

  Widget _buildWebVideoPlayer(String embedUrl) {
    // Create a unique view ID for the iframe using roomId and timestamp
    final String viewId = 'youtube-player-${_currentRoom.roomId}-${DateTime.now().millisecondsSinceEpoch}';
    
    // Check if already registered, if so, use a different ID
    try {
      // Register the iframe
      html.IFrameElement iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..allowFullscreen = true
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';

      // Register the platform view
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int viewId) => iframe,
      );

      Logger.info("Registered YouTube iframe with viewId: $viewId, embedUrl: $embedUrl", tag: 'RoomScreen');
      
      return HtmlElementView(viewType: viewId);
    } catch (e) {
      Logger.error("Error creating web video player", error: e, tag: 'RoomScreen');
      // Fallback: return a container with error message
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading video player',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URL: $embedUrl',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
