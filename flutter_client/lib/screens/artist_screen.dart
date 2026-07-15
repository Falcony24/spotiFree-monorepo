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
      Provider.of<ArtistAlbumsProvider>(context, listen: false)
          .loadInitial(_artistId);
      Provider.of<ArtistTracksProvider>(context, listen: false)
          .loadInitial(_artistId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsProvider = Provider.of<ArtistDetailsProvider>(context);
    final albumsProvider = Provider.of<ArtistAlbumsProvider>(context);
    final tracksProvider = Provider.of<ArtistTracksProvider>(context);
    final t = AppLocalizations.of(context)!;
    
    final artist = widget.artist ?? detailsProvider.artist;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailsProvider.isLoading ? '...' : (artist?.name ?? '???'),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!detailsProvider.isLoading && artist != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist.sortName ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Text(t.tracks , style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (tracksProvider.isLoading && tracksProvider.tracks.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (tracksProvider.tracks.isEmpty)
              Text(t.noTracksFound)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracksProvider.tracks.length,
                itemBuilder: (ctx, i) => TrackTile(track: tracksProvider.tracks[i]),
              ),
            if (!tracksProvider.isLoading && tracksProvider.hasMore)
              Center(
                child: TextButton(
                  onPressed: () => tracksProvider.loadMore(_artistId),
                  child: Text(t.loadMore),
                ),
              ),
            const SizedBox(height: 24),
            Text(t.albums, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (albumsProvider.isLoading && albumsProvider.albums.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (albumsProvider.albums.isEmpty)
              Text(t.noAlbumsFound)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: albumsProvider.albums.length,
                    itemBuilder: (ctx, i) {
                      final album = albumsProvider.albums[i];
                      return AlbumGridItem(
                        album: album,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlbumDetailScreen(album: album),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            if (!albumsProvider.isLoading && albumsProvider.hasMore)
              Center(
                child: TextButton(
                  onPressed: () => albumsProvider.loadMore(_artistId),
                  child: Text(t.loadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}