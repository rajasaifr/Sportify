import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/message_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/utils/logger.dart';
import 'package:sportify_app/theme/app_theme.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// Required for web platform iframe embedding
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';

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

  // Rating state
  int? _userRating;
  bool _isLoadingRating = false;

  // Video player state - store iframe reference to prevent recreation
  html.IFrameElement? _videoIframe;
  String? _videoPlayerViewId;

  // Check if current user is the host
  bool get _isHost {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    return currentUserId != null && currentUserId == _currentRoom.hostId;
  }

  @override
  void initState() {
    super.initState();
    _loadVideoContent();
    _loadUserRating();
  }




  @override
  void dispose() {
    _messageController.dispose();
    // Clear video iframe reference on dispose
    _videoIframe = null;
    _videoPlayerViewId = null;
    super.dispose();
  }

  Future<void> _loadUserRating() async {
    if (_currentRoom.roomType != RoomType.public) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final rating = await firestoreService.getUserRoomRating(_currentRoom.roomId, currentUserId);
    
    if (mounted) {
      setState(() {
        _userRating = rating;
      });
    }
  }

  Future<void> _submitRating(int stars) async {
    if (_currentRoom.roomType != RoomType.public) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to rate rooms'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingRating = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.submitRoomRating(
        roomId: _currentRoom.roomId,
        userId: currentUserId,
        stars: stars,
      );

      // Reload room to get updated rating
      final updatedRoom = await firestoreService.getRoomById(_currentRoom.roomId);
      if (updatedRoom != null && mounted) {
        setState(() {
          _currentRoom = updatedRoom;
          _userRating = stars;
          _isLoadingRating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rating submitted: $stars stars'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadVideoContent() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    setState(() => _isLoadingVideo = true);
    
    Logger.info("Loading video for room: ${_currentRoom.name}, contentId: ${_currentRoom.contentId}", tag: 'RoomScreen');
    
    try {
      final video = await firestoreService.getVideoById(_currentRoom.contentId);
      
      if (video != null && mounted) {
        Logger.info("Video found: ${video.title}, videoUrls: ${video.videoUrls}, contentId: ${video.contentId}", tag: 'RoomScreen');
        
        // Extract YouTube video ID from videoUrls
        String? videoId = _extractYouTubeVideoId(video.videoUrls);
        
        Logger.debug("Extracted video ID from videoUrls: $videoId", tag: 'RoomScreen');
        
        // If extraction failed, try using video's contentId directly if it looks like a YouTube ID
        if (videoId == null && video.contentId.isNotEmpty) {
          videoId = _tryContentIdAsVideoId(video.contentId);
          Logger.debug("Trying video.contentId as video ID: $videoId", tag: 'RoomScreen');
        }
        
        // If still null, try using room's contentId
        if (videoId == null) {
          videoId = _tryContentIdAsVideoId(_currentRoom.contentId);
          Logger.debug("Trying room.contentId as video ID: $videoId", tag: 'RoomScreen');
        }
        
        // Set video content regardless of videoId (so we can show video info)
        if (mounted) {
          setState(() {
            _videoContent = video;
            _videoId = videoId; // Can be null, but we'll handle that in UI
            _isLoadingVideo = false;
          });
          
          if (videoId != null) {
            Logger.info("Using video ID: $videoId", tag: 'RoomScreen');
          } else {
            Logger.warning("Could not extract video ID. videoUrls: ${video.videoUrls}, video.contentId: ${video.contentId}, room.contentId: ${_currentRoom.contentId}", tag: 'RoomScreen');
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
    
    Logger.debug("Extracting YouTube video ID from videoUrls: $videoUrls", tag: 'RoomScreen');
    
    // Try to find YouTube URL in videoUrls
    for (var entry in videoUrls.entries) {
      final key = entry.key.toLowerCase();
      final url = entry.value.trim();
      
      if (url.isEmpty) continue;
      
      Logger.debug("Checking videoUrl[$key]: $url", tag: 'RoomScreen');
      
      // First check if it's already a video ID (11 characters, alphanumeric)
      if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
        Logger.info("URL is already a YouTube video ID: $url", tag: 'RoomScreen');
        return url;
      }
      
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
      }
    }
    
    // Try all URLs regardless of key
    for (var url in videoUrls.values) {
      final trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) continue;
      
      // First check if it's already a video ID
      if (trimmedUrl.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmedUrl)) {
        Logger.info("URL is already a YouTube video ID: $trimmedUrl", tag: 'RoomScreen');
        return trimmedUrl;
      }
      
      // Extract video ID from various YouTube URL formats
      final regex = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      final match = regex.firstMatch(trimmedUrl);
      if (match != null) {
        final videoId = match.group(1);
        Logger.info("Extracted YouTube video ID from any URL: $videoId", tag: 'RoomScreen');
        return videoId;
      }
    }
    
    Logger.warning("Could not extract YouTube video ID from videoUrls: $videoUrls", tag: 'RoomScreen');
    return null;
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

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _showEmojiPickerDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close on outside tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Emoji picker positioned on the right
          Positioned(
            right: 12,
            bottom: 80, // Position above the message input
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 350, // Match chat width
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.cardBackground,
                        AppTheme.bgStart,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildEmojiPicker(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    // Frequently used emojis (like WhatsApp)
    final frequentlyUsed = ['😀', '😂', '🥰', '😍', '🤔', '😊', '👍', '❤️', '🔥', '💯', '🎉', '😎', '😭', '😡', '🤯', '🥳'];
    
    // Emoji categories with icons
    final emojiCategories = [
      {'name': 'Frequently Used', 'icon': Icons.access_time, 'emojis': frequentlyUsed},
      {'name': 'Smileys', 'icon': Icons.sentiment_satisfied, 'emojis': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓']},
      {'name': 'Gestures', 'icon': Icons.waving_hand, 'emojis': ['👋', '🤚', '🖐', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💪', '🦵', '🦶', '👂', '🦻', '👃', '🧠', '🫀', '🫁', '🦷', '🦴', '👀', '👁️', '👅', '👄']},
      {'name': 'Sports', 'icon': Icons.sports_soccer, 'emojis': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🥅', '⛳', '🏹', '🎣', '🥊', '🥋', '🎽', '🛹', '🛷', '⛸', '🥌', '🎿', '⛷', '🏂', '🏋️', '🤼', '🤸', '🤺', '🧘', '🏄', '🏊', '🚴', '🚵', '🧗', '🤹', '🏇']},
      {'name': 'Reactions', 'icon': Icons.favorite, 'emojis': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '✅', '❌', '❓', '❔', '❗', '❕', '💯', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤']},
      {'name': 'Objects', 'icon': Icons.auto_awesome, 'emojis': ['🔥', '💯', '⭐', '🌟', '✨', '💫', '⚡', '☄️', '💥', '💢', '💤', '💨', '👁️', '👀', '🧠', '🗣️', '👤', '👥', '👶', '🧒', '👦', '👧', '🧑', '👨', '👩', '🧓', '👴', '👵', '🎁', '🎈', '🎉', '🎊', '🎀', '🎗️', '🏆', '🥇', '🥈', '🥉', '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸', '🏒', '🏑', '🏏', '🎯', '🎲', '🎮', '🎰', '🎨', '🧩', '♠️', '♥️', '♦️', '♣️', '🃏', '🀄', '🎴', '🎭', '🖼️', '🎨', '🖌️', '🖍️', '✏️', '✒️', '🖊️', '🖋️', '📝', '💼', '📁', '📂', '🗂️', '📅', '📆', '🗒️', '🗓️', '📇', '📈', '📉', '📊', '📋', '📌', '📍', '📎', '🖇️', '📏', '📐', '✂️', '🗃️', '🗄️', '🗑️']},
    ];
    
    int selectedCategoryIndex = 0;
    
    return StatefulBuilder(
      builder: (context, setPickerState) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              // Category Tabs (WhatsApp style)
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: emojiCategories.length,
                  itemBuilder: (context, index) {
                    final category = emojiCategories[index];
                    final isSelected = selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setPickerState(() {
                          selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.5),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category['icon'] as IconData,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textFaint,
                              size: 20,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textFaint,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Emoji Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: (emojiCategories[selectedCategoryIndex]['emojis'] as List).length,
                  itemBuilder: (context, index) {
                    final emoji = (emojiCategories[selectedCategoryIndex]['emojis'] as List)[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _insertEmoji(emoji);
                          // Don't close immediately - allow multiple emoji selection
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Close Button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppTheme.textFaint, size: 18),
                      label: const Text(
                        'Close',
                        style: TextStyle(color: AppTheme.textFaint),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _checkHostPresence() {
    // If current user is host, always allow
    if (_isHost) return true;
    
    // Check if host is in participants list
    return _currentRoom.participants.contains(_currentRoom.hostId);
  }

  void _navigateBackToRooms() {
    // Pop back to previous screen (should be CreateRoomScreen which is the Room tab)
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, navigate back to home
      // This shouldn't happen in normal flow, but handle it gracefully
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _loadYouTubeIFrameAPI() {
    if (kIsWeb && html.document.querySelector('#youtube-iframe-api') == null) {
      final script = html.ScriptElement()
        ..id = 'youtube-iframe-api'
        ..src = 'https://www.youtube.com/iframe_api'
        ..async = true;
      html.document.head!.append(script);
    }
  }

  void _setupYouTubePlayerEvents(html.IFrameElement iframe) {
    if (!kIsWeb) return;
    
    // Wait for YouTube API to be ready
    Timer(const Duration(milliseconds: 500), () {
      try {
        iframe.contentWindow!.postMessage('{"event":"command","func":"addEventListener","args":["onStateChange"]}', '*');
      } catch (e) {
        Logger.error("Error setting up YouTube player events", error: e, tag: 'RoomScreen');
      }
    });
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
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: const Text(
            'Edit Room',
            style: TextStyle(color: AppTheme.textMain),
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
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      labelStyle: const TextStyle(color: AppTheme.textFaint),
                      filled: true,
                      fillColor: AppTheme.inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descriptionController,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: const TextStyle(color: AppTheme.textFaint),
                      filled: true,
                      fillColor: AppTheme.inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
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
                      color: AppTheme.textMain.withValues(alpha: 0.9),
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
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.accent),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'No videos available',
                          style: TextStyle(color: AppTheme.textFaint),
                        );
                      }
                      
                      final videos = snapshot.data!;
                      return DropdownButtonFormField<VideoContent>(
                        initialValue: selectedVideo,
                        hint: Text(
                          'Select a video',
                          style: TextStyle(color: AppTheme.textFaint.withValues(alpha: 0.5)),
                        ),
                        isExpanded: true,
                        dropdownColor: AppTheme.cardBackground,
                        style: const TextStyle(color: AppTheme.textMain),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
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
                              style: const TextStyle(color: AppTheme.textMain),
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
                      color: AppTheme.textMain.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RoomType>(
                    initialValue: selectedRoomType,
                    dropdownColor: AppTheme.cardBackground,
                    style: const TextStyle(color: AppTheme.textMain),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
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
                          style: const TextStyle(color: AppTheme.textMain),
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
                style: TextStyle(color: AppTheme.textFaint),
              ),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
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
          roomCode: _currentRoom.roomCode, // Preserve room code
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
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: const Text(
          'Delete Room',
          style: TextStyle(color: AppTheme.textMain),
        ),
        content: const Text(
          'Are you sure you want to delete this room? This action cannot be undone and all messages will be deleted.',
          style: TextStyle(color: AppTheme.textFaint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textFaint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.accent),
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
      backgroundColor: AppTheme.bgStart,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppTheme.bgStart.withValues(alpha: 0.95),
            elevation: 0,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
              onPressed: () => _navigateBackToRooms(),
            ),
            title: Text(
              _currentRoom.name,
              style: const TextStyle(color: AppTheme.textMain),
            ),
            iconTheme: const IconThemeData(color: AppTheme.textMain),
        actions: [
          // Room Code Display (for private rooms) - left of edit
          if (_currentRoom.roomType == RoomType.private && _currentRoom.roomCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentRoom.roomCode!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentRoom.roomCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Room code copied: ${_currentRoom.roomCode}'),
                          backgroundColor: AppTheme.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy Room Code',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          if (_isHost) ...[
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
          ],
        ],
      ),
      body: Row(
        children: [
          // Left Side - Video Player and Info
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Video Player
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: _isLoadingVideo
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          )
                        : _checkHostPresence()
                            ? _videoContent != null
                                ? _videoId != null
                                    ? KeyedSubtree(
                                        key: ValueKey('video-player-${_currentRoom.roomId}'),
                                        child: _buildVideoPlayer(_videoId!),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Could not load video player',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Video ID not found in: ${_videoContent!.videoUrls}',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.5),
                                                fontSize: 12,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
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
                                  )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_off,
                                      size: 64,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Host is not in the room',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video will be available when host joins',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ),
                // Video Info - Full width below video player
                if (_videoContent != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.cardBackground,
                          AppTheme.bgStart,
                        ],
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _videoContent!.title,
                                    style: const TextStyle(
                                      color: AppTheme.textMain,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_videoContent!.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _videoContent!.description,
                                      style: TextStyle(
                                        color: AppTheme.textFaint,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  // Room Rating Display and Input (only for public rooms)
                                  if (_currentRoom.roomType == RoomType.public) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        // Display average rating
                                        if (_currentRoom.averageRating != null) ...[
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _currentRoom.averageRating!.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: AppTheme.textMain,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${_currentRoom.totalRatings} ${_currentRoom.totalRatings == 1 ? 'rating' : 'ratings'})',
                                            style: TextStyle(
                                              color: AppTheme.textFaint,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'No ratings yet',
                                            style: TextStyle(
                                              color: AppTheme.textFaint,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Star rating input
                                    Row(
                                      children: [
                                        Text(
                                          'Rate this room: ',
                                          style: TextStyle(
                                            color: AppTheme.textFaint,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ...List.generate(5, (index) {
                                          final starValue = index + 1;
                                          final isSelected = _userRating != null && starValue <= _userRating!;
                                          return GestureDetector(
                                            onTap: _isLoadingRating ? null : () => _submitRating(starValue),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2),
                                              child: Icon(
                                                isSelected ? Icons.star : Icons.star_border,
                                                color: isSelected ? Colors.amber : AppTheme.textFaint,
                                                size: 28,
                                              ),
                                            ),
                                          );
                                        }),
                                        if (_isLoadingRating) ...[
                                          const SizedBox(width: 8),
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Right Side - Live Chat
          Container(
            width: 350,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.cardBackground,
                  AppTheme.bgStart,
                ],
              ),
              border: Border(
                left: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
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
                    color: AppTheme.cardBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Chat',
                        style: TextStyle(
                          color: AppTheme.textMain,
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
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$count 👤',
                              style: const TextStyle(
                                color: AppTheme.textMain,
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
                    color: AppTheme.cardBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Emoji Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: _showEmojiPickerDialog,
                          icon: const Icon(
                            Icons.emoji_emotions,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          tooltip: 'Add emoji',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppTheme.textMain, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: AppTheme.textFaint.withValues(alpha: 0.5),
                            ),
                            filled: true,
                            fillColor: AppTheme.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
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
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
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
        ),
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
                        ? AppTheme.primary
                        : AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: isMyMessage
                        ? null
                        : Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
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
                          fontSize: 16,
                          height: 1.4,
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
    // YouTube embed parameters to disable related videos and suggestions
    // rel=0: Don't show related videos from other channels (most important for preventing "More videos")
    // modestbranding=1: Reduce YouTube branding
    // showinfo=0: Don't show video info overlay (deprecated but helps)
    // iv_load_policy=3: Disable annotations
    // fs=1: Allow fullscreen
    // playsinline=1: Play inline on mobile
    // loop=0: Don't loop video
    // mute=0: Allow sound
    final origin = kIsWeb ? (Uri.base.hasScheme ? Uri.base.origin : '') : '';
    final originParam = origin.isNotEmpty ? '&origin=$origin' : '';
    final embedUrl = 'https://www.youtube.com/embed/$videoId?autoplay=1&controls=1&rel=0&modestbranding=1&showinfo=0&iv_load_policy=3&fs=1&playsinline=1&loop=0&mute=0$originParam';

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
    // Use a stable view ID based only on roomId to prevent recreation on rebuilds
    final String viewId = 'youtube-player-${_currentRoom.roomId}';
    
    // If we already have an iframe for this room, reuse it instead of creating a new one
    if (_videoIframe != null && _videoPlayerViewId == viewId) {
      Logger.debug("Reusing existing video iframe for room: ${_currentRoom.roomId}", tag: 'RoomScreen');
      return HtmlElementView(viewType: viewId);
    }
    
    try {
      // Load YouTube IFrame API script
      _loadYouTubeIFrameAPI();
      
      // Register the iframe
      html.IFrameElement iframe = html.IFrameElement()
        ..src = embedUrl.replaceFirst('?', '?enablejsapi=1&')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..allowFullscreen = true
        ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
      
      // Store the iframe reference to prevent recreation
      _videoIframe = iframe;
      _videoPlayerViewId = viewId;
      
      // Set up event listeners for playback state tracking
      iframe.onLoad.listen((_) {
        _setupYouTubePlayerEvents(iframe);
      });

      // Register the platform view (will only register once per viewId)
      try {
        ui_web.platformViewRegistry.registerViewFactory(
          viewId,
          (int viewId) => iframe,
        );
        Logger.info("Registered YouTube iframe with viewId: $viewId, embedUrl: $embedUrl", tag: 'RoomScreen');
      } catch (e) {
        // View might already be registered, that's okay - we'll reuse it
        Logger.debug("Video player viewId already registered, reusing: $viewId", tag: 'RoomScreen');
      }
      
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
