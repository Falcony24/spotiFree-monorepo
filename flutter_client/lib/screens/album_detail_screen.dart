import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/track_tile.dart';
import 'package:frontend/providers/liked_albums_provider.dart';
import 'package:frontend/providers/album_detail_provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/mode_provider.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Album? album;
  final String? albumId;

  const AlbumDetailScreen({super.key, this.album, this.albumId});

  @override
  Widget build(BuildContext context) {
    final effectiveAlbumId = album?.id ?? albumId;
    if (effectiveAlbumId == null) {
      return const Scaffold(
        body: Center(child: Text('Brak identyfikatora albumu')),
      );
    }
    return AlbumDetailScreenContent(album: album, albumId: effectiveAlbumId);
  }
}

class AlbumDetailScreenContent extends StatefulWidget {
  final Album? album;
  final String albumId;

  const AlbumDetailScreenContent({super.key, this.album, required this.albumId});

  @override
  State<AlbumDetailScreenContent> createState() => _AlbumDetailScreenContentState();
}

class _AlbumDetailScreenContentState extends State<AlbumDetailScreenContent> {
  String? _albumTitle;
  String? _albumArtist;
  bool _isLoadingMetadata = false;
  String? _metadataError;

  @override
  void initState() {
    super.initState();
    if (widget.album != null) {
      _albumTitle = widget.album!.title;
      _albumArtist = widget.album!.artist;
    } else {
      _fetchMetadata();
    }
  }

  Future<void> _fetchMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
      _metadataError = null;
    });
    try {
      final data = await ApiService().getAlbum(widget.albumId);
      setState(() {
        _albumTitle = data['title'];
        _albumArtist = data['artist'];
      });
    } catch (e) {
      setState(() {
        _metadataError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_albumTitle == null) return;
    final album = Album(
      id: widget.albumId,
      title: _albumTitle!,
      artist: _albumArtist,
    );
    final provider = Provider.of<LikedAlbumsProvider>(context, listen: false);
    await provider.toggleLike(album);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<ModeProvider, AlbumDetailProvider>(
      create: (_) => AlbumDetailProvider(widget.albumId),
      update: (_, modeProvider, previous) {
        final provider = previous ?? AlbumDetailProvider(widget.albumId);
        provider.setModeProvider(modeProvider);
        return provider;
      },
      child: Consumer<AlbumDetailProvider>(
        builder: (context, provider, child) {
          final modeProvider = Provider.of<ModeProvider>(context);
          if (!modeProvider.isOfflineMode && provider.tracks.isEmpty && !provider.isLoadingTracks) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.fetchTracks();
            });
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(_albumTitle ?? 'Album'),
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
                Consumer<LikedAlbumsProvider>(
                  builder: (context, likedProvider, child) {
                    final isLiked = likedProvider.isLiked(widget.albumId);
                    return IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.green : Colors.white,
                      ),
                      onPressed: _toggleLike,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchTracks(forceRefresh: true),
                ),
              ],
            ),
            body: _isLoadingMetadata
                ? const Center(child: CircularProgressIndicator())
                : _metadataError != null
                    ? Center(child: Text('Błąd: $_metadataError'))
                    : _buildBody(provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(AlbumDetailProvider provider) {
    if (provider.isLoadingTracks && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorTracks != null) {
      return Center(child: Text('Błąd: ${provider.errorTracks}'));
    }
    if (provider.tracks.isEmpty) {
      return const Center(child: Text('Brak utworów w tym albumie'));
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchTracks(),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: provider.tracks.length,
        itemBuilder: (ctx, index) {
          final track = provider.tracks[index];
          return TrackTile(
            track: track,
            onPlay: () {
              final player = Provider.of<PlayerProvider>(ctx, listen: false);
              player.playTracks(provider.tracks, startIndex: index);
            },
          );
        },
      ),
    );
  }
}