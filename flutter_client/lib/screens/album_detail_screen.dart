import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/widgets/download_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/widgets/track_tile.dart';
import 'package:spotifree/providers/album_detail_provider.dart';
import 'package:spotifree/providers/player_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/domain/usecases/get_album_tracks_use_case.dart';
import 'package:spotifree/domain/usecases/get_album_metadata_use_case.dart';
import 'package:spotifree/data/repositories/album_repository.dart';

class AlbumDetailScreen extends StatelessWidget {
  final Album? album;
  final String? albumId;
  final GetAlbumTracksUseCase? getAlbumTracksUseCase;
  final GetAlbumMetadataUseCase? getAlbumMetadataUseCase;

  const AlbumDetailScreen({
    super.key,
    this.album,
    this.albumId,
    this.getAlbumTracksUseCase,
    this.getAlbumMetadataUseCase,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAlbumId = album?.id ?? albumId;
    final t = AppLocalizations.of(context)!;

    if (effectiveAlbumId == null) {
      return Scaffold(
        body: Center(child: Text(t.missingAlbumId)),
      );
    }
    return AlbumDetailScreenContent(
      album: album,
      albumId: effectiveAlbumId,
      getAlbumTracksUseCase: getAlbumTracksUseCase,
      getAlbumMetadataUseCase: getAlbumMetadataUseCase,
    );
  }
}

class AlbumDetailScreenContent extends StatefulWidget {
  final Album? album;
  final String albumId;
  final GetAlbumTracksUseCase? getAlbumTracksUseCase;
  final GetAlbumMetadataUseCase? getAlbumMetadataUseCase;

  const AlbumDetailScreenContent({
    super.key,
    this.album,
    required this.albumId,
    this.getAlbumTracksUseCase,
    this.getAlbumMetadataUseCase,
  });

  @override
  State<AlbumDetailScreenContent> createState() => _AlbumDetailScreenContentState();
}

class _AlbumDetailScreenContentState extends State<AlbumDetailScreenContent> {
  String? _albumTitle;
  String? _albumArtist;
  bool _isLoadingMetadata = false;
  String? _metadataError;

  late AlbumDetailProvider _albumDetailProvider;
  late GetAlbumMetadataUseCase _metadataUseCase;

  @override
  void initState() {
    super.initState();

    final modeProvider = Provider.of<ModeProvider>(context, listen: false);

    // Use injected use case or create a default one
    final tracksUseCase = widget.getAlbumTracksUseCase ??
        GetAlbumTracksUseCase(
          repository: AlbumRepository(),
          modeProvider: modeProvider,
        );

    _metadataUseCase = widget.getAlbumMetadataUseCase ??
        GetAlbumMetadataUseCase(AlbumRepository(), modeProvider);

    if (widget.album != null) {
      _albumTitle = widget.album!.title;
      _albumArtist = widget.album!.artist;
    } else {
      _fetchMetadata();
    }

    _albumDetailProvider = AlbumDetailProvider(
      albumId: widget.albumId,
      getAlbumTracksUseCase: tracksUseCase,
      modeProvider: modeProvider,
    );

    _albumDetailProvider.fetchTracks();
  }

  Future<void> _fetchMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
      _metadataError = null;
    });
    try {
      final album = await _metadataUseCase.execute(widget.albumId);
      setState(() {
        _albumTitle = album.title;
        _albumArtist = album.artist;
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
    final provider = Provider.of<LikedProvider<Album>>(context, listen: false);
    await provider.toggleLike(album);
  }

  Future<void> _downloadAlbum(List<Track> tracks) async {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DownloadProgressDialog(
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

    return ChangeNotifierProvider.value(
      value: _albumDetailProvider,
      child: Consumer<AlbumDetailProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_albumTitle ?? "???"),
              backgroundColor: Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed:
                      provider.tracks.isNotEmpty ? () => _downloadAlbum(provider.tracks) : null,
                ),
                if (provider.tracks.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      final player = Provider.of<PlayerProvider>(context, listen: false);
                      player.playTracks(provider.tracks, startIndex: 0);
                    },
                  ),
                Consumer<LikedProvider<Album>>(
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
    final t = AppLocalizations.of(context)!;

    if (provider.isLoadingTracks && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorTracks != null) {
      return Center(child: Text(t.errorOccurred(provider.errorTracks!)));
    }
    if (provider.tracks.isEmpty) {
      return Center(child: Text(t.noTracksFound));
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchTracks(),
      child: ListView.builder(
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

  @override
  void dispose() {
    _albumDetailProvider.dispose();
    super.dispose();
  }
}