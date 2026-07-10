import 'package:flutter/material.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/providers/search_provider.dart';
import 'package:spotifree/screens/artist_screen.dart';
import 'package:spotifree/screens/album_detail_screen.dart';
import 'package:spotifree/utils/responsive.dart';
import 'package:spotifree/widgets/album_grid_item.dart';
import 'package:spotifree/widgets/track_tile.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.search(widget.query);
    });
  }

  @override
  void didUpdateWidget(covariant SearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.search(widget.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final isLoading = searchProvider.isLoading;
        final error = searchProvider.error;
        final artists = searchProvider.artists;
        final albums = searchProvider.albums;
        final tracks = searchProvider.tracks;

        return Scaffold(
          appBar: AppBar(
            title: Text('Wyniki wyszukiwania: ${widget.query}'),
            backgroundColor: Colors.black,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: t.artists),
                Tab(text: t.albums),
                Tab(text: t.tracks),
              ],
            ),
          ),
          body: _buildBody(isLoading, error, artists, albums, tracks),
        );
      },
    );
  }

  Widget _buildBody(bool isLoading, String? error, List artists, List albums, List tracks) {
    final t = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(t.errorOccurred(error)));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildArtistList(artists),
        _buildAlbumList(albums),
        _buildTrackList(tracks),
      ],
    );
  }

  Widget _buildArtistList(List artists) {
    final t = AppLocalizations.of(context)!;
    if (artists.isEmpty) return Center(child: Text(t.emptyList));
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (ctx, index) {
        final artist = artists[index];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(artist.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtistScreen(artistId: artist.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumList(List albums) {
    final t = AppLocalizations.of(context)!;
    if (albums.isEmpty) return Center(child: Text(t.emptyList));
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = getCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: albums.length,
          itemBuilder: (ctx, index) {
            final album = albums[index];
            return AlbumGridItem(
              album: album,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailScreen(album: album),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrackList(List tracks) {
    final t = AppLocalizations.of(context)!;
    if (tracks.isEmpty) {
      return Center(child: Text(t.emptyList));
    }
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (ctx, index) {
        final track = tracks[index];
        return TrackTile(track: track);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}