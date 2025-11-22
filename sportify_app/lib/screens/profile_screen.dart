import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
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

  void _signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
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
          'Manage Account',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfilePictureSection(),
                    const SizedBox(height: 24),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildPreferencesSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 20),
                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
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

        return Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.redAccent,
              backgroundImage: profilePicUrl != null
                  ? NetworkImage(profilePicUrl) as ImageProvider?
                  : null,
              child: profilePicUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo upload coming soon!')),
                );
              },
              icon: const Icon(Icons.camera_alt, color: purpleButton),
              label: const Text(
                'Change Photo',
                style: TextStyle(color: purpleButton),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            prefixIcon: const Icon(Icons.person, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: purpleButton, width: 2),
            ),
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Bio (Optional)',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: purpleButton, width: 2),
            ),
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
        const Text(
          'Sports Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your favorite teams',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
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
          label: Text(
            team,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
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
          selectedColor: purpleButton,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          side: BorderSide(
            color: isSelected
                ? purpleButton
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: purpleButton,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _saveProfile,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
