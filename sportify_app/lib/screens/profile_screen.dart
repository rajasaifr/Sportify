import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
// Make sure to point this to the correct location or use FirestoreService if you merged them
import 'package:sportify_app/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  List<String> _selectedTeams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    // Note: If you moved getUserProfile to FirestoreService, update this line:
    final profileService = Provider.of<ProfileService>(context, listen: false);

    try {
      final user = authService.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        final userProfile = await profileService.getUserProfile(user.uid);
        if (userProfile != null && mounted) {
          setState(() {
            _displayNameController.text = userProfile.displayName ?? '';
            _bioController.text = userProfile.bio ?? '';
            _selectedTeams = userProfile.favoriteTeams ?? [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) return;

      final updatedUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email!,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        favoriteTeams: _selectedTeams,
        createdAt: DateTime.now(),
        role: UserRole.user,
      );

      await profileService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Added Sign Out Function
  void _signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
    // The AuthWrapper in main.dart will automatically take them to Login
  }

  void _onTeamsUpdated(List<String> teams) {
    setState(() {
      _selectedTeams = teams;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We removed the Scaffold and AppBar so it fits nicely in the Tabs
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProfilePictureSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),

              // --- NEW SIGNOUT BUTTON ---
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ),
              const SizedBox(height: 40), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[800],
          child: const Icon(Icons.person, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            // TODO: Implement image picker
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Display name is required';
            }
            if (value.length < 2) {
              return 'Display name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio (Optional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Bio must be less than 500 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sports Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your favorite teams',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
        ),
        const SizedBox(height: 16),
        _buildTeamSelection(),
      ],
    );
  }

  Widget _buildTeamSelection() {
    final List<String> availableTeams = [
      'Los Angeles Lakers',
      'Golden State Warriors',
      'Chicago Bulls',
      'Boston Celtics',
      'Miami Heat',
      'Toronto Raptors',
      'Real Madrid',
      'FC Barcelona',
      'Manchester United',
      'Liverpool FC',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTeams.map((team) {
        final isSelected = _selectedTeams.contains(team);
        return FilterChip(
          label: Text(team),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                _selectedTeams.remove(team);
              } else {
                _selectedTeams.add(team);
              }
            });
            _onTeamsUpdated(_selectedTeams);
          },
          checkmarkColor: Colors.white,
          selectedColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
