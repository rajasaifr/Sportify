import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/profile_service.dart';
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
    // 3 Tabs: Lobby, Room, Friends (Profile removed)
    _tabController = TabController(length: 3, vsync: this);
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
      backgroundColor: const Color(0xFF1a1a2e), // Match container gradient start color
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Sportify Logo
            GestureDetector(
              onTap: _goToLobby,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sportify',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Tabs aligned horizontally with logo
            Expanded(
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.redAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Lobby"),
                  Tab(text: "Room"),
                  Tab(text: "Friends"),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Profile button with dropdown
            _buildProfileButton(context),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF1a1a2e),
        child: TabBarView(
          controller: _tabController,
          children: [
            // 1. Lobby
            _buildLobbyView(context),

            // 2. Create Room
            const CreateRoomScreen(),

            // 3. Friends
            const FriendsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final currentUser = authService.currentUser;

    return StreamBuilder<UserModel?>(
      stream: currentUser != null
          ? profileService.getUserProfileStream(currentUser.uid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final userModel = snapshot.data;
        final displayName = userModel?.displayName ?? currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'U';
        final profilePicUrl = userModel?.profilePicUrl ?? currentUser?.photoURL;
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: const Color(0xFF1a1a2e),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              image: profilePicUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profilePicUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: profilePicUrl == null ? Colors.redAccent : null,
            ),
            child: profilePicUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
          ),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'manage',
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Manage account',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            if (value == 'manage') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            } else if (value == 'signout') {
              _showSignOutDialog(context);
            }
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
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
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(context, listen: false);
                authService.signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLobbyView(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<Room>>(
      stream: firestoreService.getPublicRoomsStream(),
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
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No public rooms available.\nGo to the "Room" tab to create one!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          );
        }

        final rooms = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.redAccent,
                  ),
                ),
                title: Text(
                  room.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  room.description ?? 'No description',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${room.participants.length} 👤',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
    );
  }
}
