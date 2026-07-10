import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/downloaded_tracks_provider.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/data/services/player_service.dart';
import 'package:spotifree/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotifree/data/services/tracks_service.dart';

class PlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PlayerService _playerService = PlayerService();
  final tracksService = TracksService();
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int? _currentTaskId;
  bool _isPolling = false;
  bool _pollingCancelled = false;
  ModeProvider? _modeProvider;
  DownloadedTracksProvider? _downloadedProvider;
  List<Track> _queue = [];
  int _currentIndex = -1;

  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    final val = _position.inMilliseconds / _duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }
  double _volume = 1.0;
  double get volume => _volume;
  List<Track> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  
  SharedPreferences? _prefs;
  Timer? _saveTimer;
  bool _isRestoring = false;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _completeSubscription;

  PlayerProvider() {
    _initPrefs();
    _playerService.init();
    _positionSubscription = _playerService.onPosition.listen((pos) {
      _position = pos;
      notifyListeners();
      _debounceSavePosition();
    });
    _durationSubscription = _playerService.onDuration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _playingSubscription = _playerService.onPlaying.listen((playing) {
      _isPlaying = playing;
      if (!playing) {
        _saveCurrentState();
      }
      notifyListeners();
    });
    _completeSubscription = _playerService.onComplete.listen((_) {
      if (hasNext) {
        next();
      } else {
        _currentTrack = null;
        _isPlaying = false;
        _saveCurrentState(); 
        notifyListeners();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedVolume = _prefs?.getDouble('volume') ?? 1.0;
    _volume = savedVolume.clamp(0.0, 1.0);
    await _playerService.setVolume(_volume);
    notifyListeners();

    final lastTrackJson = _prefs?.getString('last_track');
    final lastPositionMs = _prefs?.getInt('last_position') ?? 0;
    if (lastTrackJson != null) {
      try {
        final savedTrack = Track.fromJson(jsonDecode(lastTrackJson));
        _currentTrack = savedTrack;
        _position = Duration(milliseconds: lastPositionMs);
        _duration = Duration(milliseconds: savedTrack.duration ?? 0);
        _queue = [savedTrack];
        _currentIndex = 0;
        notifyListeners();

        _isRestoring = true;
        await _preloadTrack(savedTrack, lastPositionMs);
        _isRestoring = false;
      } catch (e) {
        debugPrint('Failed to restore last track: $e');
      }
    }
  }

  Future<void> _preloadTrack(Track track, int seekMs) async {
    try {
      String source;
      if (_modeProvider != null && _modeProvider!.isOfflineMode) {
        if (_downloadedProvider == null || !_downloadedProvider!.isDownloaded(track.id)) {
          return;
        }
        final localPath = _downloadedProvider!.getFilePath(track.id);
        if (localPath == null) return;
        source = Uri.file(localPath).toString();
      } else {
        String? localPath;
        if (_downloadedProvider != null && _downloadedProvider!.isDownloaded(track.id)) {
          localPath = _downloadedProvider!.getFilePath(track.id);
        }
        if (localPath != null) {
          source = Uri.file(localPath).toString();
        } else {
          source = await TracksService().getPresignedStreamUrl(track.id);
        }
      }
      await _playerService.setSourceAndSeek(source, Duration(milliseconds: seekMs));
    } catch (e) {
      debugPrint('Preload error: $e');
      _currentTrack = null;
      _saveCurrentState();
    }
  }

  void _debounceSavePosition() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrentState();
    });
  }

  Future<void> _saveCurrentState() async {
    if (_prefs == null) return;
    if (_currentTrack != null) {
      await _prefs!.setString('last_track', jsonEncode(_currentTrack!.toJson()));
      await _prefs!.setInt('last_position', _position.inMilliseconds);
    } else {
      await _prefs!.remove('last_track');
      await _prefs!.remove('last_position');
    }
  }

  void updateDependencies(ModeProvider mode, DownloadedTracksProvider downloaded) {
    _modeProvider = mode;
    _downloadedProvider = downloaded;
  }

  void loadQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    notifyListeners();
  }

  Future<void> playCurrent() async {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _currentTrack = _queue[_currentIndex];
      await _play(_currentTrack!);
    }
  }

  Future<void> _play(Track track) async {
    await _playerService.stop();
    _isPlaying = false;
    if (_isPolling) {
      _pollingCancelled = true;
      _isPolling = false;
    }
    _currentTaskId = null;
    _currentTrack = track;
    _saveCurrentState(); 
    notifyListeners();

    try {
      if (_modeProvider != null && _modeProvider!.isOfflineMode) {
        if (_downloadedProvider == null || !_downloadedProvider!.isDownloaded(track.id)) {
          throw Exception('Offline mode: track not downloaded');
        }
        final localPath = _downloadedProvider!.getFilePath(track.id);
        if (localPath == null) throw Exception('Local file missing');
        final fileUri = Uri.file(localPath).toString();
        await _playerService.play(fileUri);
        _isPlaying = true;
        notifyListeners();
        return;
      }

      String? localPath;
      if (_downloadedProvider != null && _downloadedProvider!.isDownloaded(track.id)) {
        localPath = _downloadedProvider!.getFilePath(track.id);
      }
      if (localPath != null) {
        final fileUri = Uri.file(localPath).toString();
        await _playerService.play(fileUri);
      } else {
        final streamUrl = await tracksService.getPresignedStreamUrl(track.id);
        await _playerService.play(streamUrl);
      }
      _isPlaying = true;
      notifyListeners();
    } on PendingException catch (e) {
      _currentTaskId = e.taskId;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Utwór jest przetwarzany, proszę czekać...')),
      );
      if (!_isPolling) {
        _isPolling = true;
        _pollingCancelled = false;
        _pollTask(e.taskId, track);
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Nie można odtworzyć utworu: $e')),
      );
      _currentTrack = null;
      _saveCurrentState();
      notifyListeners();
    }
  }

  Future<void> _pollTask(int taskId, Track track) async {
    int attempts = 0;
    const maxAttempts = 30;
    while (attempts < maxAttempts && !_pollingCancelled) {
      await Future.delayed(const Duration(seconds: 2));
      if (_currentTaskId != taskId) {
        _isPolling = false;
        return;
      }
      try {
        final status = await TracksService().getTaskStatus(taskId);
        if (status['status'] == 'completed') {
          _isPolling = false;
          if (!_pollingCancelled && _currentTrack?.id == track.id) {
            await _play(track);
          }
          return;
        } else if (status['status'] == 'failed') {
          _isPolling = false;
          if (!_pollingCancelled) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Nie udało się pobrać utworu')),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Poll error: $e');
      }
      attempts++;
    }
    _isPolling = false;
    if (!_pollingCancelled) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Przekroczono czas oczekiwania')),
      );
    }
  }

  void play(Track track) {
    loadQueue([track], startIndex: 0);
    playCurrent();
  }

  void playTracks(List<Track> tracks, {int startIndex = 0}) {
    loadQueue(tracks, startIndex: startIndex);
    playCurrent();
  }

  void next() {
    if (hasNext) {
      _currentIndex++;
      playCurrent();
    }
  }

  void previous() {
    if (hasPrevious) {
      _currentIndex--;
      playCurrent();
    }
  }

  Future<void> pause() async => _playerService.pause();
  Future<void> resume() async {
  if (_currentTrack != null && _queue.isEmpty) {
    _queue = [_currentTrack!];
    _currentIndex = 0;
    await playCurrent();
  } else {
    await _playerService.resume();
  }
}

  Future<void> stop() async {
    await _playerService.stop();
    _currentTrack = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    if (_isPolling) {
      _pollingCancelled = true;
      _isPolling = false;
    }
    _currentTaskId = null;
    _queue = [];
    _currentIndex = -1;
    _saveCurrentState(); 
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _playerService.setVolume(_volume);
    await _prefs?.setDouble('volume', _volume);
    notifyListeners();
  }

  Future<void> toggleLikeCurrentTrack(BuildContext context) async {
    if (_currentTrack != null) {
      final likedProvider = Provider.of<LikedProvider<Track>>(context, listen: false);
      await likedProvider.toggleLike(_currentTrack!);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _playerService.seek(position);
    _debounceSavePosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveCurrentState();
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _completeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _playerService.dispose();
    super.dispose();
  }
}