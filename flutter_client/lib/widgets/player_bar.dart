import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/liked_provider.dart';
import 'package:frontend/models/track.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final t = AppLocalizations.of(context)!;
    
    if (player.currentTrack == null) {
      return Container(
        height: 80,
        color: Colors.grey[900],
        child: Center(
          child: Text(t.noPlayingTrack),
        ),
      );
    }

    final track = player.currentTrack!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 600;
        final isMedium = width >= 600 && width < 900;
        final isLarge = width >= 900;

        return Container(
          height: 100,
          color: Colors.grey[900],
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
          ),
          child: Row(
            children: [
              // LEWA STRONA – informacje o utworze + like
              Expanded(
                flex: isSmall ? 1 : 2,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 12 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Consumer<LikedProvider<Track>>(
                      builder: (context, likedProvider, child) {
                        final isLiked = likedProvider.isLiked(track.id);
                        return IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          iconSize: isSmall ? 20 : 24,
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.green : Colors.white,
                          ),
                          onPressed: () => _toggleLike(context, track),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ŚRODEK – odtwarzanie i suwak postępu
              Expanded(
                flex: isSmall ? 2 : 3,
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
                            size: isSmall ? 28 : 32,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 4 : 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(player.position),
                            style: TextStyle(fontSize: isSmall ? 10 : 12),
                          ),
                          Expanded(
                            child: Slider(
                              value: player.progress,
                              onChanged: (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (player.duration.inMilliseconds * value)
                                          .toInt(),
                                );
                                player.seekTo(newPosition);
                              },
                            ),
                          ),
                          Text(
                            _formatDuration(player.duration),
                            style: TextStyle(fontSize: isSmall ? 10 : 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PRAWA STRONA – głośność (ukrywana na małych ekranach)
              if (!isSmall)
                Expanded(
                  flex: isMedium ? 1 : 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: isMedium ? 18 : 20,
                      ),
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
      },
    );
  }

  Future<void> _toggleLike(BuildContext context, Track track) async {
    final likedProvider =
        Provider.of<LikedProvider<Track>>(context, listen: false);
    await likedProvider.toggleLike(track);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}