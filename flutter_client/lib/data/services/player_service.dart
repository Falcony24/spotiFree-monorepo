import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamController<Duration>? _positionController;
  StreamController<Duration>? _durationController;
  StreamController<bool>? _playingController;
  StreamController<void>? _completionController;

  bool _initialized = false;
  bool _disposed = false;

  Stream<Duration> get onPosition => _getPositionController().stream;
  Stream<Duration> get onDuration => _getDurationController().stream;
  Stream<bool> get onPlaying => _getPlayingController().stream;
  Stream<void> get onComplete => _getCompletionController().stream;

  StreamController<Duration> _getPositionController() {
    if (_positionController == null || _positionController!.isClosed) {
      _positionController = StreamController<Duration>.broadcast();
    }
    return _positionController!;
  }

  StreamController<Duration> _getDurationController() {
    if (_durationController == null || _durationController!.isClosed) {
      _durationController = StreamController<Duration>.broadcast();
    }
    return _durationController!;
  }

  StreamController<bool> _getPlayingController() {
    if (_playingController == null || _playingController!.isClosed) {
      _playingController = StreamController<bool>.broadcast();
    }
    return _playingController!;
  }

  StreamController<void> _getCompletionController() {
    if (_completionController == null || _completionController!.isClosed) {
      _completionController = StreamController<void>.broadcast();
    }
    return _completionController!;
  }

  static Source _sourceFor(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      return DeviceFileSource(path);
    }
    return UrlSource(url);
  }

  void init() {
    if (_initialized && !_disposed) return;
    _disposed = false;

    final posCtrl = _getPositionController();
    final durCtrl = _getDurationController();
    final playCtrl = _getPlayingController();
    final compCtrl = _getCompletionController();

    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _audioPlayer.onPositionChanged.listen((pos) {
      if (!posCtrl.isClosed) posCtrl.add(pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (!durCtrl.isClosed) durCtrl.add(dur);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!playCtrl.isClosed) playCtrl.add(state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!compCtrl.isClosed) compCtrl.add(null);
    });

    _initialized = true;
  }

  Future<void> setSource(String url) async {
    await _audioPlayer.setSource(_sourceFor(url));
  }

  Future<void> setSourceAndSeek(String url, Duration position) async {
    await _audioPlayer.setSource(_sourceFor(url));
    await _audioPlayer.seek(position);
  }

  Future<void> play(String url) async {
    try {
      await _audioPlayer.play(_sourceFor(url));
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
    _disposed = true;
    _audioPlayer.dispose();
    _positionController?.close();
    _durationController?.close();
    _playingController?.close();
    _completionController?.close();
  }
}