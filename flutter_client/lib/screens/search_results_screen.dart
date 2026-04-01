import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/artist_screen.dart';
import 'package:frontend/screens/album_detail_screen.dart';
import 'package:frontend/utils/responsive.dart';
import 'package:frontend/widgets/album_grid_item.dart';
import 'package:frontend/widgets/track_tile.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _results = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await ApiService().search(widget.query);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wyniki wyszukiwania: ${widget.query}'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Artyści'),
            Tab(text: 'Albumy'),
            Tab(text: 'Utwory'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Błąd: $_error'));
    }

    final artistsData = _results['artists'] as Map<String, dynamic>?;
    final albumsData = _results['albums'] as Map<String, dynamic>?;
    final tracksData = _results['tracks'] as Map<String, dynamic>?;

    final artists = (artistsData?['data'] as List?) ?? [];
    final albums = (albumsData?['data'] as List?) ?? [];
    final tracks = (tracksData?['data'] as List?) ?? [];

    return TabBarView(
      controller: _tabController,
      children: [
        _buildArtistList(artists),
        _buildAlbumList(albums),
        _buildTrackList(tracks),
      ],
    );
  }

Widget _buildArtistList(List<dynamic> artists) {
  if (artists.isEmpty) return const Center(child: Text('Brak artystów'));
  return ListView.builder(
    itemCount: artists.length,
    itemBuilder: (ctx, index) {
      final item = artists[index];
      final id = item is Map ? item['id'] : item.id;
      final name = item is Map ? item['name'] : item.name;
      return ListTile(
        leading: const Icon(Icons.person),
        title: Text(name ?? 'Nieznany artysta'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(artistId: id),
            ),
          );
        },
      );
    },
  );
}

Widget _buildAlbumList(List<dynamic> albums) {
  if (albums.isEmpty) return const Center(child: Text('Brak albumów'));
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

Widget _buildTrackList(List<dynamic> tracks) {
  if (tracks.isEmpty) {
    return const Center(child: Text('Brak utworów'));
  }
  return ListView.builder(
    itemCount: tracks.length,
    itemBuilder: (ctx, index) {
      final item = tracks[index];
      final track = item is Map
          ? Track.fromJson(Map<String, dynamic>.from(item))
          : item as Track;
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