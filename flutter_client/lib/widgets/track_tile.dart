import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/data/repositories/playlist_repository.dart';
import 'package:frontend/providers/liked_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/widgets/download_button.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/providers/downloaded_tracks_provider.dart';
import 'package:frontend/domain/usecases/manage_playlist_use_case.dart';
import 'package:frontend/domain/usecases/search_use_case.dart';
import 'package:frontend/data/repositories/track_repository.dart';
import 'package:frontend/data/services/search_service.dart';
import 'package:frontend/screens/artist_screen.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;

  const TrackTile({super.key, required this.track, this.onPlay});

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final playlists = playlistProvider.playlists;
    final managePlaylistUseCase = ManagePlaylistUseCase(
      repository: PlaylistRepository(),
      modeProvider: Provider.of<ModeProvider>(context, listen: false),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dodaj do playlisty'),
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
                    await managePlaylistUseCase.addTrackToPlaylist(playlist.id, track.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dodano do ${playlist.name}')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd: $e')),
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
            child: const Text('Utwórz nową playlistę'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final managePlaylistUseCase = ManagePlaylistUseCase(
      repository: PlaylistRepository(),
      modeProvider: Provider.of<ModeProvider>(context, listen: false),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nowa playlista'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nazwa playlisty'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  final playlist = await managePlaylistUseCase.createPlaylist(name);
                  await managePlaylistUseCase.addTrackToPlaylist(playlist.id, track.id);
                  await Provider.of<PlaylistProvider>(context, listen: false)
                      .fetchPlaylists(refresh: true);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Utworzono playlistę "$name" i dodano utwór')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd: $e')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nazwa nie może być pusta')),
                  );
                }
              }
            },
            child: const Text('Utwórz i dodaj'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToArtist(BuildContext context, String artistName) async {
    if (artistName.isEmpty) return;
    final searchUseCase = SearchUseCase(searchService: SearchService());
    try {
      final results = await searchUseCase.execute(artistName, type: 'artist');
      final artistsData = results['artists'] as Map<String, dynamic>?;
      final artists = artistsData?['data'] as List? ?? [];
      if (artists.isNotEmpty) {
        final artistId = artists.first['id'].toString();
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(artistId: artistId),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nie znaleziono artysty')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd wyszukiwania: $e')),
        );
      }
    }
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
    final trackRepository = TrackRepository();

    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(track.title),
      subtitle: track.artist.isNotEmpty
          ? Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToArtist(context, track.artist),
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
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.green : Colors.white,
            ),
            onPressed: () => likedProvider.toggleLike(track),
          ),
          if (!kIsWeb)
            Consumer<DownloadedTracksProvider>(
              builder: (context, downloadedProvider, child) {
                final isDownloaded = downloadedProvider.isDownloaded(track.id);
                return DownloadButton(
                  track: track,
                  isDownloaded: isDownloaded,
                  onDownload: () async {
                    try {
                      await trackRepository.downloadTrack(track);
                      final path = await trackRepository.getDownloadedFilePath(track.id) ?? '';
                      await downloadedProvider.addDownloadedTrack(track, path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Pobrano: ${track.title}')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Błąd pobierania: $e')),
                        );
                      }
                    }
                  },
                  onDelete: () async {
                    final filePath = downloadedProvider.getFilePath(track.id);
                    if (filePath != null) {
                      final file = File(filePath);
                      if (await file.exists()) await file.delete();
                    }
                    await trackRepository.removeDownloadedTrack(track.id);
                    await downloadedProvider.removeDownloadedTrack(track.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usunięto: ${track.title}')),
                      );
                    }
                  },
                );
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'add_to_playlist') {
                _showAddToPlaylistDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_to_playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add),
                    SizedBox(width: 8),
                    Text('Dodaj do playlisty'),
                  ],
                ),
              ),
            ],
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
  }
}