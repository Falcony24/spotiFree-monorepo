import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/liked_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/models/playlist.dart';

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

  String? _currentPlaylistId;
  String? _currentAlbumId;
  String? _currentArtistId;
  String? _currentSearchQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final likedTracksProvider = Provider.of<LikedProvider<Track>>(context, listen: false);
    final likedAlbumsProvider = Provider.of<LikedProvider<Album>>(context, listen: false);
    final likedArtistsProvider = Provider.of<LikedProvider<Artist>>(context, listen: false);

    try {
      playlistProvider.fetchPlaylists();
      likedTracksProvider.fetchLikedObjects();
      likedAlbumsProvider.fetchLikedObjects();
      likedArtistsProvider.fetchLikedObjects();
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  void _goToHome() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    _currentPlaylistId = null;
    _currentAlbumId = null;
    _currentArtistId = null;
    _currentSearchQuery = null;
  }

  void _navigateToPlaylist(Playlist playlist) {
    final id = playlist.id;
    if (_currentPlaylistId == id) return;
    _currentPlaylistId = id;
    _navigatorKey.currentState?.pushNamed('/playlist', arguments: playlist).then((_) {
      if (_currentPlaylistId == id) _currentPlaylistId = null;
    });
  }

  void _navigateToAlbum(Album album) {
    final id = album.id;
    if (_currentAlbumId == id) {
      return;
    }
    _currentAlbumId = id;
    _navigatorKey.currentState?.pushNamed('/album', arguments: album).then((_) {
      if (_currentAlbumId == id) _currentAlbumId = null;
    });
  }

  void _navigateToArtist(Artist artist) {
    final id = artist.id;
    if (_currentArtistId == id) {
      return;
    }
    _currentArtistId = id;
    _navigatorKey.currentState?.pushNamed('/artist', arguments: artist.id).then((_) {
      if (_currentArtistId == id) _currentArtistId = null;
    });
  }

  void _navigateToSearch(String query) {
    final t = AppLocalizations.of(context)!;

    if (query.isEmpty) return;
    
    final modeProvider = Provider.of<ModeProvider>(context, listen: false);
    if (modeProvider.isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.searchOffline)),
      );
      return;
    }
    
    if (_currentSearchQuery == query) return;
    _currentSearchQuery = query;
    _navigatorKey.currentState?.pushNamed('/search', arguments: query).then((_) {
      if (_currentSearchQuery == query) _currentSearchQuery = null;
    });
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
                          final album = settings.arguments as Album;
                          return MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(album: album),
                          );
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