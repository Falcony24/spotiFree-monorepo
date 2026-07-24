import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/widgets/download_button.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/player_provider.dart';
import 'package:spotifree/providers/playlist_provider.dart';
import 'package:spotifree/providers/downloaded_tracks_provider.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;

  const TrackTile({super.key, required this.track, this.onPlay});

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlists = playlistProvider.playlists;
    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.addToPlaylist),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (_, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, size: 22),
                title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await playlistProvider.addTrackToPlaylist(playlist.id, track.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.addedToPlaylist(playlist.name))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.downloadError(e.toString()))),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showCreatePlaylistDialog(context);
            },
            child: Text(t.createNewPlaylist),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.newPlaylist),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: t.playlistNameHint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  final playlist = await playlistProvider.createPlaylist(name);
                  if (playlist != null) {
                    await playlistProvider.addTrackToPlaylist(playlist.id, track.id);
                    await playlistProvider.fetchPlaylists(refresh: true);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.playlistCreated(name))),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.downloadError(e.toString()))),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.fieldMustNotBeEmpty)),
                  );
                }
              }
            },
            child: Text(t.addAndCreate),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString()}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final likedProvider = Provider.of<LikedProvider<Track>>(context);
    final isLiked = likedProvider.isLiked(track.id);
    final downloadedProvider = Provider.of<DownloadedTracksProvider>(context);
    final isDownloaded = downloadedProvider.isDownloaded(track.id);
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showInlineLike = width > 600;
        final showInlineDownload = width > 600 && !kIsWeb;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (onPlay != null) {
                onPlay!();
              } else {
                Provider.of<PlayerProvider>(context, listen: false).play(track);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  // Track number / play icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, size: 20, color: Colors.white54),
                  ),
                  const SizedBox(width: 12),

                  // Title + artist + duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (track.artist.isNotEmpty)
                              Flexible(
                                child: GestureDetector(
                                  onTap: () {
                                    if (track.artistId != null) {
                                      Navigator.pushNamed(
                                        context,
                                        '/artist',
                                        arguments: track.artistId,
                                      );
                                    }
                                  },
                                  child: Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withAlpha(140),
                                      fontSize: 12,
                                      decoration: track.artistId != null
                                          ? TextDecoration.underline
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            if (track.duration != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(Duration(milliseconds: track.duration!)),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withAlpha(100),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  if (showInlineLike)
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? theme.colorScheme.primary : Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => likedProvider.toggleLike(track),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (showInlineDownload)
                    DownloadButton(
                      track: track,
                      isDownloaded: isDownloaded,
                      onDownload: () async {
                        try {
                          await downloadedProvider.downloadTrack(track);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.download} ${track.title}')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.downloadError(e.toString()))),
                            );
                          }
                        }
                      },
                      onDelete: () async {
                        await downloadedProvider.deleteTrack(track);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${t.deleteDownloaded} ${track.title}')),
                          );
                        }
                      },
                    ),

                  // More menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'add_to_playlist') {
                        _showAddToPlaylistDialog(context);
                      } else if (value == 'like') {
                        likedProvider.toggleLike(track);
                      } else if (value == 'download') {
                        isDownloaded
                            ? downloadedProvider.deleteTrack(track)
                            : downloadedProvider.downloadTrack(track);
                      }
                    },
                    itemBuilder: (_) {
                      final items = <PopupMenuEntry<String>>[];
                      if (!showInlineLike) {
                        items.add(PopupMenuItem(
                          value: 'like',
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isLiked ? theme.colorScheme.primary : null,
                              ),
                              const SizedBox(width: 8),
                              Text(isLiked ? t.unlike : t.like),
                            ],
                          ),
                        ));
                      }
                      if (!kIsWeb && !showInlineDownload) {
                        items.add(PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(
                                isDownloaded ? Icons.check_circle : Icons.download,
                                size: 18,
                                color: isDownloaded ? theme.colorScheme.primary : null,
                              ),
                              const SizedBox(width: 8),
                              Text(isDownloaded ? t.deleteDownloaded : t.download),
                            ],
                          ),
                        ));
                      }
                      items.add(PopupMenuItem(
                        value: 'add_to_playlist',
                        child: Row(
                          children: [
                            const Icon(Icons.playlist_add, size: 18),
                            const SizedBox(width: 8),
                            Text(t.addToPlaylist),
                          ],
                        ),
                      ));
                      return items;
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}