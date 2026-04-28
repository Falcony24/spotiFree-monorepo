import 'package:frontend/models/artist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart';


abstract class IArtistRepository {
  Future<Artist> getArtist(String artistId, {required DataSource source});
  Future<List<Album>> getArtistAlbums(String artistId, {required DataSource source, int limit = 20, int offset = 0});
  Future<List<Track>> getArtistTracks(String artistId, {required DataSource source, int limit = 20, int offset = 0});
}