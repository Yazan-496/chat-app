import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/model/user.dart' as model;
import 'package:my_chat_app/services/database_service.dart';
import 'dart:io';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService();

  /// Retrieves a stream of the current user's data from Supabase.
  /// This allows for real-time updates to the user's profile.
  Stream<model.User?> getCurrentUserStream(String uid) {
    // For offline-first, we can combine the local database and Supabase stream.
    // However, Supabase's stream is already real-time.
    // We'll update the local cache whenever the stream emits a new value.
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((data) {
          if (data.isNotEmpty) {
            final user = model.User.fromMap(data.first);
            _dbService.saveUser(user); // Cache it
            return user;
          } else {
            return null;
          }
        });
  }

  /// Retrieves a single instance of a user's data.
  /// Offline-First: Returns local data immediately if available, then fetches from Supabase.
  Future<model.User?> getUser(String uid) async {
    // Try local first
    final localUser = await _dbService.getUser(uid);
    if (localUser != null) {
      print('UserRepository: Found user $uid in local cache.');
      // Optionally fetch from server in background to update cache
      _fetchAndCacheUser(uid); 
      return localUser;
    }

    return await _fetchAndCacheUser(uid);
  }

  Future<model.User?> _fetchAndCacheUser(String uid) async {
    print('UserRepository: Fetching user with ID from Supabase: $uid');
    
    // Don't even try if we know we are offline
    if (!_supabase.realtime.isConnected) {
      print('UserRepository: Offline, skipping fetch for user $uid');
      return null;
    }

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      
      if (data != null) {
        final user = model.User.fromMap(data);
        await _dbService.saveUser(user); // Cache it
        return user;
      }
      return null;
    } catch (e) {
      print('UserRepository: Error fetching user $uid from Supabase: $e');
      return null;
    }
  }

  /// Creates a new user profile in Supabase.
  /// This is typically called after a successful Supabase Authentication registration.
  Future<void> createUserProfile({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    try {
      // Create a map with the required fields and defaults
      final profileData = {
        'id': uid,
        'username': username,
        'display_name': displayName,
        'is_online': false,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      };
      
      print('UserRepository: Saving profile to "profiles" table for user $uid');
      
      // Use upsert to create or update the profile in the 'profiles' table.
      // We explicitly target the 'id' column for conflict resolution.
      await _supabase.from('profiles').upsert(
        profileData,
        onConflict: 'id',
      );
      
      print('UserRepository: Successfully saved profile for user $uid');
    } catch (e) {
      print('UserRepository: Error creating profile for user $uid: $e');
      rethrow; // Re-throw to let the caller (AuthService) handle it
    }
  }

  /// Updates the display name of a user in Supabase.
  Future<void> updateDisplayName(String uid, String newDisplayName) async {
    await _supabase
        .from('profiles')
        .update({'display_name': newDisplayName})
        .eq('id', uid);
  }

  /// Updates the avatar background color of a user in Supabase.
  Future<void> updateAvatarColor(String uid, int colorValue) async {
    await _supabase
        .from('profiles')
        .update({'avatar_color': colorValue})
        .eq('id', uid);
  }

  /// Uploads a new profile picture to Supabase Storage and updates the user's profile with the new URL.
  Future<String?> uploadProfilePicture(String uid, String imagePath) async {
    try {
      File file = File(imagePath);
      String fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('profile_pictures').upload(
        fileName,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final String downloadUrl = _supabase.storage.from('profile_pictures').getPublicUrl(fileName);
      
      await _supabase.from('profiles').update({'profile_picture_url': downloadUrl}).eq('id', uid);
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Searches for users by their username or display name.
  Future<List<model.User>> searchUsersByUsername(String query, String currentUserId) async {
    print('DEBUG: UserRepository.searchUsersByUsername called with query: "$query", currentUserId: "$currentUserId"');
    if (query.isEmpty) {
      print('DEBUG: Query is empty, returning empty list');
      return [];
    }
    
    try {
      // Use ilike for case-insensitive partial matching
      // We search both username and display_name
      print('DEBUG: Executing Supabase query for "profiles" table...');
      final data = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', currentUserId)
          .limit(20);
      
      print('DEBUG: Supabase returned ${data.length} results: $data');
      
      final users = (data as List).map((u) => model.User.fromMap(u)).toList();
      print('DEBUG: Mapped to ${users.length} model.User objects');
      return users;
    } catch (e) {
      print('DEBUG: UserRepository ERROR searching users for query "$query": $e');
      // If the complex OR query fails, try a simpler one as fallback
      try {
        print('DEBUG: Attempting fallback search on username only...');
        final data = await _supabase
            .from('profiles')
            .select()
            .ilike('username', '%$query%')
            .neq('id', currentUserId)
            .limit(20);
        print('DEBUG: Fallback Supabase returned ${data.length} results: $data');
        return (data as List).map((u) => model.User.fromMap(u)).toList();
      } catch (e2) {
        print('DEBUG: UserRepository FALLBACK ERROR: $e2');
        return [];
      }
    }
  }

  /// Checks if a username is already taken in the profiles table.
  Future<bool> isUsernameTaken(String username) async {
    // No try-catch here, let the caller handle network errors specifically
    final data = await _supabase
        .from('profiles')
        .select('username')
        .eq('username', username)
        .maybeSingle();
    return data != null;
  }

  /// Deletes a user's profile and associated data from Supabase.
  Future<void> deleteUserAccount(String uid) async {
    await _supabase.from('profiles').delete().eq('id', uid);
    // Note: Supabase doesn't have a direct equivalent to recursive deletion without DB functions/triggers.
    // For this migration, we'll stick to basic deletion.
  }

  /// Updates the user's online status and last seen timestamp.
  Future<void> updateUserStatus(String uid, {required bool isOnline}) async {
    try {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    } catch (e) {
      print('UserRepository: Error updating status for $uid: $e');
    }
  }

  /// Updates the user's active chat ID.
  Future<void> updateActiveChatId(String uid, String? chatId) async {
    try {
      await _supabase.from('profiles').update({
        'active_chat_id': chatId,
      }).eq('id', uid);
    } catch (e) {
      print('UserRepository: Error updating active_chat_id for $uid: $e');
    }
  }
}