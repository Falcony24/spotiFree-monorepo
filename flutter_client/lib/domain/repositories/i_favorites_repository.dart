import 'package:frontend/models/track.dart';
import 'package:frontend/constants.dart';

abstract class IFavoritesRepository {
  Future<List<Map<String, dynamic>>> getLikedTracks({required DataSource source, bool forceRefresh = false});
  Future<String> likeTrack(String trackMbid);
  Future<void> unlikeTrack(String favoriteId);
  Future<bool> isTrackLiked(String trackId);
  Future<String?> getFavoriteIdForTrack(String trackId);

  Future<List<Map<String, dynamic>>> getLikedAlbums({required DataSource source, bool forceRefresh = false});
  Future<String> likeAlbum(String albumMbid);
  Future<void> unlikeAlbum(String favoriteId);
  Future<bool> isAlbumLiked(String albumId);
  Future<String?> getFavoriteIdForAlbum(String albumId);
  Future<void> saveLikedAlbumTracks(String albumId, List<Track> tracks);
  Future<List<Track>> getLikedAlbumTracks(String albumId);

  Future<List<Map<String, dynamic>>> getLikedArtists({required DataSource source, bool forceRefresh = false});
  Future<String> likeArtist(String artistMbid);
  Future<void> unlikeArtist(String favoriteId);
  Future<bool> isArtistLiked(String artistId);
  Future<String?> getFavoriteIdForArtist(String artistId);
}