import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/downloaded_tracks_provider.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/providers/player_provider.dart';
import 'package:spotifree/providers/playlist_provider.dart';
import 'package:spotifree/screens/home_screen.dart';
import 'package:spotifree/screens/library_screen.dart';
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
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 0),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                HomeScreen(),
                LibraryScreen(),
                SearchScreen(),
                ProfileScreen(),
              ],
            ),
          ),
          const PlayerBar(),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.grey[900],
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Biblioteka',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Szukaj',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}