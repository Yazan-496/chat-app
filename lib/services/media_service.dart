import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<String?> uploadFile(String filePath, String storagePath) async {
    try {
      File file = File(filePath);
      UploadTask uploadTask = _storage.ref().child(storagePath).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
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
