import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/model/user.dart';
import 'package:my_chat_app/presenter/profile_presenter.dart';
import 'package:my_chat_app/view/profile_view.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements ProfileView {
  late ProfilePresenter _presenter;
  final TextEditingController _displayNameController = TextEditingController();
  User? _userProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = ProfilePresenter(this);
    _presenter.loadUserProfile();
  }

  @override
  void dispose() {
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
  void displayUserProfile(User user) {
    setState(() {
      _userProfile = user;
      _displayNameController.text = user.displayName;
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
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _userProfile?.profilePictureUrl != null
                              ? NetworkImage(_userProfile!.profilePictureUrl!)
                              : null,
                          child: _userProfile?.profilePictureUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Username: ${_userProfile!.username}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _presenter.updateDisplayName(_displayNameController.text.trim());
                        },
                        child: const Text('Update Display Name'),
                      ),
                      const SizedBox(height: 32.0), // Add some spacing
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
                            // TODO: Implement actual account deletion logic
                            print('User confirmed account deletion');
                            _presenter.deleteAccount();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Style as a warning
                        child: const Text('Delete Account'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
