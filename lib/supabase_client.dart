import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnc3l2Zm15dGlqc3B5c2toZXhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4MjQ4NDEsImV4cCI6MjA4NDQwMDg0MX0.hWUoVBO8uK-zN5z3NCFtY6dc11HH7K8x60fmesEEwMA';
  static const String baseUrl = 'https://sgsyvfmytijspyskhexk.supabase.co';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: baseUrl,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
