import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();

  late final AudioPlayer _sentPlayer;
  late final AudioPlayer _receivedPlayer;
  late final AudioPlayer _typingPlayer;

  Timer? _typingTimer;
  bool _typingLoopActive = false;
  Duration _typingInterval = const Duration(seconds: 2);
  bool _hasSent = false;
  bool _hasReceived = false;
  bool _hasTyping = false;

  SoundService._internal() {
    _sentPlayer = AudioPlayer();
    _receivedPlayer = AudioPlayer();
    _typingPlayer = AudioPlayer();

    _sentPlayer.setReleaseMode(ReleaseMode.stop);
    _receivedPlayer.setReleaseMode(ReleaseMode.stop);
    _typingPlayer.setReleaseMode(ReleaseMode.stop);

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
    try {
      await rootBundle.load('assets/sounds/typing.mp3');
      _hasTyping = true;
    } catch (_) {
      _hasTyping = false;
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

  void startTypingLoop({Duration? interval}) {
    if (interval != null) _typingInterval = interval;
    if (_typingLoopActive) return;
    if (!_hasTyping) return;
    _typingLoopActive = true;
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(_typingInterval, (_) async {
      try {
        await _typingPlayer.play(AssetSource('sounds/typing.mp3'));
      } catch (_) {}
    });
  }

  void stopTypingLoop() {
    _typingLoopActive = false;
    _typingTimer?.cancel();
    _typingTimer = null;
    // Do not stop player abruptly; let current tick finish
  }
}
