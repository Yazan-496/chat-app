import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/auth_presenter.dart';
import 'package:my_chat_app/view/auth_view.dart';
import 'package:my_chat_app/view/home_screen.dart'; // New import

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> implements AuthView {
  late AuthPresenter _presenter;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenter = AuthPresenter(this);
    _loadSavedCredentials(); // New method call
  }

  Future<void> _loadSavedCredentials() async {
    await _presenter.loadRecentUsers();
    if (_presenter.lastLoggedInEmail != null) {
      _usernameController.text = _presenter.lastLoggedInEmail!;
    }
    setState(() {}); // Refresh UI with loaded data
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
  void navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  void updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display recent accounts
            if (_presenter.recentUsers.isNotEmpty)
              SizedBox(
                height: 100, // Adjust height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presenter.recentUsers.length,
                  itemBuilder: (context, index) {
                    final user = _presenter.recentUsers[index];
                    return Dismissible(
                      key: ValueKey(user.uid),
                      direction: DismissDirection.up,
                      onDismissed: (direction) async {
                        await _presenter.removeRecentUid(user.uid);
                      },
                      background: Container(color: Colors.red, alignment: Alignment.center), // Removed icon as it's not visible when swiping up
                      child: GestureDetector(
                        onTap: () {
                          _usernameController.text = user.username; // Or user.email if you have an email field
                          _passwordController.clear(); // Clear password for security
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: user.profilePictureUrl != null
                                    ? NetworkImage(user.profilePictureUrl!)
                                    : null,
                                child: user.profilePictureUrl == null
                                    ? const Icon(Icons.person, size: 30)
                                    : null,
                              ),
                              const SizedBox(height: 4.0),
                              Text(user.displayName, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_presenter.recentUsers.isNotEmpty) const SizedBox(height: 16.0),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _presenter.login(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: () {
                          _presenter.register(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
