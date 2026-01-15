import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rwxznbitzniokfgzjmkg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3eHpuYml0em5pb2tmZ3pqbWtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyODc4NTUsImV4cCI6MjA4Mzg2Mzg1NX0.Vba99L2UG73q3WdmPRINQcRb9Y9JQjFsnISVbrA-eLM',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}