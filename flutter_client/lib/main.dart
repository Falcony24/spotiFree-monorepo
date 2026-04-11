import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/domain/factories/get_liked_use_case_factory.dart';
import 'package:frontend/domain/factories/toggle_like_use_case_factory.dart';
import 'package:provider/provider.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/providers/playlist_tracks_provider.dart';
import 'package:frontend/providers/downloaded_tracks_provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/providers/albums_provider.dart';
import 'package:frontend/providers/artist_details_provider.dart';
import 'package:frontend/providers/artist_albums_provider.dart';
import 'package:frontend/providers/artist_tracks_provider.dart';
import 'package:frontend/providers/liked_provider.dart';

import 'package:frontend/domain/usecases/get_playlists_use_case.dart';
import 'package:frontend/domain/usecases/manage_playlist_use_case.dart';
import 'package:frontend/domain/usecases/get_playlist_tracks_use_case.dart';
import 'package:frontend/domain/usecases/get_albums_use_case.dart';
// import 'package:frontend/domain/usecases/get_album_tracks_use_case.dart';
import 'package:frontend/domain/usecases/get_artist_use_case.dart';
import 'package:frontend/domain/usecases/get_artist_albums_use_case.dart';
import 'package:frontend/domain/usecases/get_artist_tracks_use_case.dart';

import 'package:frontend/data/repositories/favorites_repository.dart';
import 'package:frontend/data/repositories/playlist_repository.dart';
import 'package:frontend/data/repositories/album_repository.dart';
import 'package:frontend/data/repositories/artist_repository.dart';

import 'package:frontend/models/track.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';

import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/widgets/authenticated_wrapper.dart';

import 'package:frontend/data/services/sync_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
  _startSyncListener();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final modeProvider = ModeProvider();
    final favoritesRepository = FavoritesRepository();
    final playlistRepository = PlaylistRepository();
    final albumRepository = AlbumRepository();
    final artistRepository = ArtistRepository();

    final getLikedTracksUseCase = GetLikedUseCaseFactory.create<Track>(
      repository: favoritesRepository,
      modeProvider: modeProvider,
    );
    final toggleLikeTrackUseCase = ToggleLikeUseCaseFactory.create<Track>(
        repository: favoritesRepository,
        modeProvider: modeProvider,
    );

    final getLikedAlbumsUseCase = GetLikedUseCaseFactory.create<Album>(
      repository: favoritesRepository,
      modeProvider: modeProvider,
    );
    final toggleLikeAlbumUseCase = ToggleLikeUseCaseFactory.create<Album>(
        repository: favoritesRepository,
        modeProvider: modeProvider,
    );

    final getLikedArtistsUseCase = GetLikedUseCaseFactory.create<Artist>(
      repository: favoritesRepository,
      modeProvider: modeProvider,
    );
    final toggleLikeArtistUseCase = ToggleLikeUseCaseFactory.create<Artist>(
        repository: favoritesRepository,
        modeProvider: modeProvider,
    );

    final getPlaylistsUseCase = GetPlaylistsUseCase(
      repository: playlistRepository,
      modeProvider: modeProvider,
    );
    final managePlaylistUseCase = ManagePlaylistUseCase(
      repository: playlistRepository,
      modeProvider: modeProvider,
    );
    final getPlaylistTracksUseCase = GetPlaylistTracksUseCase(
      repository: playlistRepository,
      modeProvider: modeProvider,
    );

    final getAlbumsUseCase = GetAlbumsUseCase(
      repository: albumRepository,
      modeProvider: modeProvider,
    );
    // final getAlbumTracksUseCase = GetAlbumTracksUseCase(
    //   repository: albumRepository,
    //   modeProvider: modeProvider,
    // );

    final getArtistUseCase = GetArtistUseCase(
      repository: artistRepository,
      modeProvider: modeProvider,
    );
    final getArtistAlbumsUseCase = GetArtistAlbumsUseCase(
      repository: artistRepository,
      modeProvider: modeProvider,
    );
    final getArtistTracksUseCase = GetArtistTracksUseCase(
      repository: artistRepository,
      modeProvider: modeProvider,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: modeProvider),

        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => DownloadedTracksProvider()),

        ChangeNotifierProvider(
          create: (_) => PlaylistProvider(
            getPlaylistsUseCase: getPlaylistsUseCase,
            managePlaylistUseCase: managePlaylistUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => PlaylistTracksProvider(
            getPlaylistTracksUseCase: getPlaylistTracksUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => AlbumsProvider(
            getAlbumsUseCase: getAlbumsUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ArtistDetailsProvider(
            getArtistUseCase: getArtistUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ArtistAlbumsProvider(
            getArtistAlbumsUseCase: getArtistAlbumsUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ArtistTracksProvider(
            getArtistTracksUseCase: getArtistTracksUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => LikedProvider<Track>(
            getLikedUseCase: getLikedTracksUseCase,
            toggleLikeUseCase: toggleLikeTrackUseCase,
            modeProvider: modeProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LikedProvider<Album>(
            getLikedUseCase: getLikedAlbumsUseCase,
            toggleLikeUseCase: toggleLikeAlbumUseCase,
            modeProvider: modeProvider,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LikedProvider<Artist>(
            getLikedUseCase: getLikedArtistsUseCase,
            toggleLikeUseCase: toggleLikeArtistUseCase,
            modeProvider: modeProvider,
          ),
        ),

        ChangeNotifierProxyProvider2<ModeProvider, DownloadedTracksProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (context, mode, downloaded, previous) =>
              previous!..updateDependencies(mode, downloaded),
        ),
      ],
      child: MaterialApp(
        title: 'SpotiFree',
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isLoading) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return auth.isAuthenticated ? const AuthenticatedWrapper() : const LoginScreen();
            },
          ),
          '/register': (context) => const RegisterScreen(),
        },
      ),
    );
  }
}

void _startSyncListener() {
  InternetConnectionChecker().onStatusChange.listen((status) async {
    if (status == InternetConnectionStatus.connected) {
      final syncService = SyncService();
      await syncService.syncAll();
    }
  });
}