import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/providers/player_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/playlist_provider.dart';
import 'package:frontend/providers/liked_provider.dart'; 
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';

class LeftPanel extends StatefulWidget {
  final Function(Playlist) onPlaylistSelected;
  final Function(Album) onAlbumSelected;
  final Function(Artist) onArtistSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const LeftPanel({
    super.key,
    required this.onPlaylistSelected,
    required this.onAlbumSelected,
    required this.onArtistSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  int _selectedTab = 0; // 0: playlists, 1: albums, 2: artists

  @override
  Widget build(BuildContext context) {
    final playlistProvider = Provider.of<PlaylistProvider>(context);
    final albumsProvider = Provider.of<LikedProvider<Album>>(context);
    final artistsProvider = Provider.of<LikedProvider<Artist>>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    
    return Container(
      color: Colors.grey[900],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left),
              onPressed: () {
                Future.microtask(() => widget.onToggleCollapse());
              },
            ),
          ),
          if (!widget.isCollapsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabButton('Playlisty', 0),
                  _buildTabButton('Albumy', 1),
                  _buildTabButton('Artyści', 2),
                ],
              ),
            ),
          Expanded(
            child: RepaintBoundary(
              child: _buildContent(playlistProvider, albumsProvider, artistsProvider),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const Divider(),
            Consumer<ModeProvider>(
              builder: (context, modeProvider, child) {
                return SwitchListTile(
                  title: Text(t.offlineMode),
                  value: modeProvider.isOfflineMode,
                  onChanged: modeProvider.hasInternet
                      ? (value) => modeProvider.setOfflineMode(value)
                      : null,
                  secondary: Icon(
                    modeProvider.hasInternet ? Icons.offline_bolt : Icons.wifi_off,
                    color: modeProvider.hasInternet ? null : Colors.grey,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(t.logout),
              onTap: () async {
                final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
                await playerProvider.stop();        
                await authProvider.logout();
              },
            ),
          ],
        ],
      ),
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

  Widget _buildContent(PlaylistProvider playlistProvider, LikedProvider<Album> albumsProvider, LikedProvider<Artist> artistsProvider) {
    final t = AppLocalizations.of(context)!;
    
    if (_selectedTab == 0) {
      if (playlistProvider.isLoading) return const Center(child: CircularProgressIndicator());
      if (widget.isCollapsed) {
        return ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.green),
              onPressed: () => widget.onPlaylistSelected(Playlist(
                id: 'liked_tracks',
                name: t.likedTracks,
                description: t.likedTracksDescription,
                isPublic: false,
                userId: 0,
              )),
            ),
            const Divider(),
            ...playlistProvider.playlists.map((playlist) => IconButton(
              icon: const Icon(Icons.playlist_play),
              onPressed: () => widget.onPlaylistSelected(playlist),
            )),
          ],
        );
      } else {
        return ListView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.green),
              title: Text(t.likedTracks),
              onTap: () => widget.onPlaylistSelected(Playlist(
                id: 'liked_tracks',
                name: t.likedTracks,
                description: t.likedTracksDescription,
                isPublic: false,
                userId: 0,
              )),
            ),
            const Divider(),
            ...playlistProvider.playlists.map((playlist) => ListTile(
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
                            child: Text(t.delete, style: TextStyle(color: Colors.red)),
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
                        const Icon(Icons.delete, size: 18),
                        const SizedBox(width: 8),
                        Text(t.deletePlaylist),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => widget.onPlaylistSelected(playlist),
            )),
          ],
        );
      }
    } else if (_selectedTab == 1) {
      if (albumsProvider.isLoading) return const Center(child: CircularProgressIndicator());
      if (albumsProvider.objects.isEmpty) return Center(child: Text(t.noLikedAlbums));
      if (widget.isCollapsed) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: albumsProvider.objects.length,
          itemBuilder: (ctx, i) {
            final album = albumsProvider.objects[i];
            return IconButton(
              icon: const Icon(Icons.album),
              onPressed: () => widget.onAlbumSelected(album),
            );
          },
        );
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: albumsProvider.objects.length,
          itemBuilder: (ctx, i) {
            final album = albumsProvider.objects[i];
            return ListTile(
              leading: const Icon(Icons.album),
              title: Text(album.title),
              subtitle: album.artist != null ? Text(album.artist!) : null,
              onTap: () => widget.onAlbumSelected(album),
            );
          },
        );
      }
    } else {
      if (artistsProvider.isLoading) return const Center(child: CircularProgressIndicator());
      if (artistsProvider.objects.isEmpty) return Center(child: Text(t.noLikedArtists));
      if (widget.isCollapsed) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artistsProvider.objects.length,
          itemBuilder: (ctx, i) {
            final artist = artistsProvider.objects[i];
            return IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => widget.onArtistSelected(artist),
            );
          },
        );
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: artistsProvider.objects.length,
          itemBuilder: (ctx, i) {
            final artist = artistsProvider.objects[i];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(artist.name),
              onTap: () => widget.onArtistSelected(artist),
            );
          },
        );
      }
    }
  }
}