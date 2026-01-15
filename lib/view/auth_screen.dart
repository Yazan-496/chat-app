import 'package:flutter/material.dart';
import 'package:my_chat_app/presenter/auth_presenter.dart';
import 'package:my_chat_app/view/auth_view.dart';
import 'package:my_chat_app/view/home_screen.dart'; // New import
import 'package:my_chat_app/utils/toast_utils.dart';

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
    if (_presenter.lastLoggedInPassword != null) {
      _passwordController.text = _presenter.lastLoggedInPassword!;
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
    ToastUtils.showCustomToast(context, message);
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Brand/Logo Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue chatting',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Recent Users Section
              if (_presenter.recentUsers.isNotEmpty) ...[
                const Text(
                  'Recent accounts',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 110,
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
                        background: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _usernameController.text = user.username;
                            _passwordController.clear();
                          },
                          child: Container(
                            width: 85,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade900, width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade900,
                                    backgroundImage: user.profilePictureUrl != null
                                        ? NetworkImage(user.profilePictureUrl!)
                                        : null,
                                    child: user.profilePictureUrl == null
                                        ? Text(
                                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.displayName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Input Fields
              _buildInputField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // Actions
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _presenter.login(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          _presenter.register(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create New Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
