import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/models/team_model.dart';
import 'package:sportify_app/models/sport_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/room_screen.dart';
import 'package:sportify_app/theme/app_theme.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  RoomType _selectedRoomType = RoomType.public;
  VideoContent? _selectedVideo;
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  Sport? _selectedSport;
  bool _isLoading = false;

  late Future<List<VideoContent>> _videosFuture;
  late Future<List<Sport>> _sportsFuture;
  Future<List<Team>>? _teamsFuture;

  @override
  void initState() {
    super.initState();
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _videosFuture = firestoreService.getAvailableVideos();
    _sportsFuture = firestoreService.getSports(limit: 100);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSportChanged(Sport? sport) {
    setState(() {
      _selectedSport = sport;
      _selectedTeam1 = null;
      _selectedTeam2 = null;
      if (sport != null) {
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
        _teamsFuture = firestoreService.getTeamsBySport(sport.name, limit: 100);
      } else {
        _teamsFuture = null;
      }
    });
  }

  void _onTeam1Changed(Team? team) {
    setState(() {
      _selectedTeam1 = team;
      // If team1 and team2 are the same, clear team2
      if (team != null && _selectedTeam2 != null && team.name == _selectedTeam2!.name) {
        _selectedTeam2 = null;
      }
    });
  }

  void _onTeam2Changed(Team? team) {
    setState(() {
      _selectedTeam2 = team;
      // If team1 and team2 are the same, clear team1
      if (team != null && _selectedTeam1 != null && team.name == _selectedTeam1!.name) {
        _selectedTeam1 = null;
      }
    });
  }

  Future<void> _submitCreateRoom() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Validate that a video was selected
    if (_selectedVideo == null) {
      _showErrorSnackBar('Please select a video to watch');
      return;
    }

    // 3. Validate teams
    if (_selectedTeam1 == null || _selectedTeam2 == null) {
      _showErrorSnackBar('Please select both Team 1 and Team 2');
      return;
    }

    // 4. Validate teams are from the same sport
    if (_selectedTeam1!.sport != _selectedTeam2!.sport) {
      _showErrorSnackBar('Both teams must belong to the same sport');
      return;
    }

    // 5. Validate teams are not the same
    if (_selectedTeam1!.name == _selectedTeam2!.name) {
      _showErrorSnackBar('Team 1 and Team 2 must be different');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    final hostId = authService.currentUser?.uid;
    if (hostId == null) {
      _showErrorSnackBar('Error: You are not logged in.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newRoomId = await firestoreService.createRoom(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        contentId: _selectedVideo!.contentId,
        hostId: hostId,
        roomType: _selectedRoomType,
        team1Name: _selectedTeam1!.name,
        team2Name: _selectedTeam2!.name,
      );

      if (newRoomId != null) {
        if (mounted) {
          final createdRoom = await firestoreService.getRoomById(newRoomId);
          if (createdRoom != null && mounted) {
            _nameController.clear();
            _descriptionController.clear();
            setState(() {
              _selectedVideo = null;
              _selectedRoomType = RoomType.public;
              _selectedTeam1 = null;
              _selectedTeam2 = null;
              _selectedSport = null;
              _teamsFuture = null;
            });
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RoomScreen(room: createdRoom),
              ),
            );
          } else if (mounted) {
            Navigator.of(context).pop();
            _showErrorSnackBar('Room created but could not load it.');
          }
        }
      } else {
        _showErrorSnackBar('Failed to create room.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shows a dialog to enter room code for private rooms
  Future<bool> _showRoomCodeDialog(Room room) async {
    final codeController = TextEditingController();
    bool? result = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.accent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'Private Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This room requires an access code.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter Room Code',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  hintText: 'e.g., Cr23AB',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                result = false;
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredCode = codeController.text.trim().toUpperCase();
                if (enteredCode == room.roomCode?.toUpperCase()) {
                  Navigator.of(dialogContext).pop();
                  result = true;
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid room code. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Shows delete room dialog
  Future<void> _showDeleteRoomDialog(BuildContext context, Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.accent.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        title: const Text(
          'Delete Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this room? This action cannot be undone and all messages will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteRoom(room.roomId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete room: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Navigates to room screen with code verification for private rooms
  Future<void> _navigateToRoomWithVerification(Room room) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    
    // If user is the host, allow direct access
    if (currentUserId == room.hostId) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomScreen(room: room),
        ),
      );
      return;
    }
    
    // If room is private, ask for code
    if (room.roomType == RoomType.private) {
      final hasAccess = await _showRoomCodeDialog(room);
      if (hasAccess && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RoomScreen(room: room),
          ),
        );
      }
    } else {
      // Public room, allow direct access
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomScreen(room: room),
        ),
      );
    }
  }

  // Color scheme matching login page
  static const Color containerGradient1 = Color(0xFF1a1a2e);
  static const Color containerGradient2 = Color(0xFF16213e);
  static const Color containerGradient3 = Color(0xFF0f3460);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        elevation: 0,
        title: const Text(
          'Create New Room',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
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
                        const Text(
                          'Create New Room',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // --- ROOM NAME ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter room name',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a room name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- ROOM DESCRIPTION ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter description',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- SPORT SELECTOR ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Sport',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Sport>>(
                              future: _sportsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
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
                                  return const Center(
                                    child: Text(
                                      'No sports found in database.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                final sports = snapshot.data!;
                                return DropdownButtonFormField<Sport>(
                                  // ignore: deprecated_member_use
                                  value: _selectedSport,
                                  hint: Text(
                                    'Select a sport',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                  isExpanded: true,
                                  dropdownColor: containerGradient1,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
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
                                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onChanged: _onSportChanged,
                                  items: sports.map((sport) {
                                    return DropdownMenuItem(
                                      value: sport,
                                      child: Text(
                                        sport.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      value == null ? 'Please select a sport' : null,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- TEAM SELECTION (Side by Side) ---
                        if (_selectedSport != null) ...[
                          Row(
                            children: [
                              // Team 1 Dropdown
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Team 1',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<List<Team>>(
                                      future: _teamsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No teams found for this sport.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          );
                                        }

                                        final teams = snapshot.data!;
                                        return DropdownButtonFormField<Team>(
                                          // ignore: deprecated_member_use
                                          value: _selectedTeam1,
                                          hint: Text(
                                            'Select Team 1',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                                          ),
                                          isExpanded: true,
                                          dropdownColor: containerGradient1,
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                          decoration: InputDecoration(
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
                                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: _onTeam1Changed,
                                          items: teams.map((team) {
                                            return DropdownMenuItem(
                                              value: team,
                                              child: Text(
                                                team.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          validator: (value) =>
                                              value == null ? 'Required' : null,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Team 2 Dropdown
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Team 2',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<List<Team>>(
                                      future: _teamsFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error: ${snapshot.error}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No teams found for this sport.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          );
                                        }

                                        final teams = snapshot.data!;
                                        // Filter out team1 from team2 options
                                        final availableTeams = teams.where((team) => 
                                          _selectedTeam1 == null || team.name != _selectedTeam1!.name
                                        ).toList();

                                        return DropdownButtonFormField<Team>(
                                          // ignore: deprecated_member_use
                                          value: _selectedTeam2,
                                          hint: Text(
                                            'Select Team 2',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                                          ),
                                          isExpanded: true,
                                          dropdownColor: containerGradient1,
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                          decoration: InputDecoration(
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
                                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: _onTeam2Changed,
                                          items: availableTeams.map((team) {
                                            return DropdownMenuItem(
                                              value: team,
                                              child: Text(
                                                team.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          validator: (value) =>
                                              value == null ? 'Required' : null,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // --- VIDEO SELECTOR ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Video',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<VideoContent>>(
                              future: _videosFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
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
                                  return const Center(
                                    child: Text(
                                      'No videos found in database. Please add a video to the "videos" collection.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                final videos = snapshot.data!;
                                return DropdownButtonFormField<VideoContent>(
                                  // ignore: deprecated_member_use
                                  value: _selectedVideo,
                                  hint: Text(
                                    'Select a video',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                  isExpanded: true,
                                  dropdownColor: containerGradient1,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
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
                                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onChanged: (video) {
                                    setState(() => _selectedVideo = video);
                                  },
                                  items: videos.map((video) {
                                    return DropdownMenuItem(
                                      value: video,
                                      child: Text(
                                        video.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                  validator: (value) =>
                                      value == null ? 'Please select a video' : null,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // --- ROOM TYPE SELECTOR ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<RoomType>(
                              // ignore: deprecated_member_use
                              value: _selectedRoomType,
                              dropdownColor: containerGradient1,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
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
                                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (type) {
                                setState(() {
                                  _selectedRoomType = type ?? RoomType.public;
                                });
                              },
                              items: RoomType.values.map((type) {
                                String typeName =
                                    type.name[0].toUpperCase() + type.name.substring(1);
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    typeName,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // --- SUBMIT BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitCreateRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Room',
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
            ],
          ),
        ),
      ),
    );
  }
}
