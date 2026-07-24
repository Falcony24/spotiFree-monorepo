import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/utils/responsive.dart';
import 'package:spotifree/widgets/album_grid_item.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/providers/artist_details_provider.dart';
import 'package:spotifree/providers/artist_albums_provider.dart';
import 'package:spotifree/providers/artist_tracks_provider.dart';
import 'package:spotifree/widgets/track_tile.dart';
import 'package:spotifree/screens/album_detail_screen.dart';

class ArtistScreen extends StatefulWidget {
  final Artist? artist;
  final String? artistId;

  const ArtistScreen({super.key, this.artist, this.artistId});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late String _artistId;

  @override
  void initState() {
    super.initState();
    _artistId = widget.artist?.id ?? widget.artistId!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.artist == null) {
        Provider.of<ArtistDetailsProvider>(context, listen: false)
            .fetchArtist(_artistId);
      }
      Provider.of<ArtistAlbumsProvider>(context, listen: false).loadInitial(_artistId);
      Provider.of<ArtistTracksProvider>(context, listen: false).loadInitial(_artistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsProvider = Provider.of<ArtistDetailsProvider>(context);
    final albumsProvider = Provider.of<ArtistAlbumsProvider>(context);
    final tracksProvider = Provider.of<ArtistTracksProvider>(context);
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final artist = widget.artist ?? detailsProvider.artist;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailsProvider.isLoading ? '...' : (artist?.name ?? '???'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist info card
            if (!detailsProvider.isLoading && artist != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withAlpha(50),
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artist.name, style: theme.textTheme.headlineMedium),
                    if (artist.sortName != null) ...[
                      const SizedBox(height: 4),
                      Text(artist.sortName!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),

            // Tracks section
            _buildSectionHeader(t.tracks, Icons.music_note),
            if (tracksProvider.isLoading && tracksProvider.tracks.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (tracksProvider.tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(t.noTracksFound, style: theme.textTheme.bodyMedium),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracksProvider.tracks.length,
                itemBuilder: (_, i) => TrackTile(track: tracksProvider.tracks[i]),
              ),
              if (tracksProvider.hasMore)
                Center(
                  child: TextButton(
                    onPressed: () => tracksProvider.loadMore(_artistId),
                    child: Text(t.loadMore),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Albums section
            _buildSectionHeader(t.albums, Icons.album),
            if (albumsProvider.isLoading && albumsProvider.albums.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (albumsProvider.albums.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(t.noAlbumsFound, style: theme.textTheme.bodyMedium),
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: albumsProvider.albums.length,
                    itemBuilder: (_, i) {
                      final album = albumsProvider.albums[i];
                      return AlbumGridItem(
                        album: album,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(album: album),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              if (albumsProvider.hasMore)
                Center(
                  child: TextButton(
                    onPressed: () => albumsProvider.loadMore(_artistId),
                    child: Text(t.loadMore),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}