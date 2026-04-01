import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<Duration> _durationController = StreamController.broadcast();
  final StreamController<bool> _playingController = StreamController.broadcast();
  final StreamController<void> _completionController = StreamController.broadcast();

  Stream<Duration> get onPosition => _positionController.stream;
  Stream<Duration> get onDuration => _durationController.stream;
  Stream<bool> get onPlaying => _playingController.stream;
  Stream<void> get onComplete => _completionController.stream;

  void init() {
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _audioPlayer.onPositionChanged.listen((pos) {
      _positionController.add(pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      _durationController.add(dur);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playingController.add(state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _completionController.add(null);
    });
  }

  Future<void> play(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  void dispose() {
    _audioPlayer.dispose();
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _completionController.close();
  }
}