import 'package:flutter/material.dart';
import 'package:my_chat_app/model/user.dart';
import 'package:my_chat_app/presenter/user_discovery_presenter.dart';
import 'package:my_chat_app/view/user_discovery_view.dart';
import 'package:my_chat_app/model/relationship.dart'; // New import
import 'package:my_chat_app/view/relationship_selection_dialog.dart'; // New import

class UserDiscoveryScreen extends StatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen> implements UserDiscoveryView {
  late UserDiscoveryPresenter _presenter;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = UserDiscoveryPresenter(this);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
  void displaySearchResults(List<User> users) {
    setState(() {
      _searchResults = users;
    });
  }

  @override
  void updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _presenter.searchUsers(_searchController.text.trim());
                  },
                ),
              ),
              onSubmitted: (value) {
                _presenter.searchUsers(value.trim());
              },
            ),
            const SizedBox(height: 16.0),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePictureUrl != null
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : null,
                              child: user.profilePictureUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(user.displayName),
                            subtitle: Text('@${user.username}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () async {
                                final relationshipType = await showDialog<RelationshipType>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const RelationshipSelectionDialog();
                                  },
                                );
                                if (relationshipType != null) {
                                  _presenter.addUserToChatList(user, relationshipType);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
