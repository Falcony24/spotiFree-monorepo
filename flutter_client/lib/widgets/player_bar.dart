import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/liked_tracks_provider.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final likedProvider = Provider.of<LikedTracksProvider>(context, listen: false);

    if (player.currentTrack == null) {
      return Container(
        height: 80,
        color: Colors.grey[900],
        child: const Center(
          child: Text('Brak odtwarzanego utworu'),
        ),
      );
    }

    final track = player.currentTrack!;
    final isLiked = likedProvider.isLiked(track.id);

    return Container(
      height: 100,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.green : Colors.white,
                  ),
                  onPressed: () => player.toggleLikeCurrentTrack(context),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 28),
                      onPressed: player.hasPrevious ? player.previous : null,
                    ),
                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      onPressed: () {
                        if (player.isPlaying) {
                          player.pause();
                        } else {
                          player.resume();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      onPressed: player.hasNext ? player.next : null,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(player.position),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: player.progress,
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (player.duration.inMilliseconds * value).toInt(),
                            );
                            player.seekTo(newPosition);
                          },
                        ),
                      ),
                      Text(
                        _formatDuration(player.duration),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.volume_up, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: player.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      player.setVolume(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}