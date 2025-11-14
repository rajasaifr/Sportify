import 'package:flutter/material.dart';
import 'package:sportify_app/models/room_model.dart';

class RoomScreen extends StatelessWidget {
  final Room room;

  const RoomScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ${room.name}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('We are watching contentId: ${room.contentId}'),
            //
            // --- TODO ---
            // 1. Add the Video Player here, using the room.contentId
            // 2. Add the Chat Stream (UC-16)
            // 3. Add the Live Reactions (UC-17)
            // 4. Add the Playback Sync logic (UC-14)
          ],
        ),
      ),
    );
  }
}
