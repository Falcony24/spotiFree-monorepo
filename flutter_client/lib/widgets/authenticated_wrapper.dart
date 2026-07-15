import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/playlist.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/downloaded_tracks_provider.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/providers/player_provider.dart';
import 'package:spotifree/providers/playlist_provider.dart';
import 'package:spotifree/screens/album_detail_screen.dart';
import 'package:spotifree/screens/artist_screen.dart';
import 'package:spotifree/screens/home_screen.dart';
import 'package:spotifree/screens/library_screen.dart';
import 'package:spotifree/screens/playlist_detail_screen.dart';
import 'package:spotifree/screens/search_screen.dart';
import 'package:spotifree/screens/profile_screen.dart';
import 'package:spotifree/widgets/player_bar.dart';

class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider = context.read<PlayerProvider>();
      final modeProvider = context.read<ModeProvider>();
      final downloadedProvider = context.read<DownloadedTracksProvider>();

      playerProvider.updateDependencies(modeProvider, downloadedProvider);
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
      // if (kDebugMode) print(e);
    }
  }

@override
Widget build(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  final tabs = ["SpotiFree", t.library, t.search, t.profile];

  return Scaffold(
    body: Stack(
      children: [
        Column(
          children: [
            SafeArea(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                        _navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      child: Text(
                        tabs[_selectedIndex],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Navigator(
                key: _navigatorKey,
                initialRoute: '/home',
                onGenerateRoute: (RouteSettings settings) {
                  switch (settings.name) {
                    case '/home':
                      return MaterialPageRoute(builder: (_) => const HomeScreen());
                    case '/library':
                      return MaterialPageRoute(builder: (_) => const LibraryScreen());
                    case '/search':
                      return MaterialPageRoute(builder: (_) => const SearchScreen());
                    case '/profile':
                      return MaterialPageRoute(builder: (_) => const ProfileScreen());
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
                    default:
                      return MaterialPageRoute(builder: (_) => const HomeScreen());
                  }
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PlayerBar(),
              SizedBox(
                height: 82,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.green,
                  unselectedItemColor: Colors.grey,
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                    final routeName = ['/home', '/library', '/search', '/profile'][index];
                    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      routeName,
                      (route) => false,
                    );
                  },
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: t.home),
                    BottomNavigationBarItem(icon: Icon(Icons.library_music), label: t.library),
                    BottomNavigationBarItem(icon: Icon(Icons.search), label: t.search),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: t.profile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}}