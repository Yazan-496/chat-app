import 'package:my_chat_app/services/authentication_service.dart';
import 'package:my_chat_app/services/local_storage_service.dart';
import 'package:my_chat_app/view/auth_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/data/user_repository.dart';
import 'package:my_chat_app/model/profile.dart';
import 'package:my_chat_app/services/database_service.dart';

class AuthPresenter {
  final AuthView _view;
  final SupabaseAuthService _authService = SupabaseAuthService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();

  List<Profile> _recentUsers = [];
  String? _lastLoggedInEmail;
  String? _lastLoggedInPassword;

  AuthPresenter(this._view);

  List<Profile> get recentUsers => _recentUsers;
  String? get lastLoggedInEmail => _lastLoggedInEmail;
  String? get lastLoggedInPassword => _lastLoggedInPassword;

  // Method to load last email, password, and recent user UIDs
  Future<void> loadRecentUsers() async {
    _lastLoggedInEmail = await _localStorageService.getLastEmail();
    _lastLoggedInPassword = await _localStorageService.getLastPassword();
    final recentUids = await _localStorageService.getRecentUids();
    _recentUsers = [];
    for (final uid in recentUids) {
      final localProfile = await DatabaseService.getProfile(uid);
      if (localProfile != null) {
        _recentUsers.add(localProfile);
        continue;
      }
      final user = await _userRepository.getUser(uid);
      if (user != null) {
        await DatabaseService.saveProfiles([user]);
        _recentUsers.add(user);
      }
    }
    _view.updateView(); // Notify the view to refresh
  }

  Future<void> removeRecentUid(String uid) async {
    await _localStorageService.removeRecentUid(uid);
    await loadRecentUsers(); // Reload recent users after removal
  }

  SupabaseAuthService get authService => _authService;

  Future<void> register(String username, String password) async {
    _view.showLoading();
    String? errorMessage = await _authService.registerUser(username, password);
    _view.hideLoading();
    if (errorMessage == null) {
      _view.showMessage('Registration successful!');
      // Save credentials locally
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _localStorageService.saveLastEmail(username);
        await _localStorageService.saveLastPassword(password);
        await _localStorageService.addRecentUid(user.id);
        await loadRecentUsers(); // Refresh recent users list
      }
      _view.navigateToHome();
    }
    else {
      _view.showMessage(errorMessage);
    }
  }

  Future<void> login(String username, String password) async {
    _view.showLoading();
    String? errorMessage = await _authService.loginUser(username, password);
    _view.hideLoading();
    if (errorMessage == null) {
      _view.showMessage('Login successful!');
      // Save credentials locally
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _localStorageService.saveLastEmail(username);
        await _localStorageService.saveLastPassword(password);
        await _localStorageService.addRecentUid(user.id);
        await loadRecentUsers(); // Refresh recent users list
      }
      _view.navigateToHome();
    }
    else {
      _view.showMessage(errorMessage);
    }
  }
}
