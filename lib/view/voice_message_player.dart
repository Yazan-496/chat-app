import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Color backgroundColor;
  final Color textColor;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _setAudioSource();
  }

  Future<void> _setAudioSource() async {
    try {
      await _audioPlayer.setSourceUrl(widget.audioUrl);
    } catch (e) {
      print('Error setting audio source: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: widget.textColor,
          ),
          onPressed: () async {
            if (_playerState == PlayerState.playing) {
              await _audioPlayer.pause();
            } else if (_playerState == PlayerState.paused) {
              await _audioPlayer.resume();
            } else {
              await _audioPlayer.play(UrlSource(widget.audioUrl));
            }
          },
        ),
        Flexible(
          child: Slider(
            min: 0.0,
            max: _duration.inMilliseconds.toDouble(),
            value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
            onChanged: (value) async {
              await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
            },
            activeColor: widget.textColor,
            inactiveColor: widget.textColor.withOpacity(0.4),
          ),
        ),
        Text(
          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
          style: TextStyle(color: widget.textColor, fontSize: 12),
        ),
      ],
    );
  }
}