import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/create_room_screen.dart';
import 'package:sportify_app/screens/room_screen.dart';
import 'package:sportify_app/screens/profile_screen.dart';
import 'package:sportify_app/screens/friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Lobby, Room, Friends, Profile
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToLobby() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _goToLobby,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_soccer, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text(
                'Sportify',
                style:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          // Text Only Tabs
          tabs: const [
            Tab(text: "Lobby"),
            Tab(text: "Room"),
            Tab(text: "Friends"),
            Tab(text: "Profile"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Lobby
          _buildLobbyView(context),

          // 2. Create Room
          const CreateRoomScreen(),

          // 3. Friends
          const FriendsScreen(),

          // 4. Profile
          const ProfileScreen(),
        ],
      ),
      // No Floating Action Button
    );
  }

  Widget _buildLobbyView(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<Room>>(
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
              'No public rooms available.\nGo to the "Room" tab to create one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final rooms = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_outline,
                      color: Colors.redAccent),
                ),
                title: Text(
                  room.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(room.description ?? 'No description'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${room.participants.length} 👤'),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => RoomScreen(room: room)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
