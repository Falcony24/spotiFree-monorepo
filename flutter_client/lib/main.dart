import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/providers/albums_provider.dart';
import 'package:frontend/providers/artist_albums_provider.dart';
import 'package:frontend/providers/artist_details_provider.dart';
import 'package:frontend/providers/artist_tracks_provider.dart';
import 'package:frontend/providers/downloaded_tracks_provider.dart';
import 'package:frontend/providers/liked_albums_provider.dart';
import 'package:frontend/providers/liked_artists_provider.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/widgets/authenticated_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/providers/liked_tracks_provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => LikedTracksProvider()),
        ChangeNotifierProvider(create: (_) => LikedAlbumsProvider()),
        ChangeNotifierProvider(create: (_) => LikedArtistsProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => DownloadedTracksProvider()),
        ChangeNotifierProxyProvider2<ModeProvider, DownloadedTracksProvider, PlayerProvider>(
          create: (_) => PlayerProvider(),
          update: (context, mode, downloaded, previous) =>
          previous!..updateDependencies(mode, downloaded),
        ),
        ChangeNotifierProvider(create: (_) => AlbumsProvider()),
        ChangeNotifierProvider(create: (_) => ArtistDetailsProvider()),
        ChangeNotifierProvider(create: (_) => ArtistAlbumsProvider()),
        ChangeNotifierProvider(create: (_) => ArtistTracksProvider()),
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