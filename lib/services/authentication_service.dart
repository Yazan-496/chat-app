import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/services/backend_service.dart';
import 'package:my_chat_app/data/user_repository.dart';

/// This service implements the BackendService interface using Supabase Authentication.
/// It handles user registration, login, and profile updates related to Supabase Auth.
class SupabaseAuthService implements BackendService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();

  SupabaseAuthService() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (session?.user != null) {
        // User is logged in - Presence is now handled globally in main.dart via PresenceService
      }
    });
  }

  @override
  Future<void> initialize() async {
    // Supabase initialization is handled in main.dart.
  }

  @override
  Future<String?> registerUser(String username, String password) async {
    print('DEBUG: registerUser started for username: $username');
    try {
      // 1. Check if username is already taken in the profiles table
      try {
        final bool isTaken = await _userRepository.isUsernameTaken(username);
        if (isTaken) {
          print('DEBUG: Username "$username" is already taken in profiles table');
          return 'Username already exists. Please choose a different one.';
        }
      } catch (e) {
        print('ERROR: Connection issue during username check: $e');
        if (e.toString().contains('Connection reset') || e.toString().contains('ClientException')) {
          return 'Network error: Connection to Supabase was reset. Please check your internet or if the Supabase project is active.';
        }
        // If it's another error, we might still want to try signing up
      }

      // 2. Perform Supabase Auth signUp
      final AuthResponse res = await _supabase.auth.signUp(
        email: "$username@mychatapp.com",
        password: password,
        data: {
          'username': username,
          'display_name': username, // Adding this helps if a trigger expects it
        },
      );
      
      print('DEBUG: Auth.signUp response - User ID: ${res.user?.id}, Has Session: ${res.session != null}');
      
      if (res.user != null) {
        String uid = res.user!.id;
        
        // 3. Manually create user profile in profiles table
        // We only do this if you DON'T have a trigger.
        // If you DO have a trigger, this might cause a duplicate key error if the trigger succeeded.
        try {
          print('DEBUG: Attempting to create profile in DB for UID: $uid');
          await _userRepository.createUserProfile(
            uid: uid,
            username: username,
            displayName: username,
          );
          print('DEBUG: Profile creation successful for UID: $uid');
        } catch (e) {
          print('DEBUG: Manual profile creation failed (might already be created by trigger): $e');
          // If the profile already exists (created by a trigger), we ignore this error.
          // If it's another error (like RLS), we handle it.
          if (!e.toString().toLowerCase().contains('duplicate') && 
              !e.toString().toLowerCase().contains('already exists')) {
            print('CRITICAL: Profile creation failed for $uid. Error: $e');
            
            if (res.session == null) {
              return 'Account created! Please check your email ($username@mychatapp.com) to verify your account before logging in.';
            }
            
            return 'Account created, but profile setup failed: $e';
          }
        }
      } else {
        print('ERROR: Auth.signUp returned null user without throwing exception');
        return 'Registration failed: Could not create user.';
      }
      return null;
    } on AuthException catch (e) {
      print('ERROR: AuthException during registration: ${e.message} (Status: ${e.statusCode})');
      
      if (e.statusCode == '500' || e.message.contains('Database error saving new user') || e.message.contains('unexpected_failure')) {
        print('CRITICAL: This 500 error is caused by a failing Supabase Trigger.');
        print('FIX: Go to Supabase SQL Editor and run: DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;');
        return 'Registration server error. Please contact admin to check Supabase triggers.';
      }

      String errorMsg = e.message.toLowerCase();
      if (errorMsg.contains('already registered') || 
          errorMsg.contains('user already registered') || 
          errorMsg.contains('already exists') || 
          errorMsg.contains('email already registered')) {
        return 'User already exists.';
      }
      return 'Error during registration: ${e.message}';
    } catch (e) {
      print('ERROR: Unexpected error during registration: $e');
      return e.toString();
    }
  }

  @override
  Future<String?> loginUser(String username, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: "$username@mychatapp.com",
        password: password,
      );
      
      // Update user status to online after successful login
      if (res.user != null) {
        // Check if profile exists, create if missing (in case database was reset)
        final profile = await _userRepository.getUser(res.user!.id);
        if (profile == null) {
          // Profile missing, create it
          await _userRepository.createUserProfile(
            uid: res.user!.id,
            username: username,
            displayName: username,
          );
        }
        await _userRepository.updateUserStatus(res.user!.id, isOnline: true);
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> updateDisplayName(String userId, String newDisplayName) async {
    await _userRepository.updateDisplayName(userId, newDisplayName);
  }

  @override
  Future<String?> uploadProfilePicture(String userId, String filePath) async {
    return await _userRepository.uploadProfilePicture(userId, filePath);
  }

  @override
  Future<String?> uploadVoiceMessage(String chatId, String filePath) async {
    // This will be implemented in ChatRepository or a dedicated Storage service
    return null;
  }
}
