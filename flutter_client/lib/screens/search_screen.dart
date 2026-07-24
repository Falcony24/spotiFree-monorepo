import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/search_provider.dart';
import 'package:spotifree/widgets/search_bar.dart';
import 'package:spotifree/widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchBarWidget(
            onSearch: (query) => searchProvider.search(query),
          ),
        ),
        if (searchProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (searchProvider.error != null && searchProvider.error!.isNotEmpty)
          Expanded(child: Center(child: Text(searchProvider.error!)))
        else if (searchProvider.lastQuery == null || searchProvider.lastQuery!.isEmpty)
          Expanded(
            child: Center(
              child: Text(t.searchHint, style: Theme.of(context).textTheme.bodyLarge),
            ),
          )
        else if (searchProvider.artists.isEmpty &&
            searchProvider.albums.isEmpty &&
            searchProvider.tracks.isEmpty)
          Expanded(child: Center(child: Text(t.noResults)))
        else
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: '${t.artists} (${searchProvider.artists.length})'),
                    Tab(text: '${t.albums} (${searchProvider.albums.length})'),
                    Tab(text: '${t.tracks} (${searchProvider.tracks.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildArtistList(searchProvider.artists, t),
                      _buildAlbumList(searchProvider.albums, t),
                      _buildTrackList(searchProvider.tracks, t),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArtistList(List<Artist> artists, AppLocalizations t) {
    if (artists.isEmpty) return Center(child: Text(t.noArtistsFound));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: artists.length,
      itemBuilder: (ctx, i) {
        final artist = artists[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.purpleAccent.withAlpha(40),
            child: const Icon(Icons.person, size: 20, color: Colors.purpleAccent),
          ),
          title: Text(artist.name),
          onTap: () => Navigator.pushNamed(context, '/artist', arguments: artist.id),
        );
      },
    );
  }

  Widget _buildAlbumList(List<Album> albums, AppLocalizations t) {
    if (albums.isEmpty) return Center(child: Text(t.noAlbumsFound));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: albums.length,
      itemBuilder: (ctx, i) {
        final album = albums[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orangeAccent.withAlpha(40),
            child: const Icon(Icons.album, size: 20, color: Colors.orangeAccent),
          ),
          title: Text(album.title),
          subtitle: album.artist != null ? Text(album.artist!) : null,
          onTap: () => Navigator.pushNamed(context, '/album', arguments: album),
        );
      },
    );
  }

  Widget _buildTrackList(List<Track> tracks, AppLocalizations t) {
    if (tracks.isEmpty) return Center(child: Text(t.noTracksFound));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) {
        return TrackTile(track: tracks[i]);
      },
    );
  }
}