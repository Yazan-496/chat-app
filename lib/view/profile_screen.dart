import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/presenter/profile_presenter.dart';
import 'package:my_chat_app/view/profile_view.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements ProfileView {
  late ProfilePresenter _presenter;
  final TextEditingController _displayNameController = TextEditingController();
  app_user.User? _userProfile;
  bool _isLoading = false;
  bool _isCurrentUser = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  Relationship? _currentRelationship;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _presenter = ProfilePresenter(this, widget.userId);
    _presenter.loadUserProfile();
    _isCurrentUser = (_supabase.auth.currentUser?.id == widget.userId);
    if (!_isCurrentUser) {
      _presenter.loadRelationship();
    }

    // Periodic timer to refresh "last seen" labels
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update relative time
        });
      }
    });
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void displayUserProfile(app_user.User user) {
    setState(() {
      _userProfile = user;
      _displayNameController.text = user.displayName;
    });
  }

  @override
  void displayRelationship(Relationship? relationship) {
    setState(() {
      _currentRelationship = relationship;
    });
  }

  @override
  void navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  void updateView() {
    setState(() {});
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _presenter.updateProfilePicture(image.path);
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.isNegative) {
      return 'Online'; // lastSeen is in the future, treat as online
    } else if (difference.inSeconds < 60) {
      return 'Last seen ${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else {
      return 'Last seen ${DateFormat('MMM d, h:mm a').format(lastSeen.toLocal())}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Failed to load profile.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isCurrentUser ? _pickImage : null,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: _userProfile?.avatarColor != null 
                              ? Color(_userProfile!.avatarColor!) 
                              : Colors.blue.shade300,
                          backgroundImage: _userProfile?.profilePictureUrl != null
                              ? NetworkImage(_userProfile!.profilePictureUrl!)
                              : null,
                          child: _userProfile?.profilePictureUrl == null
                              ? Text(
                                  _userProfile!.displayName.isNotEmpty ? _userProfile!.displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Username: ${_userProfile!.username}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      if (!_isCurrentUser)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _userProfile!.isOnline ? Colors.greenAccent : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _userProfile!.isOnline ? 'Online' : _formatLastSeen(_userProfile!.lastSeen),
                              style: TextStyle(
                                color: _userProfile!.isOnline ? Colors.greenAccent : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _displayNameController,
                        readOnly: !_isCurrentUser, // Make read-only if not current user
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          enabled: _isCurrentUser, // Visually disable if not current user
                        ),
                      ),
                      if (_isCurrentUser) // Only show update button for current user
                        const SizedBox(height: 16.0),
                      if (_isCurrentUser)
                        ElevatedButton(
                          onPressed: () {
                            _presenter.updateDisplayName(_displayNameController.text.trim());
                          },
                          child: const Text('Update Display Name'),
                        ),
                      if (_isCurrentUser) // Only show delete button for current user
                        const SizedBox(height: 32.0), // Add some spacing
                      if (_isCurrentUser)
                        ElevatedButton(
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Account'),
                                  content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmDelete == true) {
                              print('User confirmed account deletion');
                              _presenter.deleteAccount();
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Style as a warning
                          child: const Text('Delete Account'),
                        ),
                      if (!_isCurrentUser) // Display relationship for other users
                        const SizedBox(height: 16.0),
                      if (!_isCurrentUser)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Relationship: ',
                              style: TextStyle(fontSize: 16),
                            ),
                            DropdownButton<RelationshipType>(
                              value: _currentRelationship?.type ?? RelationshipType.none,
                              onChanged: (RelationshipType? newValue) {
                                if (newValue != null) {
                                  _presenter.updateRelationship(newValue);
                                }
                              },
                              items: RelationshipType.values
                                  .map<DropdownMenuItem<RelationshipType>>(
                                      (RelationshipType type) {
                                return DropdownMenuItem<RelationshipType>(
                                  value: type,
                                  child: Text(type.toString().split('.').last),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
