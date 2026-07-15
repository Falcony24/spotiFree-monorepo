import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/providers/player_provider.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final visible = playerProvider.currentTrack != null || playerProvider.queue.isNotEmpty;
        final track = playerProvider.currentTrack;
        final isPlaying = playerProvider.isPlaying;
        final progress = playerProvider.progress;
        final screenWidth = MediaQuery.of(context).size.width;

        return Visibility(
          visible: visible,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Container(
            color: Colors.blueGrey, 
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (track != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        // child: Image.network(
                        //   track.coverUrl ?? '',
                        //   width: 40,
                        //   height: 40,
                        //   fit: BoxFit.cover,
                        //   errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40),
                        // ),
                      )
                    else
                      const SizedBox(width: 40, height: 40),
                      
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? "???",
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track?.artist ?? '???',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (track != null)
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () => playerProvider.toggleLikeCurrentTrack(context),
                        color: Colors.white,
                      ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () {
                        if (isPlaying) {
                          playerProvider.pause();
                        } else {
                          playerProvider.resume();
                        }
                      },
                      color: Colors.white,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: playerProvider.hasNext ? playerProvider.next : null,
                      color: Colors.white,
                    ),
                  ],
                ),
                Container(
                  height: 4,
                  width: screenWidth,
                  color: Colors.grey[800]?.withOpacity(0.5), 
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: progress * screenWidth,
                      height: 4,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}