import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/models/friendship_model.dart'; 

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  // Color scheme matching login page
  static const Color purpleButton = Color(0xFF6C5CE7);
  static const Color containerGradient1 = Color(0xFF1a1a2e);
  static const Color containerGradient2 = Color(0xFF16213e);
  static const Color containerGradient3 = Color(0xFF0f3460);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // Match container gradient start color
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        title: const Text(
          'Add Friends',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Search Results or Empty State
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Users',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: purpleButton, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: _performSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Search for users by their display name',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final initial = (user.displayName ?? user.email.split('@')[0])[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            containerGradient1,
            containerGradient2,
            containerGradient3,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent,
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.displayName ?? 'No name',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: _buildAddButton(user, _getCurrentUserId()),
      ),
    );
  }
Widget _buildAddButton(UserModel user, String currentUserId) {
  return FutureBuilder<FriendshipStatus?>(
    future: Provider.of<FirestoreService>(context, listen: false)
        .getFriendshipStatus(currentUserId, user.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      
      final status = snapshot.data;
      
      return _getFriendButtonByStatus(status, user);
    },
  );
}

Widget _getFriendButtonByStatus(FriendshipStatus? status, UserModel user) {
  switch (status) {
    case FriendshipStatus.pending:
      // Check who sent the request
      return FutureBuilder<Friendship?>(
        future: _getFriendshipBetweenUsers(user.uid),
        builder: (context, friendshipSnapshot) {
          if (friendshipSnapshot.connectionState == ConnectionState.waiting) {
            return const OutlinedButton(
              onPressed: null,
              child: Text('Loading...'),
            );
          }
          
          final friendship = friendshipSnapshot.data;
          final isRequestSentByMe = friendship?.user1Id == _getCurrentUserId();
          
          if (isRequestSentByMe) {
            return OutlinedButton(
              onPressed: null,
              child: Text('Request Sent'),
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptFriendRequest(friendship!.friendshipId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleButton,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Accept'),
                ),
                SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _declineFriendRequest(friendship!.friendshipId),
                  child: Text('Decline'),
                ),
              ],
            );
          }
        },
      );
      
    case FriendshipStatus.accepted:
      return OutlinedButton(
        onPressed: null,
        child: Text('Friends'),
      );
      
    case FriendshipStatus.declined:
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text('Add Friend'),
      );
    case null:
    default:
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text('Add Friend'),
      );
  }
}

  void _performSearch(String query) async {
    if (query.length < 2) { // Don't search for very short queries
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await Provider.of<FirestoreService>(context, listen: false)
          .searchUsers(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print("Search error: $e");
    }
  }

  void _sendFriendRequest(UserModel targetUser) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  final currentUser = authService.currentUser;

  if (currentUser == null) return;

  // Prevent sending to yourself
  if (currentUser.uid == targetUser.uid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot send a friend request to yourself')),
    );
    return;
  }

  try {
    // Check if friendship already exists
    final existingFriendship = await firestoreService.getFriendshipBetweenUsers(
      currentUser.uid, 
      targetUser.uid
    );

    if (existingFriendship != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request already ${existingFriendship.status.name}')),
      );
      return;
    }

    // Send new request
    await firestoreService.sendFriendRequest(
      fromUserId: currentUser.uid,
      toUserId: targetUser.uid,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to ${targetUser.displayName}')),
    );
    
    // Refresh the UI to update button state
    setState(() {});
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send request: $e')),
    );
  }
}
  void _acceptFriendRequest(String friendshipId) async {
  try {
    await Provider.of<FirestoreService>(context, listen: false)
        .acceptFriendRequest(friendshipId);
    setState(() {}); // Refresh UI
  } catch (e) {
    // Handle error
  }
}

void _declineFriendRequest(String friendshipId) async {
  try {
    // Instead of updating status to declined, DELETE the friendship
    await Provider.of<FirestoreService>(context, listen: false)
        .deleteFriendship(friendshipId);
    setState(() {}); // Refresh UI
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to decline request: $e')),
    );
  }
}

  
  String _getCurrentUserId() {
  return Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
}

Future<Friendship?> _getFriendshipBetweenUsers(String otherUserId) async {
  final currentUserId = _getCurrentUserId();
  return Provider.of<FirestoreService>(context, listen: false)
      .getFriendshipBetweenUsers(currentUserId, otherUserId);
}
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}