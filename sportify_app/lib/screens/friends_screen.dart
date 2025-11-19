import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabsSection(),
        ],
      ),
    );
  }

Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Friends',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddFriendScreen()),
              );
            },
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Find Friends',
          ),
        ),
      ],
    ),
  );
}
  Widget _buildTabsSection() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'My Friends'),
                Tab(text: 'Requests'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFriendsList(),
                  _buildRequestsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<Friendship>>(
      stream: Provider.of<FirestoreService>(context)
          .getFriendshipsForUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading friends'));
        }
        
        final friendships = snapshot.data ?? [];
        
        if (friendships.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Search for users and send friend requests!',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: friendships.length,
          itemBuilder: (context, index) {
            final friendship = friendships[index];
            return FutureBuilder<UserModel?>(
              future: _getFriendUserModel(friendship, currentUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey),
                    title: Text('Loading...'),
                  );
                }
                
                final friendUser = userSnapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(friendUser?.displayName ?? 'Unknown User'),
                  subtitle: Text(friendUser?.email ?? ''),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    if (currentUser == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<Friendship>>(
      stream: Provider.of<FirestoreService>(context)
          .getPendingRequestsReceived(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading requests'));
        }
        
        final requests = snapshot.data ?? [];
        
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<UserModel?>(
              future: Provider.of<FirestoreService>(context, listen: false)
                  .getUserById(request.user1Id),
              builder: (context, userSnapshot) {
                final senderUser = userSnapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(senderUser?.displayName ?? 'Unknown User'),
                  subtitle: const Text('Wants to be your friend'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptFriendRequest(request.friendshipId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _declineFriendRequest(request.friendshipId),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<UserModel?> _getFriendUserModel(Friendship friendship, String currentUserId) async {
    final friendId = friendship.user1Id == currentUserId 
        ? friendship.user2Id 
        : friendship.user1Id;
    
    return Provider.of<FirestoreService>(context, listen: false)
        .getUserById(friendId);
  }

  void _acceptFriendRequest(String friendshipId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .acceptFriendRequest(friendshipId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept request')),
      );
    }
  }

  void _declineFriendRequest(String friendshipId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .declineFriendRequest(friendshipId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline request')),
      );
    }
  }
}