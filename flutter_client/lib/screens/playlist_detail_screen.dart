import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/widgets/download_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/models/playlist.dart';
import 'package:spotifree/providers/playlist_tracks_provider.dart';
import 'package:spotifree/providers/player_provider.dart';
import 'package:spotifree/widgets/track_tile.dart';

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
        if (mounted) {
          Provider.of<PlaylistTracksProvider>(context, listen: false)
              .loadTracks(widget.playlist.id);
        }
      });
    }
  }

  Future<void> _refresh() async {
    if (widget.playlist.id != 'liked_tracks') {
      await Provider.of<PlaylistTracksProvider>(context, listen: false)
          .loadTracks(widget.playlist.id);
    } else {
      await Provider.of<LikedProvider<Track>>(context, listen: false)
          .fetchLikedObjects();
    }
  }

  Future<void> _downloadPlaylist(List<Track> tracks) async {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DownloadProgressDialog(
        tracks: tracks,
        onComplete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.downloaded)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (widget.playlist.id == 'liked_tracks') {
      return Consumer<LikedProvider<Track>>(
        builder: (context, likedProvider, child) {
          final likedTracks = likedProvider.objects;
          return Scaffold(
            appBar: _buildAppBar(
              title: widget.playlist.name,
              hasTracks: likedTracks.isNotEmpty,
              onDownload: () => _downloadPlaylist(likedProvider.objects),
              onPlay: () {
                Provider.of<PlayerProvider>(context, listen: false)
                    .playTracks(likedTracks, startIndex: 0);
              },
              onRefresh: () => likedProvider.fetchLikedObjects(),
              theme: theme,
            ),
            body: RefreshIndicator(
              onRefresh: () => likedProvider.fetchLikedObjects(),
              child: likedProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : likedTracks.isEmpty
                      ? Center(
                          child: Text(t.emptyList, style: theme.textTheme.bodyLarge))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                          itemCount: likedTracks.length,
                          itemBuilder: (_, index) => TrackTile(
                            track: likedTracks[index],
                            onPlay: () {
                              Provider.of<PlayerProvider>(context, listen: false)
                                  .playTracks(likedTracks, startIndex: index);
                            },
                          ),
                        ),
            ),
          );
        },
      );
    }

    return Consumer<PlaylistTracksProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: _buildAppBar(
            title: widget.playlist.name,
            hasTracks: provider.tracks.isNotEmpty,
            onDownload: () => _downloadPlaylist(provider.tracks),
            onPlay: () {
              Provider.of<PlayerProvider>(context, listen: false)
                  .playTracks(provider.tracks, startIndex: 0);
            },
            onRefresh: _refresh,
            theme: theme,
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar({
    required String title,
    required bool hasTracks,
    required VoidCallback onDownload,
    required VoidCallback onPlay,
    required VoidCallback onRefresh,
    required ThemeData theme,
  }) {
    return AppBar(
      title: Text(title),
      actions: [
        if (hasTracks) ...[
          IconButton(icon: const Icon(Icons.download), onPressed: onDownload),
          IconButton(icon: const Icon(Icons.play_arrow), onPressed: onPlay),
        ],
        IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }

  Widget _buildBody(PlaylistTracksProvider provider) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (provider.isLoading && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(t.errorOccurred(provider.error!)));
    }
    if (provider.tracks.isEmpty) {
      return Center(child: Text(t.emptyList, style: theme.textTheme.bodyLarge));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: provider.tracks.length,
      itemBuilder: (_, index) => TrackTile(
        track: provider.tracks[index],
        onPlay: () {
          Provider.of<PlayerProvider>(context, listen: false)
              .playTracks(provider.tracks, startIndex: index);
        },
      ),
    );
  }
}