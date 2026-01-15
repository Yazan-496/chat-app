import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<String?> uploadFile(String filePath, String storagePath) async {
    try {
      final file = File(filePath);
      
      // storagePath format: "bucket_name/path/to/file.ext"
      final pathParts = storagePath.split('/');
      final bucketName = pathParts.first;
      final fileRelativePath = pathParts.sublist(1).join('/');
      
      await _supabase.storage.from(bucketName).upload(
        fileRelativePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String publicUrl = _supabase.storage.from(bucketName).getPublicUrl(fileRelativePath);
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<String?> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        return filePath;
      } else {
        print('Microphone permission not granted.');
        return null;
      }
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      return path; // Returns the recorded file path
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  Future<bool> isRecording() async {
    return _audioRecorder.isRecording();
  }
}
