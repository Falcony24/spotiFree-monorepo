import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/offline_storage.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/track.dart';

class SyncService {
  final OfflineStorage _storage;
  final ApiService _api;

  SyncService({
    OfflineStorage? storage,
    ApiService? api,
  }) : _storage = storage ?? OfflineStorage(),
       _api = api ?? ApiService();

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
              final track = Track.fromJson(jsonDecode(payload!));
              await _api.likeTrack(track.id);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForTrack(entityId);
              if (favId != null) await _api.unlikeTrack(favId);
            }
            break;
          case 'liked_album':
            if (action == 'add' && entityId != null) {
              await _api.likeAlbum(entityId);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForAlbum(entityId);
              if (favId != null) await _api.unlikeAlbumById(favId);
            }
            break;
          case 'liked_artist':
            if (action == 'add' && entityId != null) {
              await _api.likeArtist(entityId);
            } else if (action == 'remove' && entityId != null) {
              final favId = await _storage.getFavoriteIdForArtist(entityId);
              if (favId != null) await _api.unlikeArtist(favId);
            }
            break;
          case 'playlist':
            if (action == 'create') {
              final payload = jsonDecode(item['payload']!);
              final newPlaylist = await _api.createPlaylist(
                payload['name'],
                description: payload['description'],
                isPublic: payload['is_public'],
              );
              final oldId = entityId!; // String
              final db = await _storage.database;
              await db.update('playlists', {'id': newPlaylist.id}, where: 'id = ?', whereArgs: [oldId]);
              await db.update('playlist_tracks', {'playlist_id': newPlaylist.id}, where: 'playlist_id = ?', whereArgs: [oldId]);
            } else if (action == 'delete') {
              final playlistId = entityId!;
              if (playlistId.isNotEmpty && !playlistId.startsWith('local_')) {
                await _api.deletePlaylist(playlistId);
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
      final likedTracks = await _api.getLikedTracks();
      final likedAlbums = await _api.getLikedAlbums();
      final likedArtists = await _api.getLikedArtists();
      final playlistsData = await _api.getPlaylists(limit: 1000);

      final db = await _storage.database;
      await db.delete('liked_tracks');
      await db.delete('liked_albums');
      await db.delete('liked_artists');
      await db.delete('playlists');
      await db.delete('playlist_tracks');

      for (final item in likedTracks) {
        await _storage.addLikedTrack(item['id'], item['track']);
      }
      for (final item in likedAlbums) {
        final album = item['album'];
        await _storage.addLikedAlbum(item['id'], album);
        try {
          final tracks = await _api.getAlbumTracks(album.id);
          await _storage.saveLikedAlbumTracks(album.id, tracks);
        } catch (e) {
          debugPrint('Nie udało się pobrać utworów albumu ${album.id} podczas synchronizacji: $e');
        }
      }
      for (final item in likedArtists) {
        await _storage.addLikedArtist(item['id'], item['artist']);
      }
      for (final playlist in playlistsData['data']) {
        await _storage.insertPlaylist(playlist);
        final detail = await _api.getPlaylistDetail(playlist.id);
        await _storage.savePlaylistTracks(playlist.id, detail['tracks']);
      }
    } catch (e) {
      debugPrint('Pull remote data failed: $e');
    }
  }
}