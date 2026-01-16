import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Color backgroundColor;
  final Color textColor;
  final Color? playedColor;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.backgroundColor,
    required this.textColor,
    this.playedColor,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  // Pre-defined heights for a more natural looking waveform
  final List<double> _waveformHeights = [
    0.3, 0.5, 0.4, 0.7, 0.8, 0.5, 0.3, 0.4, 0.6, 0.9,
    0.7, 0.5, 0.4, 0.6, 0.8, 0.7, 0.4, 0.3, 0.5, 0.8,
    0.6, 0.4, 0.5, 0.7, 0.9, 0.6, 0.4, 0.3, 0.5, 0.4
  ];

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

  Future<void> _toggleSpeed() async {
    double newSpeed;
    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }

    setState(() {
      _playbackSpeed = newSpeed;
    });
    await _audioPlayer.setPlaybackRate(newSpeed);
  }

  Future<void> _setAudioSource() async {
    if (widget.audioUrl.isEmpty) {
      print('Error setting audio source: URL is empty');
      return;
    }
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
    final bool isMe = widget.backgroundColor == Colors.transparent; // Rough way to check if it's 'me' based on current MessageItem implementation
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              if (_playerState == PlayerState.playing) {
                await _audioPlayer.pause();
              } else if (_playerState == PlayerState.paused) {
                await _audioPlayer.resume();
              } else {
                await _audioPlayer.play(UrlSource(widget.audioUrl));
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.textColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                color: widget.textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120, // Increased width from 120 to 150
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Waveform with progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_waveformHeights.length, (index) {
                        final double progress = _duration.inMilliseconds > 0 
                            ? _position.inMilliseconds / _duration.inMilliseconds 
                            : 0.0;
                        final bool isPlayed = (index / _waveformHeights.length) < progress;
                        
                        return Container(
                          width: 2, // Thinner bars
                          height: 5 + (20 * _waveformHeights[index]), // More organic heights
                          decoration: BoxDecoration(
                            color: isPlayed 
                                ? (widget.playedColor ?? widget.textColor)
                                : widget.textColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                    // Progress Slider (Invisible track, only thumb)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 0, // Remove the "white line"
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: widget.textColor,
                      ),
                      child: Slider(
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble() > 0 
                            ? _duration.inMilliseconds.toDouble() 
                            : 1.0,
                        value: _position.inMilliseconds.toDouble().clamp(
                          0.0, 
                          _duration.inMilliseconds.toDouble() > 0 
                              ? _duration.inMilliseconds.toDouble() 
                              : 1.0
                        ),
                        onChanged: (value) async {
                          await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _playerState == PlayerState.playing || _position != Duration.zero
                      ? _formatDuration(_position)
                      : _formatDuration(_duration),
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_playbackSpeed.toString().replaceAll('.0', '')}x',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}