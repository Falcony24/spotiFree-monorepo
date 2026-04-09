import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/playlist_tracks_provider.dart';
import 'package:frontend/providers/liked_tracks_provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/widgets/track_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.playlist.id != 'liked_tracks') {
      Future.microtask(() {
        Provider.of<PlaylistTracksProvider>(context, listen: false)
            .loadTracks(widget.playlist.id);
      });
    }
  }

  Future<void> _refresh() async {
    if (widget.playlist.id != 'liked_tracks') {
      await Provider.of<PlaylistTracksProvider>(context, listen: false)
          .loadTracks(widget.playlist.id);
    } else {
      await Provider.of<LikedTracksProvider>(context, listen: false)
          .fetchLikedTracks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playlist.id == 'liked_tracks') {
      return Consumer<LikedTracksProvider>(
        builder: (context, likedProvider, child) {
          final likedTracks = likedProvider.likedItems
              .map((item) => item['track'] as Track?)
              .where((track) => track != null)
              .cast<Track>()
              .toList();
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.playlist.name),
              backgroundColor: Colors.black,
              actions: [
                if (likedTracks.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      final player = Provider.of<PlayerProvider>(context, listen: false);
                      player.playTracks(likedTracks, startIndex: 0);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => likedProvider.fetchLikedTracks(),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => likedProvider.fetchLikedTracks(),
              child: likedProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : likedTracks.isEmpty
                      ? const Center(child: Text('Brak polubionych utworów'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: likedTracks.length,
                          itemBuilder: (ctx, index) {
                            final track = likedTracks[index];
                            return TrackTile(
                              track: track,
                              onPlay: () {
                                final player = Provider.of<PlayerProvider>(context, listen: false);
                                player.playTracks(likedTracks, startIndex: index);
                              },
                            );
                          },
                        ),
            ),
          );
        },
      );
    }
    
    return Consumer<PlaylistTracksProvider>(
      builder: (context, provider, child) {
        return Scaffold(
                      appBar: AppBar(
                  title: Text(widget.playlist.name),
                  backgroundColor: Colors.black,
                  actions: [
                    if (provider.tracks.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          final player = Provider.of<PlayerProvider>(context, listen: false);
                          player.playTracks(provider.tracks, startIndex: 0);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh,
                    ),
                  ],
                ),
          body: RefreshIndicator(
            onRefresh: () => _refresh(),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(PlaylistTracksProvider provider) {
    if (provider.isLoading && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Błąd: ${provider.error}'));
    }
    if (provider.tracks.isEmpty) {
      return const Center(child: Text('Brak utworów w playliście'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.tracks.length,
      itemBuilder: (ctx, index) {
        final track = provider.tracks[index];
        return TrackTile(
          track: track,
          onPlay: () {
            final player = Provider.of<PlayerProvider>(context, listen: false);
            player.playTracks(provider.tracks, startIndex: index);
          },
        );
      },
    );
  }
}