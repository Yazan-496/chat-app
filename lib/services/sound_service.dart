import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();

  late final AudioPlayer _sentPlayer;
  late final AudioPlayer _receivedPlayer;

  bool _hasSent = false;
  bool _hasReceived = false;

  SoundService._internal() {
    _sentPlayer = AudioPlayer();
    _receivedPlayer = AudioPlayer();

    _sentPlayer.setReleaseMode(ReleaseMode.stop);
    _receivedPlayer.setReleaseMode(ReleaseMode.stop);

    _precheckAssets();
  }

  Future<void> _precheckAssets() async {
    try {
      await rootBundle.load('assets/sounds/sent.mp3');
      _hasSent = true;
    } catch (_) {
      _hasSent = false;
    }
    try {
      await rootBundle.load('assets/sounds/received.mp3');
      _hasReceived = true;
    } catch (_) {
      _hasReceived = false;
    }
  }

  Future<void> playSent() async {
    try {
      if (!_hasSent) return;
      await _sentPlayer.play(AssetSource('sounds/sent.mp3'));
    } catch (_) {}
  }

  Future<void> playReceived() async {
    try {
      if (!_hasReceived) return;
      await _receivedPlayer.play(AssetSource('sounds/received.mp3'));
    } catch (_) {}
  }
}
