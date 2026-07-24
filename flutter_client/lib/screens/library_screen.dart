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
    final theme = Theme.of(context);

    return Column(
      children: [
        // Pill-shaped tab selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildPillTab(t.playlists, 0),
                _buildPillTab(t.albums, 1),
                _buildPillTab(t.artists, 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildContent(playlistProvider, albumsProvider, artistsProvider),
        ),
      ],
    );
  }

  Widget _buildPillTab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withAlpha(40)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
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
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Liked tracks
          _buildLibraryTile(
            icon: Icons.favorite,
            iconColor: Theme.of(context).colorScheme.primary,
            title: t.likedTracks,
            subtitle: t.likedTracksDescription,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          ...playlistProvider.playlists.map(
            (playlist) => _buildLibraryTile(
              icon: Icons.playlist_play,
              iconColor: Colors.white70,
              title: playlist.name,
              subtitle: null,
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
                            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await playlistProvider.deletePlaylist(playlist.id);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18),
                        const SizedBox(width: 8),
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
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: albumsProvider.objects.length,
        itemBuilder: (_, i) {
          final album = albumsProvider.objects[i];
          return _buildLibraryTile(
            icon: Icons.album,
            iconColor: Colors.orangeAccent,
            title: album.title,
            subtitle: album.artist,
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
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: artistsProvider.objects.length,
        itemBuilder: (_, i) {
          final artist = artistsProvider.objects[i];
          return _buildLibraryTile(
            icon: Icons.person,
            iconColor: Colors.purpleAccent,
            title: artist.name,
            subtitle: null,
            onTap: () => _navigateToArtist(artist),
          );
        },
      );
    }
  }

  Widget _buildLibraryTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withAlpha(40),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: trailing,
      onTap: onTap,
    );
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