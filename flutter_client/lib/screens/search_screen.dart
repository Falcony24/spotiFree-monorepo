import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/search_provider.dart';
import 'package:spotifree/widgets/search_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
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

    final artistCount = searchProvider.artists.length;
    final albumCount = searchProvider.albums.length;
    final trackCount = searchProvider.tracks.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchBarWidget(
            onSearch: (query) => searchProvider.search(query),
          ),
        ),
        if (searchProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (searchProvider.error != null && searchProvider.error!.isNotEmpty)
          Expanded(child: Center(child: Text(searchProvider.error!)))
        else if (searchProvider.lastQuery == null || searchProvider.lastQuery!.isEmpty)
          Expanded(child: Center(child: Text(t.searchHint)))
        else if (artistCount == 0 && albumCount == 0 && trackCount == 0)
          Expanded(child: Center(child: Text(t.noResults)))
        else
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.grey[900],
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.green,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: '${t.artists} ($artistCount)'),
                      Tab(text: '${t.albums} ($albumCount)'),
                      Tab(text: '${t.tracks} ($trackCount)'),
                    ],
                  ),
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
    if (artists.isEmpty) {
      return Center(child: Text(t.noArtistsFound));
    }
    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (ctx, i) {
        final artist = artists[i];
        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(artist.name),
          onTap: () => Navigator.pushNamed(context, '/artist', arguments: artist.id),
        );
      },
    );
  }

  Widget _buildAlbumList(List<Album> albums, AppLocalizations t) {
    if (albums.isEmpty) {
      return Center(child: Text(t.noAlbumsFound));
    }
    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (ctx, i) {
        final album = albums[i];
        return ListTile(
          leading: const Icon(Icons.album),
          title: Text(album.title),
          subtitle: album.artist != null ? Text(album.artist!) : null,
          onTap: () => Navigator.pushNamed(context, '/album', arguments: album),
        );
      },
    );
  }

  Widget _buildTrackList(List<Track> tracks, AppLocalizations t) {
    if (tracks.isEmpty) {
      return Center(child: Text(t.noTracksFound));
    }
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (ctx, i) {
        final track = tracks[i];
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: Text(track.title),
          subtitle: Text(track.artist),
          onTap: () {
          },
        );
      },
    );
  }
}