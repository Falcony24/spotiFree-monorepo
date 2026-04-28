import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart';


abstract class IAlbumRepository {
  Future<List<Album>> getAlbums({
    required DataSource source,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  });

  Future<Album> getAlbum(String albumId, {required DataSource source});

  Future<List<Track>> getAlbumTracks(String albumId, {required DataSource source});
}