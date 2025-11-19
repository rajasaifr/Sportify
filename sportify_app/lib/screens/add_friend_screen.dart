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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friends'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by username...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onChanged: _performSearch, // This will trigger search as user types
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Search for users by their display name',
            style: TextStyle(color: Colors.grey),
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
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: Colors.grey[800],
      child: const Icon(Icons.person, color: Colors.grey),
    ),
    title: Text(user.displayName ?? 'No name'),
    subtitle: Text(user.email),
    trailing: _buildAddButton(user, _getCurrentUserId()), // ← FIX THIS LINE
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
                  child: Text('Accept'),
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
  return ElevatedButton( // Changed from OutlinedButton to ElevatedButton
    onPressed: () => _sendFriendRequest(user),
    child: Text('Add Friend'), // Changed text to be more clear
  );
    case null:
    default:
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(user),
        child: Text('Add Friend'),
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