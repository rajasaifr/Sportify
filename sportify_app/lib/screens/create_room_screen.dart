import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ADD THIS
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  RoomType _selectedRoomType = RoomType.public;
  VideoContent? _selectedVideo;
  bool _isLoading = false;

  late Future<List<VideoContent>> _videosFuture;

  // We no longer create instances here
  // final FirestoreService _firestoreService = FirestoreService();
  // final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Get the shared instance from Provider
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _videosFuture = firestoreService.getAvailableVideos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateRoom() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return; // Don't submit if form is invalid
    }

    // 2. Validate that a video was selected
    if (_selectedVideo == null) {
      _showErrorSnackBar('Please select a video to watch');
      return;
    }

    // --- THIS IS THE FIX ---
    // Get shared services from Provider
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    // --- END OF FIX ---

    // 3. Get the current user's ID
    final hostId = authService.currentUser?.uid;
    if (hostId == null) {
      _showErrorSnackBar('Error: You are not logged in.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Call the createRoom function from our service
      String? newRoomId = await firestoreService.createRoom(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        contentId: _selectedVideo!.contentId,
        hostId: hostId,
        roomType: _selectedRoomType,
        // TODO: Add fields for Rival Room
      );

      if (newRoomId != null) {
        // 5. Success! Pop back to the HomeScreen
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackBar('Failed to create room.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Room'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- ROOM NAME ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a room name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // --- ROOM DESCRIPTION ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- VIDEO SELECTOR ---
            FutureBuilder<List<VideoContent>>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No videos found in database. Please add a video to the "videos" collection.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final videos = snapshot.data!;
                return DropdownButtonFormField<VideoContent>(
                  value: _selectedVideo,
                  hint: const Text('Select a video'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (video) {
                    setState(() => _selectedVideo = video);
                  },
                  items: videos.map((video) {
                    return DropdownMenuItem(
                      value: video,
                      child: Text(video.title, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null ? 'Please select a video' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // --- ROOM TYPE SELECTOR ---
            DropdownButtonFormField<RoomType>(
              value: _selectedRoomType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (type) {
                setState(() => _selectedRoomType = type ?? RoomType.public);
              },
              items: RoomType.values.map((type) {
                // Simple logic to format the enum name
                String typeName =
                    type.name[0].toUpperCase() + type.name.substring(1);
                return DropdownMenuItem(
                  value: type,
                  child: Text(typeName),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // TODO: Add text fields for Team 1 / Team 2
            // that only appear if _selectedRoomType == RoomType.rival

            const SizedBox(height: 32),

            // --- SUBMIT BUTTON ---
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCreateRoom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Room', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
