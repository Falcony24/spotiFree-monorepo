import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/liked_provider.dart';
import 'package:frontend/widgets/download_button.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/providers/downloaded_tracks_provider.dart';

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
            itemBuilder: (ctx, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
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
                        SnackBar(content: Text('${t.downloadError} $e')),
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
    final TextEditingController nameController = TextEditingController();
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.newPlaylist),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: t.playlistNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
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
                      SnackBar(content: Text('${t.downloadError} $e')),
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
    } else {
      return '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final likedProvider = Provider.of<LikedProvider<Track>>(context);
    final isLiked = likedProvider.isLiked(track.id);
    final downloadedProvider = Provider.of<DownloadedTracksProvider>(context);
    final isDownloaded = downloadedProvider.isDownloaded(track.id);
    final t = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        bool showLikeInline = false;
        bool showDownloadInline = false;

        if (width > 600) {
          showLikeInline = true;
          showDownloadInline = !kIsWeb;
        } else if (width > 450) {
          showLikeInline = true;
          showDownloadInline = false;
        } else {
          showLikeInline = false;
          showDownloadInline = false;
        }

        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(track.title),
          subtitle: track.artist.isNotEmpty
              ? Row(
                  children: [
                    GestureDetector(
                      child: Text(
                        track.artist,
                        style: const TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                      ),
                    ),
                    if (track.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(Duration(milliseconds: track.duration!)),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                )
              : (track.duration != null
                  ? Text(
                      _formatDuration(Duration(seconds: track.duration!)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  : null),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLikeInline)
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.green : Colors.white,
                  ),
                  onPressed: () => likedProvider.toggleLike(track),
                ),
              if (showDownloadInline)
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'add_to_playlist') {
                    _showAddToPlaylistDialog(context);
                  } else if (value == 'like') {
                    likedProvider.toggleLike(track);
                  } else if (value == 'download') {
                    if (isDownloaded) {
                      downloadedProvider.deleteTrack(track);
                    } else {
                      downloadedProvider.downloadTrack(track);
                    }
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  if (!showLikeInline) {
                    items.add(
                      PopupMenuItem(
                        value: 'like',
                        child: Row(
                          children: [
                            Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.green : Colors.white),
                            const SizedBox(width: 8),
                            Text(isLiked ? t.unlike : t.like),
                          ],
                        ),
                      ),
                    );
                  }
                  if (!kIsWeb && !showDownloadInline) {
                    items.add(
                      PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(isDownloaded ? Icons.check_circle : Icons.download,
                                color: isDownloaded ? Colors.green : Colors.white),
                            const SizedBox(width: 8),
                            Text(isDownloaded ? t.deleteDownloaded : t.download),
                          ],
                        ),
                      ),
                    );
                  }
                  items.add(
                    PopupMenuItem(
                      value: 'add_to_playlist',
                      child: Row(
                        children: [
                          const Icon(Icons.playlist_add),
                          const SizedBox(width: 8),
                          Text(t.addToPlaylist),
                        ],
                      ),
                    ),
                  );
                  return items;
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  if (onPlay != null) {
                    onPlay!();
                  } else {
                    final player = Provider.of<PlayerProvider>(context, listen: false);
                    player.play(track);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}