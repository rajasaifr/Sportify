import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/add_friend_screen.dart';
import 'package:sportify_app/theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Changed from Colors.black
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Account_BG.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content on top
          Column(
            children: [
              _buildSearchBar(),
              _buildTabsSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Colors.transparent, // Make transparent so image shows
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Friends',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primary, // Dark greenish blue
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AddFriendScreen()),
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
            Container(
              color: Colors.transparent, // Changed from Colors.black
              child: TabBar(
                indicatorColor: AppTheme.primary, // Dark greenish blue
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                tabs: const [
                  Tab(text: 'My Friends'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.transparent, // Changed from Colors.black
                child: TabBarView(
                  children: [
                    _buildFriendsList(),
                    _buildRequestsList(),
                  ],
                ),
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
      return const Center(child: Text('Please log in', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<List<Friendship>>(
      stream: Provider.of<FirestoreService>(context)
          .getFriendshipsForUser(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading friends',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final friendships = snapshot.data ?? [];

        if (friendships.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for users and send friend requests!',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Centered list with left and right borders
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Limit width for centering
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent, // Explicitly transparent so image shows through
              border: Border(
                left: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                right: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: friendships.length,
              itemBuilder: (context, index) {
                final friendship = friendships[index];
                return FutureBuilder<UserModel?>(
                  future: _getFriendUserModel(friendship, currentUser.uid),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey),
                        title: Text('Loading...', style: TextStyle(color: Colors.white)),
                      );
                    }

                    final friendUser = userSnapshot.data;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground, // Dark background
                        borderRadius: BorderRadius.circular(0), // Sharp corners
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3), // Dark greenish blue border
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary, // Dark greenish blue
                          child: Text(
                            (friendUser?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          friendUser?.displayName ?? 'Unknown User',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          friendUser?.email ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<List<Friendship>>(
      stream: Provider.of<FirestoreService>(context)
          .getPendingRequestsReceived(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading requests',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_unread_outlined,
                    size: 64, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        }

        // Centered list with left and right borders
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Limit width for centering
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent, // Explicitly transparent so image shows through
              border: Border(
                left: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                right: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return FutureBuilder<UserModel?>(
                  future: Provider.of<FirestoreService>(context, listen: false)
                      .getUserById(request.user1Id),
                  builder: (context, userSnapshot) {
                    final senderUser = userSnapshot.data;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground, // Dark background
                        borderRadius: BorderRadius.circular(0), // Sharp corners
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3), // Dark greenish blue border
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary, // Dark greenish blue
                          child: Text(
                            (senderUser?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          senderUser?.displayName ?? 'Unknown User',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Wants to be your friend',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () =>
                                  _acceptFriendRequest(request.friendshipId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _declineFriendRequest(request.friendshipId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<UserModel?> _getFriendUserModel(
      Friendship friendship, String currentUserId) async {
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _declineFriendRequest(String friendshipId) async {
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .declineFriendRequest(friendshipId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
