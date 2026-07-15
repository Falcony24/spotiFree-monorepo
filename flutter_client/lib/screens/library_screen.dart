import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotifree/l10n/app_localizations.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/playlist.dart';
import 'package:spotifree/providers/liked_provider.dart';
import 'package:spotifree/providers/playlist_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0; // 0 - playlists, 1 - albums, 2 - artists

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final albumsProvider = Provider.of<LikedProvider<Album>>(context);
    final artistsProvider = Provider.of<LikedProvider<Artist>>(context);
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(t.playlists, 0),
              _buildTabButton(t.albums, 1),
              _buildTabButton(t.artists, 2),
            ],
          ),
        ),
        Expanded(
          child: _buildContent(
            playlistProvider,
            albumsProvider,
            artistsProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _selectedTab == index ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab == index ? Colors.white : Colors.grey,
              fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    PlaylistProvider playlistProvider,
    LikedProvider<Album> albumsProvider,
    LikedProvider<Artist> artistsProvider,
  ) {
    final t = AppLocalizations.of(context)!;

    if (_selectedTab == 0) {
      if (playlistProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        children: [
          // Favorite tracks as special playlist
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.green),
            title: Text(t.likedTracks),
            onTap: () => _navigateToPlaylist(
              Playlist(
                id: 'liked_tracks',
                name: t.likedTracks,
                description: t.likedTracksDescription,
                isPublic: false,
                userId: 0,
              ),
            ),
          ),
          const Divider(),
          ...playlistProvider.playlists.map(
            (playlist) => ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(playlist.name),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(t.deletePlaylist),
                        content: Text(t.confirmDeletePlaylist(playlist.name)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(t.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              t.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await playlistProvider.deletePlaylist(playlist.id);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18),
                        SizedBox(width: 8),
                        Text(t.deletePlaylist),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _navigateToPlaylist(playlist),
            ),
          ),
        ],
      );
    } else if (_selectedTab == 1) {
      if (albumsProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (albumsProvider.objects.isEmpty) {
        return Center(child: Text(t.noLikedAlbums));
      }
      return ListView.builder(
        itemCount: albumsProvider.objects.length,
        itemBuilder: (ctx, i) {
          final album = albumsProvider.objects[i];
          return ListTile(
            leading: const Icon(Icons.album),
            title: Text(album.title),
            subtitle: album.artist != null ? Text(album.artist!) : null,
            onTap: () => _navigateToAlbum(album),
          );
        },
      );
    } else {
      if (artistsProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (artistsProvider.objects.isEmpty) {
        return Center(child: Text(t.noLikedArtists));
      }
      return ListView.builder(
        itemCount: artistsProvider.objects.length,
        itemBuilder: (ctx, i) {
          final artist = artistsProvider.objects[i];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(artist.name),
            onTap: () => _navigateToArtist(artist),
          );
        },
      );
    }
  }

  void _navigateToPlaylist(Playlist playlist) {
    Navigator.pushNamed(context, '/playlist', arguments: playlist);
  }

  void _navigateToAlbum(Album album) {
    Navigator.pushNamed(context, '/album', arguments: album);
  }

  void _navigateToArtist(Artist artist) {
    Navigator.pushNamed(context, '/artist', arguments: artist.id);
  }
}