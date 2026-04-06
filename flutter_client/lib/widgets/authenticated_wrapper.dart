import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/liked_albums_provider.dart';
import 'package:frontend/providers/liked_artists_provider.dart';
import 'package:frontend/providers/liked_tracks_provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/screens/album_detail_screen.dart';
import 'package:frontend/screens/artist_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/playlist_detail_screen.dart';
import 'package:frontend/screens/search_results_screen.dart';
import 'package:frontend/widgets/left_panel.dart';
import 'package:frontend/widgets/player_bar.dart';
import 'package:frontend/widgets/search_bar.dart';

class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isLeftPanelCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final likedTracksProvider = Provider.of<LikedTracksProvider>(context, listen: false);
    final likedAlbumsProvider = Provider.of<LikedAlbumsProvider>(context, listen: false);
    final likedArtistsProvider = Provider.of<LikedArtistsProvider>(context, listen: false);

    try{
      playlistProvider.fetchPlaylists();           
      likedTracksProvider.fetchLikedTracks();
      likedAlbumsProvider.fetchLikedAlbums();
      likedArtistsProvider.fetchLikedArtists();
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _goToHome() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void _navigateToPlaylist(Playlist playlist) {
    _navigatorKey.currentState?.pushNamed('/playlist', arguments: playlist);
  }

  void _navigateToAlbum(Album album) {
    _navigatorKey.currentState?.pushNamed('/album', arguments: album);
  }

  void _navigateToArtist(Artist artist) {
    _navigatorKey.currentState?.pushNamed('/artist', arguments: artist.id);
  }

  void _navigateToSearch(String query) {
    if (query.isNotEmpty) {
      _navigatorKey.currentState?.pushNamed('/search', arguments: query);
    }
  }

  void _toggleLeftPanel() {
    setState(() {
      _isLeftPanelCollapsed = !_isLeftPanelCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goToHome,
                    child: const Text(
                      'SpotiFree',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: SearchBarWidget(
                      onSearch: _navigateToSearch,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: _isLeftPanelCollapsed ? 60 : 280,
                  child: LeftPanel(
                    onPlaylistSelected: _navigateToPlaylist,
                    onAlbumSelected: _navigateToAlbum,
                    onArtistSelected: _navigateToArtist,
                    isCollapsed: _isLeftPanelCollapsed,
                    onToggleCollapse: _toggleLeftPanel,
                  ),
                ),
                Expanded(
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: '/',
                    onGenerateRoute: (settings) {
                      switch (settings.name) {
                        case '/':
                          return MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          );
                        case '/playlist':
                          final playlist = settings.arguments as Playlist;
                          return MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(playlist: playlist),
                          );
                        case '/album':
                          final album = settings.arguments;
                          if (album is Album) {
                            return MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(album: album),
                            );
                          } else if (album is String) {
                            return MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: album),
                            );
                          } else {
                            return MaterialPageRoute(builder: (_) => const HomeScreen());
                          }
                        case '/artist':
                          final artistId = settings.arguments as String;
                          return MaterialPageRoute(
                            builder: (_) => ArtistScreen(artistId: artistId),
                          );
                        case '/search':
                          final query = settings.arguments as String;
                          return MaterialPageRoute(
                            builder: (_) => SearchResultsScreen(query: query),
                          );
                        default:
                          return MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const PlayerBar(),
        ],
      ),
    );
  }
}