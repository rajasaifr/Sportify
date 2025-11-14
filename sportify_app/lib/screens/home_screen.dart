import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ADD THIS
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/create_room_screen.dart';
import 'package:sportify_app/screens/room_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    // Get the *shared* instances from Provider
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    // --- END OF FIX ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sportify Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              // This now calls the *shared* instance,
              // so the AuthWrapper will hear it!
              authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Room>>(
        // Use the shared instance
        stream: firestoreService.getPublicRoomsStream(),
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
                'No public rooms available.\nWhy not create one?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(room.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(room.description ?? 'No description'),
                  trailing: Text('${room.participants.length} 👤'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RoomScreen(room: room),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateRoomScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create a Room',
      ),
    );
  }
}
