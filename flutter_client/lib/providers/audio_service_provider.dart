import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:spotifree/providers/player_provider.dart';

class AudioServiceProvider extends BaseAudioHandler {
  final PlayerProvider _playerProvider;
  Timer? _positionTimer;

  AudioServiceProvider({required PlayerProvider playerProvider})
      : _playerProvider = playerProvider {
    _playerProvider.addListener(_update);
    _update(); 
  }

  void _update() {
    _updateMediaItem();
    _updatePlaybackState();
    _startPositionPolling(); 
  }

  void _updateMediaItem() {
    final track = _playerProvider.currentTrack;
    if (track != null) {
      final duration = track.duration != null
          ? Duration(milliseconds: track.duration!)
          : const Duration(seconds: 180);
      final mediaItem = MediaItem(
        id: track.id,
        title: track.title.isNotEmpty ? track.title : "Nieznany utwór",
        artist: track.artist.isNotEmpty ? track.artist : "Nieznany artysta",
        duration: duration,
      );
      this.mediaItem.add(mediaItem);
      queue.add([mediaItem]);
    } else {
      mediaItem.add(null);
      queue.add([]);
    }
  }

  void _updatePlaybackState() {
    final playing = _playerProvider.isPlaying;
    final position = _playerProvider.position;
    final duration = _playerProvider.duration;
    final processingState = playing
        ? (position < duration ? AudioProcessingState.ready : AudioProcessingState.completed)
        : AudioProcessingState.ready;

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: const {MediaAction.seek},
      playing: playing,
      processingState: processingState,
      updatePosition: position,
      bufferedPosition: duration,
      speed: 1.0,
    ));
  }

  void _startPositionPolling() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_playerProvider.currentTrack != null) {
        _updatePlaybackState();
      }
    });
  }

  @override
  Future<void> play() async => _playerProvider.resume();
  @override
  Future<void> pause() async => _playerProvider.pause();
  @override
  Future<void> stop() async => _playerProvider.stop();
  @override
  Future<void> seek(Duration position) async => _playerProvider.seekTo(position);
  @override
  Future<void> skipToNext() async => _playerProvider.next();
  @override
  Future<void> skipToPrevious() async => _playerProvider.previous();

  @override
  Future<void> onTaskRemoved() async {
    await _playerProvider.stop();
    await super.onTaskRemoved();
  }

  Future<void> onDestroy() async {
    _positionTimer?.cancel();
    _playerProvider.removeListener(_update);
  }
}