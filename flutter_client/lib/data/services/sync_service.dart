import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/data/services/favorites_service.dart';
import 'package:frontend/data/services/playlists_service.dart';
import 'package:frontend/data/services/albums_service.dart';

class SyncService {
  final OfflineStorage _storage;
  final FavoritesService _favoritesService;
  final PlaylistsService _playlistsService;
  final AlbumsService _albumsService;

  SyncService({
    OfflineStorage? storage,
    FavoritesService? favoritesService,
    PlaylistsService? playlistsService,
    AlbumsService? albumsService,
  }) : _storage = storage ?? OfflineStorage(),
       _favoritesService = favoritesService ?? FavoritesService(),
       _playlistsService = playlistsService ?? PlaylistsService(),
       _albumsService = albumsService ?? AlbumsService();

  Future<void> syncAll() async {
    await _pushLocalChanges();
    await _pullRemoteData();
  }

  Future<void> _pushLocalChanges() async {
    final pending = await _storage.getPendingSyncItems();
    for (final item in pending) {
      try {
        final type = item['entity_type'] as String;
        final action = item['action'] as String;
        final entityId = item['entity_id'] as String?;
        final payload = item['payload'] as String?;

        switch (type) {
          case 'liked_track':
            if (action == 'add' && entityId != null) {
              await _favoritesService.likeTrack(entityId);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForTrack(entityId);
              if (favId != null) await _favoritesService.unlikeTrack(favId);
            }
            break;
          case 'liked_album':
            if (action == 'add' && entityId != null) {
              await _favoritesService.likeAlbum(entityId);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForAlbum(entityId);
              if (favId != null) await _favoritesService.unlikeAlbum(favId);
            }
            break;
          case 'liked_artist':
            if (action == 'add' && entityId != null) {
              await _favoritesService.likeArtist(entityId);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForArtist(entityId);
              if (favId != null) await _favoritesService.unlikeArtist(favId);
            }
            break;
          case 'playlist':
            if (action == 'create') {
              final payloadMap = jsonDecode(payload!);
              final newPlaylist = await _playlistsService.createPlaylist(
                payloadMap['name'],
                description: payloadMap['description'],
                isPublic: payloadMap['is_public'],
              );
              final oldId = entityId!;
              final db = await _storage.database;
              await db.update('playlists', {'id': newPlaylist.id}, where: 'id = ?', whereArgs: [oldId]);
              await db.update('playlist_tracks', {'playlist_id': newPlaylist.id}, where: 'playlist_id = ?', whereArgs: [oldId]);
            } else if (action == 'delete') {
              final playlistId = entityId!;
              if (playlistId.isNotEmpty && !playlistId.startsWith('local_')) {
                await _playlistsService.deletePlaylist(playlistId);
              }
              await _storage.permanentlyDeletePlaylist(playlistId);
            }
            break;
        }
        await _storage.removeSyncItem(item['id']);
      } catch (e) {
        debugPrint('Sync error for ${item['entity_type']} ${item['action']}: $e');
      }
    }
  }

  Future<void> _pullRemoteData() async {
    try {
      final likedTracks = await _favoritesService.getLikedTracks();
      final likedAlbums = await _favoritesService.getLikedAlbums();
      final likedArtists = await _favoritesService.getLikedArtists();
      final playlistsData = await _playlistsService.getPlaylists(limit: 1000);

      final db = await _storage.database;
      await db.delete('liked_tracks');
      await db.delete('liked_albums');
      await db.delete('liked_artists');
      await db.delete('playlists');
      await db.delete('playlist_tracks');

      for (final item in likedTracks) {
        await _storage.addLikedTrack(item['id'], item['entity']);
      }
      for (final item in likedAlbums) {
        final album = item['entity'];
        await _storage.addLikedAlbum(item['id'], album);
        try {
          final tracks = await _albumsService.getAlbumTracks(album.id);
          await _storage.saveLikedAlbumTracks(album.id, tracks);
        } catch (e) {
          debugPrint('Nie udało się pobrać utworów albumu ${album.id} podczas synchronizacji: $e');
        }
      }
      for (final item in likedArtists) {
        await _storage.addLikedArtist(item['id'], item['entity']);
      }
      for (final playlist in playlistsData['data']) {
        await _storage.insertPlaylist(playlist);
        final detail = await _playlistsService.getPlaylistDetail(playlist.id);
        await _storage.savePlaylistTracks(playlist.id, detail['tracks']);
      }
    } catch (e) {
      debugPrint('Pull remote data failed: $e');
    }
  }
}