import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_chat_app/model/user.dart' as app_user;
import 'package:my_chat_app/presenter/profile_presenter.dart';
import 'package:my_chat_app/view/profile_view.dart';
import 'package:my_chat_app/model/relationship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/toast_utils.dart';
import 'package:my_chat_app/view/auth_screen.dart';
import 'package:my_chat_app/main.dart';

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
    ToastUtils.showCustomToast(context, message);
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
  void navigateToSignIn() {
    // We use the global navigator key to ensure we can navigate even if this widget is being unmounted
    // during a sign-out event triggered by a StreamBuilder in main.dart.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AuthScreen()),
      (route) => false,
    );
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: _userProfile == null && _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _userProfile == null
                    ? const Center(child: Text('Failed to load profile.', style: TextStyle(color: Colors.white)))
                    : Column(
                        children: [
                          // Custom Header matching HomeScreen and SettingsScreen
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _isCurrentUser ? 'Your Profile' : 'Profile',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              children: [
                                const SizedBox(height: 24),
                                // Profile Avatar Section
                                Center(
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: _isCurrentUser ? _pickImage : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey.shade900, width: 4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 65,
                                            backgroundColor: _userProfile?.avatarColor != null 
                                                ? Color(_userProfile!.avatarColor!) 
                                                : Colors.blue.shade300,
                                            backgroundImage: _userProfile?.profilePictureUrl != null
                                                ? NetworkImage(_userProfile!.profilePictureUrl!)
                                                : null,
                                            child: _userProfile?.profilePictureUrl == null
                                                ? Text(
                                                    _userProfile!.displayName.isNotEmpty ? _userProfile!.displayName[0].toUpperCase() : '?',
                                                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (_isCurrentUser)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.black, width: 3),
                                            ),
                                            child: IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(10),
                                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                              onPressed: _pickImage,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // User Info Section
                                if (!_isCurrentUser)
                                  Center(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _userProfile!.isOnline ? Colors.greenAccent : Colors.grey,
                                                shape: BoxShape.circle,
                                                boxShadow: _userProfile!.isOnline ? [
                                                  BoxShadow(
                                                    color: Colors.greenAccent.withOpacity(0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  )
                                                ] : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              _userProfile!.isOnline ? 'Online Now' : _formatLastSeen(_userProfile!.lastSeen),
                                              style: TextStyle(
                                                color: _userProfile!.isOnline ? Colors.greenAccent : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),

                                _buildInfoTile(
                                  title: 'Username',
                                  value: '@${_userProfile!.username}',
                                  icon: Icons.alternate_email,
                                ),
                                const SizedBox(height: 16),

                                _buildEditableTile(
                                  title: 'Display Name',
                                  controller: _displayNameController,
                                  icon: Icons.person_outline,
                                  isEditable: _isCurrentUser,
                                  onUpdate: () {
                                    _presenter.updateDisplayName(_displayNameController.text.trim());
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (!_isCurrentUser)
                                  _buildRelationshipTile(),

                                const SizedBox(height: 32),
                                if (_isCurrentUser) ...[
                                  const Divider(color: Colors.grey, thickness: 0.5),
                                  const SizedBox(height: 16),
                                  _buildDangerTile(
                                    title: 'Delete Account',
                                    subtitle: 'This action is permanent and cannot be undone',
                                    icon: Icons.delete_forever,
                                    onTap: () async {
                                      final confirmDelete = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.grey.shade900,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            content: const Text('Are you sure you want to delete your account? This action cannot be undone.', style: TextStyle(color: Colors.grey)),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (confirmDelete == true) {
                                        _presenter.deleteAccount();
                                      }
                                    },
                                  ),
                                ],
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
          if (_isLoading && _userProfile != null)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTile({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditable,
    VoidCallback? onUpdate,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.blueAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller,
                      readOnly: !isEditable,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Enter $title',
                        hintStyle: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              if (isEditable)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.blueAccent),
                  onPressed: onUpdate,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, color: Colors.purpleAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relationship',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                DropdownButton<RelationshipType>(
                  value: _currentRelationship?.type ?? RelationshipType.none,
                  dropdownColor: Colors.grey.shade900,
                  underline: const SizedBox(),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                      child: Text(type.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.redAccent, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
      ),
    );
  }
}
